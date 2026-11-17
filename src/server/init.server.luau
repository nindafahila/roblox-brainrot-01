-- Brainrot Base (server): spawner karakter, ekonomi, base pemain, steal,
-- kunci base, rebirth, dan Badai Brainrot yang menyapu map.
-- Semua karakter/nama orisinal; lihat Characters.luau untuk datanya.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Characters = require(script.Parent.Characters)

local START_MONEY = 100
local MAX_SLOTS = 8
local MAX_WALKERS = 10
local SPAWN_INTERVAL = 6
local WALK_START_X = -135
local WALK_END_X = 138
local LOCK_DURATION = 30
local LOCK_COOLDOWN = 90
local REBIRTH_MIN_MONEY = 5000
local REBIRTH_MIN_CHARS = 4
local CALM_SECONDS = 150
local WARN_SECONDS = 15
local SWEEP_SECONDS = 25
local WAVE_LOSS = 0.10 -- kena badai di luar base: hilang 10% uang

local GameState = ReplicatedStorage:WaitForChild("GameState")
local WaveStatus = GameState:WaitForChild("WaveStatus")
local WaveTimer = GameState:WaitForChild("WaveTimer")
local NextWaveIn = GameState:WaitForChild("NextWaveIn")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ToggleLock = Remotes:WaitForChild("ToggleLock")
local DoRebirth = Remotes:WaitForChild("DoRebirth")
local Notify = Remotes:WaitForChild("Notify")

local playersData = {} -- [Player] = { plotIndex, plot, money, multiplier, rebirths, chars, lockedUntil, lockReadyAt, totalEarned }
local walkers = {} -- array { model, speed, rolled }
local plotTaken = {}

local function notify(player, message, kind)
	Notify:FireClient(player, message, kind or "info")
end

local function plotCenter(plotIndex)
	local plot = Workspace:FindFirstChild("Plot" .. plotIndex)
	if not plot then
		return nil
	end
	local floor = plot:FindFirstChild("Floor")
	if not floor then
		return nil
	end
	return floor.Position
end

local function isInsideOwnBase(player)
	local data = playersData[player]
	if not data or data.plotIndex == 0 then
		return false
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local center = plotCenter(data.plotIndex)
	if not center then
		return false
	end
	return math.abs(root.Position.X - center.X) <= 14
		and math.abs(root.Position.Z - center.Z) <= 14
end

local function countChars(data)
	local n = 0
	for _ in pairs(data.chars) do
		n += 1
	end
	return n
end

local function freeSlot(data)
	for i = 1, MAX_SLOTS do
		if not data.chars[i] then
			return i
		end
	end
	return nil
end

local function incomePerSecond(data)
	local total = 0
	for _, rec in pairs(data.chars) do
		total += rec.income
	end
	return math.floor(total * data.multiplier)
end

-- ---------------------------------------------------------------- model

local function buildCharacterModel(rolled)
	local def = rolled.def
	local model = Instance.new("Model")
	model.Name = Characters.displayName(rolled)

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 3, 2)
	body.Color = def.body
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 2, 2)
	head.Color = def.head
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = CFrame.new(0, 2.5, 0)
	head.Parent = model

	-- Mahkota kecil untuk rarity tinggi, supaya terlihat istimewa dari jauh.
	if rolled.rarityIndex >= 4 then
		local crown = Instance.new("Part")
		crown.Name = "Crown"
		crown.Size = Vector3.new(1.6, 0.6, 1.6)
		crown.Color = Color3.fromRGB(255, 215, 0)
		crown.Material = Enum.Material.Neon
		crown.Anchored = true
		crown.CanCollide = false
		crown.CFrame = CFrame.new(0, 3.8, 0)
		crown.Parent = model
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(220, 70)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 5.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.BackgroundTransparency = 0.35
	label.TextColor3 = rolled.rarity.color
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Text = Characters.displayName(rolled)
		.. "\n$" .. rolled.price
		.. "  |  $" .. rolled.income .. "/dtk"
		.. "\n" .. rolled.rarity.name
	label.Parent = billboard

	model.PrimaryPart = body
	return model
end

local function addBuyPrompt(model, rolled)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Beli"
	prompt.ObjectText = "$" .. rolled.price .. "  |  $" .. rolled.income .. "/dtk"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	return prompt
end

-- ---------------------------------------------------------------- steal

local function wireStealPrompt(model, record)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Curi"
	prompt.ObjectText = record.name
	prompt.HoldDuration = 2.5
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart

	prompt.Triggered:Connect(function(thief)
		local owner = record.owner
		if thief == owner then
			notify(thief, "Itu karaktermu sendiri!", "info")
			return
		end
		local ownerData = playersData[owner]
		local thiefData = playersData[thief]
		if not ownerData or not thiefData then
			return
		end
		-- Karakter masih milik owner ini?
		if ownerData.chars[record.slot] ~= record then
			return
		end
		if os.time() < ownerData.lockedUntil then
			notify(thief, "Base " .. owner.DisplayName .. " sedang TERKUNCI!", "buruk")
			return
		end
		if thiefData.plotIndex == 0 then
			notify(thief, "Kamu tidak punya base!", "buruk")
			return
		end
		local slot = freeSlot(thiefData)
		if not slot then
			notify(thief, "Base-mu penuh, tidak bisa menampung curian!", "buruk")
			return
		end
		ownerData.chars[record.slot] = nil
		local slotPart = thiefData.plot:FindFirstChild("Slot" .. slot)
		model:PivotTo(CFrame.new(slotPart.Position + Vector3.new(0, 1.75, 0)))
		model.Parent = thiefData.plot
		record.owner = thief
		record.slot = slot
		thiefData.chars[slot] = record
		notify(thief, "Berhasil mencuri " .. record.name .. " dari " .. owner.DisplayName .. "!", "baik")
		notify(owner, thief.DisplayName .. " MENCURI " .. record.name .. " dari base-mu! Kunci base-mu!", "buruk")
	end)
end

-- ---------------------------------------------------------------- spawner

local function spawnWalker()
	if #walkers >= MAX_WALKERS then
		return
	end
	local rolled = Characters.roll()
	local model = buildCharacterModel(rolled)
	model:PivotTo(CFrame.new(WALK_START_X, 2.5, 0))
	model.Parent = Workspace
	local prompt = addBuyPrompt(model, rolled)
	local entry = { model = model, speed = rolled.def.speed, rolled = rolled }
	table.insert(walkers, entry)

	prompt.Triggered:Connect(function(player)
		-- Prompt bisa dipicu sekali; abaikan bila model sudah tidak berjalan.
		local stillWalking = false
		for _, w in ipairs(walkers) do
			if w == entry then
				stillWalking = true
				break
			end
		end
		if not stillWalking then
			return
		end
		local data = playersData[player]
		if not data then
			return
		end
		if data.plotIndex == 0 then
			notify(player, "Tidak ada base kosong untukmu!", "buruk")
			return
		end
		if data.money < rolled.price then
			notify(player, "Uang tidak cukup! Butuh $" .. rolled.price .. ".", "buruk")
			return
		end
		local slot = freeSlot(data)
		if not slot then
			notify(player, "Base-mu penuh (8/8)! Rebirth untuk mengosongkan.", "buruk")
			return
		end
		data.money -= rolled.price
		local plot = data.plot
		local slotPart = plot:FindFirstChild("Slot" .. slot)
		for i, w in ipairs(walkers) do
			if w == entry then
				table.remove(walkers, i)
				break
			end
		end
		prompt:Destroy()
		model:PivotTo(CFrame.new(slotPart.Position + Vector3.new(0, 1.75, 0)))
		model.Parent = plot
		local record = {
			model = model,
			slot = slot,
			income = rolled.income,
			price = rolled.price,
			name = Characters.displayName(rolled),
			owner = player,
		}
		data.chars[slot] = record
		wireStealPrompt(model, record)
		notify(player, "Dapat " .. Characters.displayName(rolled) .. " (+$" .. rolled.income .. "/dtk)!", "baik")
	end)
end

local function despawnAllWalkers()
	for _, w in ipairs(walkers) do
		if w.model.Parent then
			w.model:Destroy()
		end
	end
	table.clear(walkers)
end

RunService.Heartbeat:Connect(function(dt)
	for i = #walkers, 1, -1 do
		local w = walkers[i]
		if not w.model.Parent then
			table.remove(walkers, i)
		else
			w.model:PivotTo(w.model:GetPivot() * CFrame.new(w.speed * dt, 0, 0))
			if w.model:GetPivot().Position.X >= WALK_END_X then
				w.model:Destroy()
				table.remove(walkers, i)
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(SPAWN_INTERVAL)
		-- Jangan spawn saat badai sedang menyapu.
		if WaveStatus.Value ~= "BADAI" then
			spawnWalker()
		end
	end
end)

-- ---------------------------------------------------------------- ekonomi

task.spawn(function()
	while true do
		task.wait(1)
		for player, data in pairs(playersData) do
			local gain = incomePerSecond(data)
			if gain > 0 then
				data.money += gain
				data.totalEarned += gain
			end
			local stats = player:FindFirstChild("leaderstats")
			if stats then
				local uang = stats:FindFirstChild("Uang")
				if uang then
					uang.Value = math.floor(data.money)
				end
				local perDetik = stats:FindFirstChild("PerDetik")
				if perDetik then
					perDetik.Value = gain
				end
			end
		end
	end
end)

-- ---------------------------------------------------------------- kunci & rebirth

ToggleLock.OnServerEvent:Connect(function(player)
	local data = playersData[player]
	if not data or data.plotIndex == 0 then
		return
	end
	local now = os.time()
	if now < data.lockReadyAt then
		notify(player, "Kunci masih cooldown (" .. (data.lockReadyAt - now) .. " dtk lagi).", "info")
		return
	end
	data.lockedUntil = now + LOCK_DURATION
	data.lockReadyAt = now + LOCK_COOLDOWN
	player:SetAttribute("Locked", true)
	notify(player, "Base TERKUNCI selama " .. LOCK_DURATION .. " detik!", "baik")
	task.delay(LOCK_DURATION, function()
		if playersData[player] == data then
			player:SetAttribute("Locked", false)
		end
	end)
end)

DoRebirth.OnServerEvent:Connect(function(player)
	local data = playersData[player]
	if not data then
		return
	end
	if data.money < REBIRTH_MIN_MONEY then
		notify(player, "Rebirth butuh $"
			.. REBIRTH_MIN_MONEY .. " (kamu $" .. math.floor(data.money) .. ").", "buruk")
		return
	end
	if countChars(data) < REBIRTH_MIN_CHARS then
		notify(player, "Rebirth butuh minimal " .. REBIRTH_MIN_CHARS .. " karakter di base.", "buruk")
		return
	end
	for _, rec in pairs(data.chars) do
		if rec.model.Parent then
			rec.model:Destroy()
		end
	end
	table.clear(data.chars)
	data.money = START_MONEY
	data.multiplier += 0.5
	data.rebirths += 1
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local rb = stats:FindFirstChild("Rebirth")
		if rb then
			rb.Value = data.rebirths
		end
	end
	notify(player, "REBIRTH #" .. data.rebirths .. "! Penghasilan x" .. data.multiplier .. " selamanya.", "baik")
end)

-- ---------------------------------------------------------------- badai

local waveWall = Workspace:WaitForChild("WaveWall")

task.spawn(function()
	while true do
		-- Fase tenang: hitung mundur.
		for t = CALM_SECONDS, 1, -1 do
			NextWaveIn.Value = t
			task.wait(1)
		end
		-- Fase peringatan: karakter liar kabur, pemain harus pulang ke base.
		WaveStatus.Value = "PERINGATAN"
		despawnAllWalkers()
		for t = WARN_SECONDS, 1, -1 do
			WaveTimer.Value = t
			task.wait(1)
		end
		-- Fase badai: dinding menyapu map dari barat ke timur.
		WaveStatus.Value = "BADAI"
		local start = os.clock()
		local lastCheck = 0
		while true do
			local elapsed = os.clock() - start
			if elapsed >= SWEEP_SECONDS then
				break
			end
			local x = -170 + (elapsed / SWEEP_SECONDS) * 340
			waveWall:PivotTo(CFrame.new(x, 20, 0))
			WaveTimer.Value = math.ceil(SWEEP_SECONDS - elapsed)
			if os.clock() - lastCheck >= 0.5 then
				lastCheck = os.clock()
				for player in pairs(playersData) do
					local character = player.Character
					local root = character and character:FindFirstChild("HumanoidRootPart")
					if root and math.abs(root.Position.X - x) < 9 and not isInsideOwnBase(player) then
						local data = playersData[player]
						local lost = math.floor(data.money * WAVE_LOSS)
						data.money -= lost
						character:PivotTo(CFrame.new(0, 5, 40))
						notify(player, "Kena Badai Brainrot! -$" .. lost .. " (lari ke base saat peringatan!)", "buruk")
					end
				end
			end
			task.wait(0.05)
		end
		waveWall:PivotTo(CFrame.new(-170, 20, 0))
		WaveStatus.Value = "Tenang"
		WaveTimer.Value = 0
	end
end)

-- ---------------------------------------------------------------- pemain

local function onPlayerAdded(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local uang = Instance.new("IntValue")
	uang.Name = "Uang"
	uang.Value = START_MONEY
	uang.Parent = stats
	local perDetik = Instance.new("IntValue")
	perDetik.Name = "PerDetik"
	perDetik.Value = 0
	perDetik.Parent = stats
	local rebirth = Instance.new("IntValue")
	rebirth.Name = "Rebirth"
	rebirth.Value = 0
	rebirth.Parent = stats
	stats.Parent = player

	local plotIndex = 0
	for i = 1, MAX_SLOTS do
		if not plotTaken[i] then
			plotTaken[i] = player
			plotIndex = i
			break
		end
	end
	local plot = nil
	if plotIndex > 0 then
		plot = Workspace:FindFirstChild("Plot" .. plotIndex)
	end
	playersData[player] = {
		plotIndex = plotIndex,
		plot = plot,
		money = START_MONEY,
		multiplier = 1,
		rebirths = 0,
		chars = {},
		lockedUntil = 0,
		lockReadyAt = 0,
		totalEarned = 0,
	}
	player:SetAttribute("PlotIndex", plotIndex)
	player:SetAttribute("Locked", false)
	if plotIndex == 0 then
		notify(player, "Server penuh: semua 8 base terisi. Kamu hanya bisa menonton.", "buruk")
	else
		notify(player, "Selamat datang di Brainrot Base! Base-mu: Plot " .. plotIndex .. ". Beli karakter di jalur tengah!", "baik")
	end
end

local function onPlayerRemoving(player)
	local data = playersData[player]
	if data then
		for _, rec in pairs(data.chars) do
			if rec.model.Parent then
				rec.model:Destroy()
			end
		end
		if data.plotIndex > 0 and plotTaken[data.plotIndex] == player then
			plotTaken[data.plotIndex] = nil
		end
		playersData[player] = nil
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("Brainrot Base server siap: 12 karakter, 8 base, badai tiap "
	.. CALM_SECONDS .. " detik.")
