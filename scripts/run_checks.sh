#!/usr/bin/env bash
# After setup_and_build_windows.sh: compare the elaborated statements and
# definitions of the solution against the standalone challenge file, and
# print the axioms the three theorems depend on.
set -u
ROOT=/d/lean
HERE="$(cd "$(dirname "$0")/.." && pwd)"
export ELAN_HOME="$ROOT/elan" PATH="$ROOT/elan/bin:$PATH"
cd "$ROOT/math/lean"

# Challenge side: the official challenge file (statements with `sorry`,
# only Mathlib imported) followed by the print commands.
cat ComparatorChallenges/MatrixMultiplication.lean "$HERE/check/prints.txt" > "$HERE/check/Challenge.lean"
# Solution side: the compiled proof, the same print commands, plus axioms.
{
  echo "import OAI.LinearAlgebra.MatrixMultiplication.Main"
  cat "$HERE/check/prints.txt"; echo
  echo "set_option pp.all false"
  for t in complex_omega_le_nine_quarters complex_alpha_gt_93_div_200 complex_rectangular_omega_lt_523_div_250; do
    echo "#print axioms OAI.MatrixMultiplication.$t"
  done
} > "$HERE/check/Solution.lean"

lake env lean "$HERE/check/Solution.lean" > "$HERE/results/solution_output.txt" 2>&1
lake env lean "$HERE/check/Challenge.lean" > "$HERE/results/challenge_output.txt" 2>&1

strip() { sed -E 's/^[^ ]*\.lean:[0-9]+:[0-9]+: //' "$1" | tr -d '\r'; }
strip "$HERE/results/solution_output.txt" | grep -v "depends on axioms\|^ Classical\|^ Quot" > /tmp/s.txt
strip "$HERE/results/challenge_output.txt" | grep -v "declaration uses .sorry." > /tmp/c.txt
diff /tmp/s.txt /tmp/c.txt > "$HERE/results/statement_diff.txt" && echo "Statements and definitions: IDENTICAL"
grep -A3 "depends on axioms" "$HERE/results/solution_output.txt" > "$HERE/results/axioms.txt"
cat "$HERE/results/axioms.txt"

# Scan the proof sources for constructs that could bypass the kernel.
grep -rn -E "skipKernelTC|debug\.|unsafe|implemented_by|@\[extern|addDecl|ofReduceBool|native_decide|run_cmd|run_elab" \
  OAI/LinearAlgebra/MatrixMultiplication .lake/packages/fixed-point-theorems --include=*.lean \
  > "$HERE/results/kernel_bypass_scan.txt" || echo "Kernel-bypass scan: nothing found"
