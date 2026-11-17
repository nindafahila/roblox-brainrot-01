-- Brainrot Base: data semua karakter. SEMUA nama orisinal (terinspirasi genre
-- "steal a brainrot", bukan menyalin karakter/meme yang sudah ada).
-- Harga = harga beli sekali; Income = uang per detik selama karakter di base.

local Characters = {}

Characters.RARITIES = {
	{ name = "Biasa", color = Color3.fromRGB(180, 180, 180), weight = 40 },
	{ name = "Langka", color = Color3.fromRGB(80, 200, 255), weight = 28 },
	{ name = "Epik", color = Color3.fromRGB(180, 90, 255), weight = 16 },
	{ name = "Legendaris", color = Color3.fromRGB(255, 170, 0), weight = 10 },
	{ name = "Mistis", color = Color3.fromRGB(255, 60, 120), weight = 5 },
	{ name = "Dewa", color = Color3.fromRGB(255, 230, 0), weight = 1 },
}

-- Mutasi: peluang digulir tiap spawn; pengali berlaku ke harga DAN income.
Characters.MUTATIONS = {
	{ name = "", mult = 1, chance = 0.865, color = Color3.fromRGB(255, 255, 255) },
	{ name = "Emas", mult = 2, chance = 0.08, color = Color3.fromRGB(255, 215, 0) },
	{ name = "Pelangi", mult = 4, chance = 0.03, color = Color3.fromRGB(120, 220, 255) },
	{ name = "Bayangan", mult = 6, chance = 0.015, color = Color3.fromRGB(90, 60, 140) },
	{ name = "Api", mult = 8, chance = 0.01, color = Color3.fromRGB(255, 80, 0) },
}

-- name, rarityIndex (1..6), price, incomePerSec, bodyColor, headColor, speed
Characters.DEFS = {
	{ name = "Kucing Nasi Goreng", rarity = 1, price = 60, income = 5, body = Color3.fromRGB(255, 170, 60), head = Color3.fromRGB(255, 220, 150), speed = 7 },
	{ name = "Ayam Geprek Terbang", rarity = 1, price = 120, income = 9, body = Color3.fromRGB(255, 240, 220), head = Color3.fromRGB(255, 90, 90), speed = 8 },
	{ name = "Ikan Lele Disco", rarity = 2, price = 300, income = 20, body = Color3.fromRGB(70, 130, 200), head = Color3.fromRGB(120, 220, 255), speed = 6 },
	{ name = "Bebek Es Teh Manis", rarity = 2, price = 500, income = 32, body = Color3.fromRGB(255, 230, 120), head = Color3.fromRGB(255, 180, 40), speed = 6 },
	{ name = "Capybara Kopi Tubruk", rarity = 3, price = 1000, income = 60, body = Color3.fromRGB(150, 100, 60), head = Color3.fromRGB(90, 55, 30), speed = 5 },
	{ name = "Tikus Roti Bakar", rarity = 3, price = 1500, income = 90, body = Color3.fromRGB(120, 120, 120), head = Color3.fromRGB(220, 180, 120), speed = 9 },
	{ name = "Kodok Martabak Manis", rarity = 4, price = 3000, income = 170, body = Color3.fromRGB(80, 200, 90), head = Color3.fromRGB(40, 140, 60), speed = 5 },
	{ name = "Ular Mie Ayam", rarity = 4, price = 5000, income = 280, body = Color3.fromRGB(240, 220, 120), head = Color3.fromRGB(200, 60, 60), speed = 8 },
	{ name = "Kuda Gado-Gado", rarity = 5, price = 10000, income = 550, body = Color3.fromRGB(160, 90, 40), head = Color3.fromRGB(220, 200, 160), speed = 6 },
	{ name = "Burung Es Kelapa", rarity = 5, price = 20000, income = 1100, body = Color3.fromRGB(200, 240, 255), head = Color3.fromRGB(255, 255, 255), speed = 7 },
	{ name = "Monyet Bakso Berapi", rarity = 5, price = 35000, income = 1800, body = Color3.fromRGB(140, 90, 50), head = Color3.fromRGB(255, 120, 40), speed = 8 },
	{ name = "Naga Nasi Padang", rarity = 6, price = 75000, income = 4000, body = Color3.fromRGB(40, 180, 90), head = Color3.fromRGB(255, 215, 0), speed = 5 },
}

function Characters.rollRarity()
	local total = 0
	for _, r in ipairs(Characters.RARITIES) do
		total += r.weight
	end
	local roll = math.random(1, total)
	local acc = 0
	for i, r in ipairs(Characters.RARITIES) do
		acc += r.weight
		if roll <= acc then
			return i
		end
	end
	return 1
end

function Characters.rollMutation()
	local roll = math.random()
	local acc = 0
	for _, m in ipairs(Characters.MUTATIONS) do
		acc += m.chance
		if roll <= acc then
			return m
		end
	end
	return Characters.MUTATIONS[1]
end

-- Gulir satu karakter acak: mengembalikan def + rarity + mutasi + harga/income akhir.
function Characters.roll()
	local rarityIndex = Characters.rollRarity()
	local pool = {}
	for _, def in ipairs(Characters.DEFS) do
		if def.rarity == rarityIndex then
			table.insert(pool, def)
		end
	end
	local def = pool[math.random(1, #pool)]
	local mutation = Characters.rollMutation()
	return {
		def = def,
		rarity = Characters.RARITIES[rarityIndex],
		rarityIndex = rarityIndex,
		mutation = mutation,
		price = math.floor(def.price * mutation.mult),
		income = math.floor(def.income * mutation.mult),
	}
end

function Characters.displayName(rolled)
	if rolled.mutation.name ~= "" then
		return rolled.mutation.name .. " " .. rolled.def.name
	end
	return rolled.def.name
end

return Characters
