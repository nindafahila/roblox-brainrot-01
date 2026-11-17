# BUILD-PLAN — Rencana Replayable (untuk sesi Codex terekam)

> Rencana ini untuk membangun ulang entri **Brainrot Base** (roblox-brainrot-01) di dalam
> sesi `makefun record` yang terekam, supaya entri bisa disubmit. Build di VM Linux ini
> (17 Nov 2026) SUDAH menghasilkan game + `game.rbxl` + local check, TAPI **tidak bisa
> disubmit dari sini** — lihat BUILD-NOTES.md untuk alasannya (tidak ada auth rekaman,
> tidak ada Roblox Studio). Jangan klaim build VM ini bisa disubmit.

## 0. Prasyarat (sebelum rekaman)

- [ ] Akun Roblox yang **sudah bisa publish**: umur akun ≥ 2 hari, lolos age check, good standing.
  Akun yang dibuat setelah kompetisi buka (17 Nov 2026) TIDAK bisa publish sampai umur 2 hari.
- [ ] Roblox Studio terpasang (Windows/macOS — Studio TIDAK ADA di Linux).
- [ ] `makefun record` bisa merekam sesi Codex/Claude Code (butuh auth Codex/Claude yang valid;
  di VM ini `codex` 401 tanpa auth, `claude` CLI tidak ada — siapkan dulu di mesin yang dipakai).
- [ ] Akun make.fun `@lahh-anjenk` + wallet Solana `4v5NaBkEJXfPYPMD12DFTJAwyFqSzFr21JJqnHp4uTV5`.
- [ ] Repo ini sudah ada: https://github.com/nindafahila/roblox-brainrot-01 (dibuat 17 Nov 2026, setelah kompetisi buka).

## 1. Mulai rekaman (publish-first — JANGAN build dulu)

Sesuai RULES.txt ("Before you submit" + "Getting started"): **publish dulu, build kemudian.**

1. Di luar sesi agen: clone repo ini ke mesin Windows/macOS yang ada Studio-nya.
2. Jalankan `makefun record` (perintah persis di RULES.txt), lalu mulai sesi Codex baru di dalam rekaman.
3. **Di dalam rekaman, dari Studio:** buka `game.rbxl` (starter — atau `game.rbxl` hasil Rojo di repo ini
   bila sudah ada) dan publish sebagai experience baru akun Roblox tersebut
   (File → Publish to Roblox As… → Create new experience).
4. Pemilik akun: set experience **Public** (Studio: Game Settings → Basic Info → Private → Public;
   lalu jawab pertanyaan konten Roblox — untuk game sederhana ini jawab "No" di pertanyaan konten
   age-restricted, atau isi seluruh kuesioner ±15 jawaban).
5. Ambil play code: `node <kit>/cli/makefun.mjs check --repo <repo> --play-code <n>` (n dari langkah
   registrasi "Enter"), tulis play code APA ADANYA di deskripsi experience
   (Game Settings → Basic Info, atau Creator Dashboard → Configure). Jangan ubah isinya.
6. Isi `PLAY.json` di repo (di dalam rekaman, oleh agen): `{"url": "https://www.roblox.com/games/<placeId>",
   "place_id": <placeId>, "universe_id": <universeId>}` — place_id = angka di play link,
   universe_id = angka setelah `experiences/` di Creator Dashboard, atau `game.GameId` di Studio.
7. Jalankan `node <kit>/cli/makefun.mjs check --kit <kit> --repo <repo>` sampai baris **play_link PASS**.
   Akun yang tidak bisa publish = tidak bisa ikut; berhenti di sini dan kabari user.

## 2. Build game (di dalam rekaman yang sama)

Alur yang dipakai repo ini: **Rojo-first** (jangan campur dengan alur Studio-first).

1. Install Rojo (salah satu; yang terbukti jalan di VM Linux):
   - Binary release: `curl -sSL -o rojo.zip https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-linux-x86_64.zip && unzip rojo.zip`
     (sesuaikan `-macos-…` / `-windows-…` dengan OS; atau `cargo install rojo` bila ada Rust).
   - `rojo --version` → harus `Rojo 7.7.1`.
2. Tulis/ulangi file game (agen menulis sendiri di sesi terekam — JANGAN copy-paste file jadi dari luar
   tanpa menulis ulang, karena transcript gate hanya menghitung baris yang ditulis agen terekam):
   - `src/server/Characters.luau` — 12 karakter orisinal + 6 rarity + 5 mutasi + fungsi roll.
   - `src/server/init.server.luau` — spawner, ekonomi, base 8 slot, steal (tahan E 2,5 dtk),
     kunci base 30 dtk (cooldown 90 dtk), rebirth ($5000 + 4 karakter → pengali +0,5x),
     Badai Brainrot (tenang 150 dtk → peringatan 15 dtk → sapuan dinding 25 dtk, -10% uang di luar base).
   - `src/client/Game.client.luau` — HUD uang/pendapatan/rebirth, banner badai, tombol Kunci + Rebirth,
     kompas arah + jarak base, notifikasi server.
   - `default.project.json` — dunia 3D: baseplate, jalur spawn 280 stud, 8 plot base (28x28, 8 slot),
     SpawnLocation, WaveWall, pohon, lampu, kolam; `ReplicatedStorage/GameState` (WaveStatus/WaveTimer/
     NextWaveIn) + `Remotes` (ToggleLock/DoRebirth/Notify); `Players.CharacterAutoLoads = true`.
   - `main.ts` — tulis sendiri mengikuti pola starter (main.ts starter yang tidak diubah dihitung 0 baris):
     salin game.rbxl, PLAY.json, src/, screenshots/ ke /output + tulis dossier.json via
     `vendor/makefun-roblox.ts` (JANGAN diubah).
3. Validasi Luau (opsional tapi dianjurkan): install luau 0.747 dari
   `https://github.com/luau-lang/luau/releases/download/0.747/luau-ubuntu.zip` (atau `-macos`/`-windows`),
   lalu `luau-compile --only-parse src/server/*.luau src/client/*.luau` (harus SYNTAX-OK semua) dan
   `luau-analyze --mode=nonstrict …` — error "Unknown global" (Color3/Instance/game/…) WAJAR tanpa
   definisi tipe Roblox; yang tidak boleh ada adalah SyntaxError.
4. `rojo build default.project.json --output game.rbxl` → harus `Built project to game.rbxl`
   (hasil build VM: 16.854 byte; starter hanya 3.108 byte — bila ukurannya tetap ~3 KB, build gagal).
   **JANGAN PERNAH** timpa `game.rbxl` hasil Rojo dengan save Studio, atau sebaliknya.
5. Determinisme: `mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts` 2x ke direktori berbeda,
   bandingkan dengan `diff -r` — harus identik byte-per-byte.

## 3. Screenshot + thumbnail (di Studio, di dalam rekaman)

1. Play-test di Studio (Play ▶), ambil **3–4 screenshot 16:9** (mis. 1280x720, masing-masing ≤ 256 KiB):
   `1-start.png` (spawn, HUD terlihat), `2-play.png` (karakter di jalur + base terisi),
   `3-end.png` (badai / base penuh). HUD dijauhi dari pojok kiri atas (tombol menu Roblox).
2. Simpan di `screenshots/` **menggantikan 3 screenshot starter** (jangan memalsukan: harus tangkapan
   game yang jalan di Studio).
3. Sesuaikan `TOUR.json` dengan langkah kunci tiap screenshot (mis. `{"keys": ["W"], "wait_ms": 2000}`).
4. Pemilik akun, di Creator Dashboard (https://create.roblox.com/dashboard/creations):
   pilih experience → Configurations → Places → start place (bertanda bintang) → **Icon** (512x512)
   dan **Thumbnails** (tab Experience Detail Page): upload icon + **salah satu screenshot di atas
   sebagai thumbnail PERTAMA**. Tunggu sampai halaman experience menampilkan keduanya (Roblox me-review
   tiap upload; selama masih review, entry ditolak).

## 4. Check + submit (di dalam rekaman)

1. `node <kit>/cli/makefun.mjs check --kit <kit> --repo <repo>` — semua baris harus PASS
   (play_link, transcripts, dst.). Baris yang wajar gagal SEBELUM publish: play_link.
2. `node <kit>/cli/makefun.mjs submit --competition roblox-brainrot-01 --repo-url <url> --commit <sha>
   --title "Brainrot Base" --recording <id> --keypair <keypair>` — **HANYA dari sesi terekam**,
   dengan keypair akun @lahh-anjenk. Jangan submit dari VM Linux tanpa rekaman.
3. `node <kit>/cli/makefun.mjs status --submission <id>` untuk memantau hasil gate.

## 5. Jangan lakukan

- Jangan bundle/submit/bayar fee apa pun di luar perintah eksplisit user.
- Jangan isi PLAY.json dengan angka palsu; 0 = belum publish = gate menolak (benar begitu).
- Jangan buat akun Roblox baru (akun harus ≥ 2 hari agar bisa publish).
- Jangan memalsukan rekaman/transkrip atau screenshot.
- Jangan baca/tampilkan isi keypair ke output.
