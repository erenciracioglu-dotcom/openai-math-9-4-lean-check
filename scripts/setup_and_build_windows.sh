#!/usr/bin/env bash
# Reproduce the Lean check of openai/math family 107 (omega <= 9/4) on Windows.
# Run from Git Bash. Needs git and ~20 GB free disk. Adjust ROOT if you like.
set -u
ROOT=/d/lean
MATH_COMMIT=adc7f1241b42e322a6451854ab7e4b4c146bf78a
AINTLIB_REV=160e446617a2168c34c95bbe7a76c4105b392434

export ELAN_HOME="$ROOT/elan" PATH="$ROOT/elan/bin:$PATH"
# Windows git checks out with CRLF by default; the repo's compatibility
# patches only apply to LF files. Force LF for every git call lake makes.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.autocrlf GIT_CONFIG_VALUE_0=false

mkdir -p "$ROOT" && cd "$ROOT"

# 1. elan (Lean version manager), installed under $ROOT/elan
if [ ! -x "$ROOT/elan/bin/elan.exe" ]; then
  curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.ps1 -o elan-init.ps1
  powershell -ExecutionPolicy Bypass -Command "\$env:ELAN_HOME='$(cygpath -w "$ROOT/elan")'; & '$(cygpath -w "$ROOT/elan-init.ps1")' -NoPrompt 1 -DefaultToolchain none"
fi

# 2. openai/math at the checked commit, with LF line endings
if [ ! -d math ]; then
  git -c core.autocrlf=false -c core.longpaths=true clone https://github.com/openai/math
fi
cd math && git config core.autocrlf false && git checkout -q "$MATH_COMMIT" && cd lean
elan toolchain install "$(cat lean-toolchain)"

# 3. AINTLIB contains a file named "2026-07-16T07:39:08Z", which is not a
#    valid Windows file name, so a normal clone fails. Pre-create the checkout
#    at the pinned commit and leave that one file out (sparse checkout).
P=.lake/packages/AINTLIB
if [ ! -d "$P/.git" ]; then
  rm -rf "$P" && mkdir -p "$P" && cd "$P"
  git init -q && git config core.autocrlf false && git config core.protectNTFS false
  git remote add origin https://github.com/CBirkbeck/AINTLIB.git
  git fetch --depth 1 origin "$AINTLIB_REV"
  git sparse-checkout set --no-cone '/*' '!*:*'
  git checkout -q --detach FETCH_HEAD
  cd - >/dev/null
fi

# 4. Remaining dependencies + Mathlib build cache
lake update || lake update
lake exe cache get

# 5. Build only the matrix multiplication proof. On Windows some parallel
#    builds fail with transient "failed to read file ... .olean" errors;
#    rerunning picks up where it stopped.
for i in 1 2 3 4 5 6 7 8; do
  lake build OAI.LinearAlgebra.MatrixMultiplication.Main && break
done
