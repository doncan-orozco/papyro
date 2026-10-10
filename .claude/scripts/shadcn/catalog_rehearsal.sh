#!/bin/bash
# Rehearses /shadcn-plan Phase 2 (React catalog = the oracle) on a SCRATCH copy of the repo layout.
# Nothing in the real repo changes. Needs network (npm + ui.shadcn.com) and takes a few minutes.
#
#   bash .claude/scripts/shadcn/catalog_rehearsal.sh [--keep]
#
# Prints one PASS/FAIL line per step and exits 1 if any step failed. --keep leaves the scratch dir for inspection.
set -u
REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/catalog-rehearsal.XXXXXX")"
KEEP=0; [ "${1:-}" = "--keep" ] && KEEP=1
FAILED=0
LOG="$WORK/rehearsal.log"
trap '[ $KEEP -eq 1 ] || rm -rf "$WORK"' EXIT

mkdir -p "$WORK/repo/docs/shadcn-port" "$WORK/repo/app/assets/tailwind" "$WORK/repo/tmp/shadcn-port" "$WORK/repo/.claude"
rsync -a --exclude node_modules --exclude dist "$REPO/react-shadcn-catalog/" "$WORK/repo/react-shadcn-catalog/"
cp -r "$REPO/app/assets/tailwind/theme" "$WORK/repo/app/assets/tailwind/theme"
cp -r "$REPO/.claude/scripts" "$WORK/repo/.claude/scripts"
cp -r "$REPO/lib" "$WORK/repo/lib"
[ -f "$REPO/.ruby-version" ] && cp "$REPO/.ruby-version" "$WORK/repo/.ruby-version"
cd "$WORK/repo" || exit 2

step() { # name, command...
  local name="$1"; shift
  echo "=== $name" >> "$LOG"
  if ( "$@" ) >> "$LOG" 2>&1; then echo "PASS  $name"; else echo "FAIL  $name"; FAILED=1; fi
}

ruby .claude/scripts/shadcn/oracle_extract.rb --out docs/shadcn-port/oracle > /dev/null 2>&1 || { echo "FAIL  oracle extraction (needs network)"; exit 1; }
ruby .claude/scripts/shadcn/oracle_audit.rb > /dev/null 2>&1 && echo "PASS  oracle audit" || { echo "FAIL  oracle audit"; FAILED=1; }
NAMES=$(ls docs/shadcn-port/oracle/manifest | sed 's/\.json$//' | tr '\n' ' ')
mv react-shadcn-catalog/src/components/ui tmp/shadcn-port/old-catalog-ui 2>/dev/null

cd react-shadcn-catalog || exit 2
OLD_RADIX=$(node -e 'console.log(Object.keys(require("./package.json").dependencies).filter(d=>d.startsWith("@radix-ui/")).join(" "))')
step "2a remove old dependencies" npm rm tailwindcss-animate autoprefixer postcss $OLD_RADIX
step "2b runtime dependencies" npm i react@19 react-dom@19 tailwindcss@4 @tailwindcss/vite tw-animate-css radix-ui lucide-react class-variance-authority clsx tailwind-merge --no-audit --no-fund
step "2c dev dependencies (React 19 types pinned)" npm i -D shadcn typescript vite @vitejs/plugin-react @types/node @types/react@19 @types/react-dom@19 --no-audit --no-fund
rm -f tailwind.config.js postcss.config.js
cat > components.json <<'J'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": false,
  "tsx": true,
  "tailwind": { "config": "", "css": "src/index.css", "baseColor": "zinc", "cssVariables": true, "prefix": "" },
  "aliases": { "components": "@/components", "utils": "@/lib/utils", "ui": "@/components/ui", "lib": "@/lib", "hooks": "@/hooks" }
}
J
cat > vite.config.ts <<'J'
/// <reference types="node" />
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'

export default defineConfig(({ command }) => ({
  plugins: [react(), tailwindcss()],
  resolve: { alias: { '@': path.resolve(__dirname, './src'), '@scenarios': path.resolve(__dirname, '../docs/shadcn-port/scenarios'), '@host-theme': path.resolve(__dirname, '../app/assets/tailwind/theme') } },
  server: { fs: { allow: ['..'] } },
  base: command === 'build' ? '/react-catalog/' : '/',
  build: { outDir: '../public/react-catalog', emptyOutDir: true },
}))
J
sed -i.bak 's/"moduleResolution": "node"/"moduleResolution": "bundler"/' tsconfig.json && rm -f tsconfig.json.bak
IMPORTS='@import "tailwindcss";\n@import "tw-animate-css";\n@import "@host-theme/theme.css";\n@import "@host-theme/tokens.css";\n'
printf "$IMPORTS" > src/index.css
step "5 shadcn add <all manifest names>" npx --yes shadcn@latest add $NAMES --overwrite --yes
printf "$IMPORTS" > src/index.css   # 5b: the CLI appends HSL sidebar variables
cd ..
step "6 verify catalog == oracle (G0)" ruby .claude/scripts/shadcn/oracle_extract.rb --out docs/shadcn-port/oracle --verify-catalog react-shadcn-catalog/src/components/ui
step "6b vendor tw-animate + shadcn css" ruby .claude/scripts/shadcn/theme_sync.rb --vendor
step "6c tokens.css covers every semantic class" ruby .claude/scripts/shadcn/theme_sync.rb --check-tokens
cd react-shadcn-catalog || exit 2
step "7 npm run build (type check + vite build)" npm run build
step "7b dev server answers GET / (base fix)" bash -c 'PORT=$((20000 + RANDOM % 20000)); (npm run dev -- --port $PORT --strictPort > ../dev.log 2>&1 & echo $! > ../dev.pid); for i in $(seq 1 40); do code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/ || true); [ "$code" = "200" ] && break; sleep 0.5; done; pkill -P $(cat ../dev.pid) 2>/dev/null; kill $(cat ../dev.pid) 2>/dev/null; [ "$code" = "200" ]'
step "7c compiled CSS has no leftover HSL variables" bash -c '! grep -q "hsl(" ../public/react-catalog/assets/*.css'

echo
[ $FAILED -eq 0 ] && echo "REHEARSAL: PASS" || { echo "REHEARSAL: FAIL (log: $LOG; rerun with --keep to inspect)"; [ $KEEP -eq 1 ] || cp "$LOG" "${TMPDIR:-/tmp}/catalog-rehearsal-last.log"; }
exit $FAILED
