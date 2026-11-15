// NEON RUSH — Crystal Run: the entry program (Node 22, standard library only).
// It hands the game in: game.rbxl, PLAY.json, src/ and screenshots/ are copied
// from this repository to /output, and /output/dossier.json is written with
// the kit's vendored library, so the scorer can rebuild the same dossier
// byte for byte. The run is deterministic: same input files, same bytes out.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const here = fileURLToPath(new URL(".", import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

// The place, the play link and every script go out whole.
copyFileSync(join(here, "game.rbxl"), join(out, "game.rbxl"));
copyFileSync(join(here, "PLAY.json"), join(out, "PLAY.json"));
cpSync(join(here, "src"), join(out, "src"), { recursive: true });

// Screenshots: 3 or 4, the first by name is the cover. The directory may
// hold a .gitkeep while the owner takes the real captures in Studio; a
// name starting with "." is skipped by the dossier builder.
mkdirSync(join(out, "screenshots"), { recursive: true });
if (existsSync(join(here, "screenshots"))) {
	cpSync(join(here, "screenshots"), join(out, "screenshots"), { recursive: true });
}

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes
// the bytes; the others refuse an entry the scorer would refuse (more than
// 4 screenshots or one over 256 KiB; a place of more than 500000 instances,
// whose scripts' sources come to over 8 MiB or whose scripts' paths come to
// over 1048576 characters, in all).
writeFileSync(
	join(out, "dossier.json"),
	buildDossier(out, {
		text_max_bytes: 65536,
		screenshots: { max: 4, max_bytes: 262144 },
		max_instances: 500000,
		scripts_max_source_bytes: 8388608,
		scripts_max_path_chars: 1048576,
	}),
);
