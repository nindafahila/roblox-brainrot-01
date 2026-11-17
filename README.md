# Brainrot Base — roblox-brainrot-01

[![roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/nindafahila/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/nindafahila/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

Entry for make.fun's ["Make the best AI Roblox brainrot game"](https://make.fun/bounty/roblox-brainrot-01)
bounty (roblox-brainrot-01): a 3D steal-a-brainrot-style game built with Rojo, with all-original characters.

## The game

**Brainrot Base** — kumpulkan karakter meme absurd orisinal, simpan di base sendiri, dan jadi yang terkaya:

- **12 karakter orisinal** (Kucing Nasi Goreng, Ayam Geprek Terbang, Ikan Lele Disco, Bebek Es Teh Manis,
  Capybara Kopi Tubruk, Tikus Roti Bakar, Kodok Martabak Manis, Ular Mie Ayam, Kuda Gado-Gado, Burung Es Kelapa,
  Monyet Bakso Berapi, Naga Nasi Padang) — masing-masing menghasilkan uang per detik.
- **6 rarity** (Biasa → Langka → Epik → Legendaris → Mistis → Dewa) dan **5 mutasi** (Emas x2, Pelangi x4,
  Bayangan x6, Api x8) yang melipatgandakan harga dan penghasilan.
- **Base sendiri**: tiap pemain mendapat 1 dari 8 plot base dengan 8 slot karakter.
- **Pencurian**: tahan E di karakter base pemain lain selama 2,5 detik untuk mencurinya — kecuali base itu
  sedang dikunci (tombol Kunci Base: 30 detik perlindungan, cooldown 90 detik).
- **Badai Brainrot**: tiap ~3 menit ada peringatan 15 detik, lalu dinding badai menyapu map dari barat ke timur.
  Pemain yang ketahuan di luar base kehilangan 10% uangnya dan terlempar ke spawn.
- **Rebirth**: dengan $5000 + 4 karakter, reset uang dan koleksi untuk pengali penghasilan permanen +0,5x per rebirth.

## How to play

1. Karakter berjalan di jalur tengah — dekati dan tekan **E** untuk membelinya (bila uangmu cukup).
2. Karakter yang dibeli pindah ke slot kosong di base-mu dan mulai menghasilkan uang tiap detik.
3. Awasi base pemain lain: curi karakter bagus mereka, dan kunci base-mu sebelum mereka membalas.
4. Saat banner **PERINGATAN** muncul, segera lari pulang ke base-mu sebelum badai menyapu map.

## Build & hand in

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
node <kit>/cli/makefun.mjs check --kit <kit> --repo .
```

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and
  `PLAY.json` to `/output` (leaving out names that start with a dot) and writes `/output/dossier.json` with
  `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json` — Rojo-first, never overwritten
  from Studio.
- `screenshots/` holds captures of the game running in Roblox Studio; one of them is also the game's first
  thumbnail on Roblox (uploaded on the Creator Dashboard together with the game's icon).
- `PLAY.json` names the published place (play link, place id, universe id) once it is published from Studio.

See `BUILD-PLAN.md` for the replayable build plan and `BUILD-NOTES.md` for the current build status and blockers.
