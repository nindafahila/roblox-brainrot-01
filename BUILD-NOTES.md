# BUILD-NOTES — Status build VM (17 Nov 2026, ~16:05–16:15 WIB)

> Build ini dikerjakan di VM Linux (subagent, TANPA rekaman `makefun record`).
> **Status: BUILD + LOCAL CHECK SELESAI. TIDAK BISA DISUBMIT DARI SINI.**
> Jangan klaim build ini bisa disubmit dari transkrip Muse.

## Repo

- **URL:** https://github.com/nindafahila/roblox-brainrot-01
- **Commit:** `82e636c7e5a922252b772a01ea13825077711e51`
  ("Brainrot Base: 3D steal-a-brainrot game (Rojo build, 12 original characters, steal, wave, rebirth)")
- Publik, dibuat 17 Nov 2026 16:09 UTC (setelah kompetisi buka 17 Nov 2026 — memenuhi syarat umur repo).
- GitHub About: homepage `https://make.fun/bounty/roblox-brainrot-01`, topic `makefun` (terverifikasi via `gh api`).
- `.makefun/owner.json`: `{"wallet": "4v5NaBkEJXfPYPMD12DFTJAwyFqSzFr21JJqnHp4uTV5"}`.
- LICENSE MIT (bawaan kit, SPDX MIT).

## Yang berhasil dibangun

Game **Brainrot Base** (3D, Rojo-first, semua karakter/nama orisinal):

| Bagian | File | Isi |
|---|---|---|
| Data karakter | `src/server/Characters.luau` (97 baris) | 12 karakter orisinal, 6 rarity (Biasa→Dewa), 5 mutasi (Emas x2, Pelangi x4, Bayangan x6, Api x8), roll berbobot |
| Server | `src/server/init.server.luau` (536 baris) | Spawner (tiap 6 dtk, maks 10 pejalan), ekonomi 1 dtk, base 8 slot, beli (E 0,5 dtk), steal (tahan E 2,5 dtk), kunci base 30 dtk + cooldown 90 dtk, rebirth ($5000 + 4 karakter → pengali +0,5x), Badai Brainrot (tenang 150 dtk → peringatan 15 dtk → sapuan 25 dtk, -10% uang di luar base), leaderstats Uang/PerDetik/Rebirth |
| Client | `src/client/Game.client.luau` (242 baris) | HUD uang/pendapatan/rebirth, banner badai, tombol Kunci + Rebirth, kompas arah + jarak base (Utara/Selatan/Timur/Barat + meter), notifikasi server |
| Dunia 3D | `default.project.json` | Baseplate 512, jalur spawn 280 stud + rel neon, 8 plot base (28x28, 8 slot, 4 tiang sudut), SpawnLocation, WaveWall, 10 pohon, 8 lampu, kolam; ReplicatedStorage GameState (WaveStatus/WaveTimer/NextWaveIn) + Remotes (ToggleLock/DoRebirth/Notify); CharacterAutoLoads = true |
| Penyerahan | `main.ts` (ditulis ulang sendiri) | Salin game.rbxl + PLAY.json + src/ + screenshots/ ke /output + dossier.json via vendor/makefun-roblox.ts (tidak diubah) |
| README | `README.md` | 3 badge make.fun (kompetisi + rank + reward repo ini) + link ke halaman bounty |
| Tour | `TOUR.json` | 3 langkah disesuaikan game baru (W jalan, E interaksi) |

## Hasil validasi

- **Rojo:** install BERHASIL dari binary release GitHub
  (`rojo-7.7.1-linux-x86_64.zip`, `~/.local/bin/rojo`, `Rojo 7.7.1`).
  `rojo build default.project.json --output game.rbxl` → `Built project to game.rbxl`,
  **game.rbxl = 16.854 byte** (starter 3.108 byte). Satu perbaikan dibutuhkan: folder
  `ReplicatedStorage/GameState` dan `Remotes` harus punya `"$className": "Folder"`.
- **Luau:** `luau` 0.747 (luau/luau-analyze/luau-compile) install BERHASIL dari
  `luau-ubuntu.zip` release 0.747. `luau-compile --only-parse` → **SYNTAX-OK untuk ketiga file**.
  `luau-analyze --mode=nonstrict` → hanya error `Unknown global` (Color3/Instance/game/…)
  yang WAJAR tanpa definisi tipe Roblox; **nol SyntaxError / nol error lain**.
- **main.ts determinisme:** `MAKEFUN_OUTPUT_DIR=out node main.ts` 2x → `diff -r` identik;
  sha256 game.rbxl `21eda0c0…44099`, dossier.json `a72c2511…d98` (sama di kedua run).
- **Kit check** (`node cli/makefun.mjs check --kit . --repo …`, dari kit dir):
  `kit roblox-brainrot-01 dev: verified 21 files`, lalu menolak karena repo belum git
  saat itu (`is not in a git repository`). **Check BELUM diulang setelah push** — harus
  diulang di sesi terekam (baris play_link + transcripts wajar gagal sampai publish + rekaman ada).

## Yang MASIH starter / belum nyata (jangan disalahartikan)

- **screenshots/ (1-start.png, 2-play.png, 3-end.png) = tangkapan starter** (kotak abu-abu),
  BUKAN tangkapan game ini. Harus diganti dari Studio saat play-test (lihat BUILD-PLAN.md §3).
- **PLAY.json = `{"url": "https://www.roblox.com/games/0", "place_id": 0, "universe_id": 0}`**
  (tetap 0 — belum ada tempat terbit; JANGAN isi angka palsu).
- **Game belum pernah dimainkan/diuji jalan** (tidak ada Roblox Studio di VM Linux ini):
  logika server/client hanya lolos cek sintaks + build Rojo, bukan play-test.
  Risiko yang diketahui: perilaku ProximityPrompt + `PivotTo` model ber-anchored, dan
  `RunService.RenderStepped` di client yang me-refresh HUD tiap frame — perlu play-test di Studio.

## Blocker (semua di luar kendali build ini)

1. **Tidak ada rekaman terekam / recording auth.** `codex` CLI ada tapi TANPA auth (401),
   `claude` CLI tidak ada, tidak ada OPENAI_API_KEY/ANTHROPIC_API_KEY. Kompetisi STRICT:
   entri HANYA diterima dari sealed recordings `makefun record` atas sesi Codex/Claude Code/dll.
   Build ini dikerjakan subagent Muse tanpa rekaman → **tidak bisa disubmit**.
2. **Tidak ada Roblox Studio di VM Linux** (Studio hanya Windows/macOS). Akibatnya:
   tidak bisa publish-first, tidak bisa play-test, tidak bisa ambil screenshot asli,
   tidak bisa upload icon/thumbnail di Creator Dashboard. Semua langkah itu butuh mesin
   Windows/macOS + akun Roblox yang bisa publish (≥ 2 hari + age check) — lihat BUILD-PLAN.md.
3. **PLAY.json masih 0** (konsekuensi blocker 2) → baris play_link gate akan gagal sampai publish.
4. **Screenshot starter** (konsekuensi blocker 2) → harus diganti dari Studio.
5. **Kit check belum diulang pasca-push** — jalankan lagi di sesi terekam setelah publish.

## Perintah yang TIDAK dijalankan (sesuai aturan)

- Tidak ada bundle, submit, atau pembayaran fee apa pun.
- Tidak membaca isi `~/workspace/makefun/makefun-keypair.json` ke output.
- Tidak membuat akun Roblox baru.
- Tidak memalsukan rekaman/transkrip/screenshot/PLAY.json.
