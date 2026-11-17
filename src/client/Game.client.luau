-- Brainrot Base (client): HUD uang/pendapatan, banner Badai Brainrot,
-- tombol Kunci Base + Rebirth, kompas arah base, dan notifikasi server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local GameState = ReplicatedStorage:WaitForChild("GameState")
local WaveStatus = GameState:WaitForChild("WaveStatus")
local WaveTimer = GameState:WaitForChild("WaveTimer")
local NextWaveIn = GameState:WaitForChild("NextWaveIn")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ToggleLock = Remotes:WaitForChild("ToggleLock")
local DoRebirth = Remotes:WaitForChild("DoRebirth")
local Notify = Remotes:WaitForChild("Notify")

local function makeLabel(parent, name, text, size, pos, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Size = size
	label.Position = pos
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.BackgroundTransparency = 0.4
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize or 20
	label.Font = Enum.Font.SourceSansBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false

-- Panel kiri atas: uang + pendapatan + rebirth. (Kiri atas dijauhi tombol
-- menu Roblox yang menumpuk di pojok: panel mulai di bawahnya.)
local stats = Instance.new("Frame")
stats.Name = "Stats"
stats.AnchorPoint = Vector2.new(0, 0)
stats.Position = UDim2.new(0, 12, 0, 56)
stats.Size = UDim2.fromOffset(280, 110)
stats.BackgroundTransparency = 1
stats.Parent = gui

local moneyLabel = makeLabel(stats, "Money", "Uang: $100", UDim2.new(1, 0, 0, 34), UDim2.new(0, 0, 0, 0), 24, Color3.fromRGB(120, 255, 120))
local incomeLabel = makeLabel(stats, "Income", "+$0/dtk", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 38), 20, Color3.fromRGB(255, 230, 120))
local rebirthLabel = makeLabel(stats, "Rebirth", "Rebirth: 0  (pengali x1.0)", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 72), 18, Color3.fromRGB(180, 200, 255))

-- Banner badai di tengah atas.
local banner = Instance.new("Frame")
banner.Name = "WaveBanner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 10)
banner.Size = UDim2.fromOffset(420, 44)
banner.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
banner.BackgroundTransparency = 0.4
banner.Parent = gui

local bannerLabel = Instance.new("TextLabel")
bannerLabel.Name = "WaveText"
bannerLabel.Size = UDim2.fromScale(1, 1)
bannerLabel.BackgroundTransparency = 1
bannerLabel.Text = "Tenang"
bannerLabel.TextColor3 = Color3.fromRGB(140, 255, 140)
bannerLabel.TextSize = 22
bannerLabel.Font = Enum.Font.SourceSansBold
bannerLabel.Parent = banner

-- Kompas base di kiri bawah: arah + jarak ke base sendiri.
local compass = makeLabel(gui, "Compass", "BASE: -", UDim2.fromOffset(300, 36), UDim2.new(0, 12, 1, -48), 20, Color3.fromRGB(255, 255, 255))

-- Tombol kanan bawah: kunci base + rebirth.
local buttons = Instance.new("Frame")
buttons.Name = "Buttons"
buttons.AnchorPoint = Vector2.new(1, 1)
buttons.Position = UDim2.new(1, -12, 1, -12)
buttons.Size = UDim2.fromOffset(220, 96)
buttons.BackgroundTransparency = 1
buttons.Parent = gui

local lockButton = Instance.new("TextButton")
lockButton.Name = "LockButton"
lockButton.Text = "Kunci Base (30 dtk)"
lockButton.Size = UDim2.new(1, 0, 0, 44)
lockButton.Position = UDim2.new(0, 0, 0, 0)
lockButton.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lockButton.TextSize = 20
lockButton.Font = Enum.Font.SourceSansBold
lockButton.Parent = buttons

local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.Text = "Rebirth ($5000 + 4 karakter)"
rebirthButton.Size = UDim2.new(1, 0, 0, 44)
rebirthButton.Position = UDim2.new(0, 0, 0, 52)
rebirthButton.BackgroundColor3 = Color3.fromRGB(160, 60, 220)
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.TextSize = 18
rebirthButton.Font = Enum.Font.SourceSansBold
rebirthButton.Parent = buttons

lockButton.MouseButton1Click:Connect(function()
	ToggleLock:FireServer()
end)

rebirthButton.MouseButton1Click:Connect(function()
	DoRebirth:FireServer()
end)

-- Notifikasi dari server, tampil beberapa detik di tengah layar.
local notice = Instance.new("TextLabel")
notice.Name = "Notice"
notice.AnchorPoint = Vector2.new(0.5, 0)
notice.Position = UDim2.new(0.5, 0, 0, 64)
notice.Size = UDim2.fromOffset(560, 40)
notice.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
notice.BackgroundTransparency = 0.35
notice.Text = ""
notice.TextColor3 = Color3.fromRGB(255, 255, 255)
notice.TextSize = 20
notice.Font = Enum.Font.SourceSansBold
notice.Visible = false
notice.Parent = gui

local noticeUntil = 0
Notify.OnClientEvent:Connect(function(message, kind)
	if kind == "baik" then
		notice.TextColor3 = Color3.fromRGB(120, 255, 120)
	elseif kind == "buruk" then
		notice.TextColor3 = Color3.fromRGB(255, 120, 120)
	else
		notice.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	notice.Text = message
	notice.Visible = true
	noticeUntil = os.clock() + 4
end)

-- ---------------------------------------------------------------- update loop

local function directionWord(dx, dz)
	-- Di Roblox: -Z = utara, +X = timur (sumbu peta).
	local ns = ""
	local ew = ""
	if dz < -4 then
		ns = "Utara"
	elseif dz > 4 then
		ns = "Selatan"
	end
	if dx > 4 then
		ew = "Timur"
	elseif dx < -4 then
		ew = "Barat"
	end
	if ns ~= "" and ew ~= "" then
		return ns .. "-" .. ew
	elseif ns ~= "" then
		return ns
	elseif ew ~= "" then
		return ew
	end
	return "di sini"
end

local function refresh()
	local statsFolder = player:FindFirstChild("leaderstats")
	local money = 0
	local perSec = 0
	local rebirths = 0
	if statsFolder then
		local uang = statsFolder:FindFirstChild("Uang")
		if uang then
			money = uang.Value
		end
		local perDetik = statsFolder:FindFirstChild("PerDetik")
		if perDetik then
			perSec = perDetik.Value
		end
		local rb = statsFolder:FindFirstChild("Rebirth")
		if rb then
			rebirths = rb.Value
		end
	end
	moneyLabel.Text = "Uang: $" .. money
	incomeLabel.Text = "+$" .. perSec .. "/dtk"
	rebirthLabel.Text = "Rebirth: " .. rebirths .. "  (pengali x" .. string.format("%.1f", 1 + rebirths * 0.5) .. ")"

	local status = WaveStatus.Value
	if status == "Tenang" then
		bannerLabel.Text = "Tenang - Badai berikutnya: " .. NextWaveIn.Value .. " dtk"
		bannerLabel.TextColor3 = Color3.fromRGB(140, 255, 140)
	elseif status == "PERINGATAN" then
		bannerLabel.Text = "PERINGATAN! Badai datang " .. WaveTimer.Value .. " dtk - LARI KE BASE!"
		bannerLabel.TextColor3 = Color3.fromRGB(255, 200, 60)
	else
		bannerLabel.Text = "BADAI BRAINROT! " .. WaveTimer.Value .. " dtk - JANGAN DI LUAR BASE!"
		bannerLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
	end

	if player:GetAttribute("Locked") then
		lockButton.Text = "Base TERKUNCI"
		lockButton.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
	else
		lockButton.Text = "Kunci Base (30 dtk)"
		lockButton.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
	end

	-- Kompas: arah + jarak ke base sendiri.
	local plotIndex = player:GetAttribute("PlotIndex") or 0
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if plotIndex > 0 and root then
		local plot = Workspace:FindFirstChild("Plot" .. plotIndex)
		local floor = plot and plot:FindFirstChild("Floor")
		if floor then
			local delta = floor.Position - root.Position
			local dist = math.floor(math.sqrt(delta.X * delta.X + delta.Z * delta.Z))
			compass.Text = "BASE Plot " .. plotIndex .. ": " .. directionWord(delta.X, delta.Z) .. " " .. dist .. "m"
		else
			compass.Text = "BASE Plot " .. plotIndex
		end
	else
		compass.Text = "Kamu belum punya base"
	end

	if notice.Visible and os.clock() > noticeUntil then
		notice.Visible = false
	end
end

gui.Parent = player:WaitForChild("PlayerGui")

RunService.RenderStepped:Connect(function()
	refresh()
end)
