// Brainrot Base — entry roblox-brainrot-01 (Node 22, standard library only).
//
// Cara build gamenya: tulis script Luau di src/, lalu
//   rojo build default.project.json --output game.rbxl
// Program ini yang menyerahkan gamenya ke make.fun: ia menyalin game.rbxl,
// PLAY.json, src/ dan screenshots/ dari samping file ini ke /output, lalu
// menulis /output/dossier.json (ringkasan yang dibaca juri) dengan library
// vendored make.fun. Satu-satunya yang disalin adalah file-file itu; nama
// yang diawali titik (.gitkeep, .DS_Store, .git) TIDAK ikut, karena grader
// menolak entry yang output-nya memuat nama seperti itu.
//
// Di luar container grader, MAKEFUN_OUTPUT_DIR menggantikan /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** Filter untuk cpSync: jangan salin file/direktori yang namanya diawali titik. */
const keepVisible = (path: string): boolean => !basename(path).startsWith('.');

mkdirSync(out, { recursive: true });

const placeFile = join(here, 'game.rbxl');
if (!existsSync(placeFile)) {
  throw new Error('game.rbxl tidak ada: jalankan dulu `rojo build default.project.json --output game.rbxl`');
}

copyFileSync(placeFile, join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: keepVisible });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) {
  cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: keepVisible });
}

// Batas dari scorer (reference/gate.json): hanya text_max_bytes yang
// memotong isi; sisanya menolak entry yang memang akan ditolak scorer
// (lebih dari 4 screenshot atau satu di atas 256 KiB; place di atas
// 500000 instance; source script di atas 8 MiB atau path-nya di atas
// 1048576 karakter, semuanya dijumlah).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, {
    text_max_bytes: 65536,
    screenshots: { max: 4, max_bytes: 262144 },
    max_instances: 500000,
    scripts_max_source_bytes: 8388608,
    scripts_max_path_chars: 1048576,
  }),
);

console.log('Brainrot Base diserahkan ke ' + out);
