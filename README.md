# Independent Lean check of OpenAI's ω ≤ 9/4 matrix multiplication result

On 6 October 2026 OpenAI published [openai/math](https://github.com/openai/math), 722 manuscripts produced by an internal model. Family 107 claims that the **matrix multiplication exponent over ℂ is at most 9/4** (previous best known bound: ω < 2.371177), with a Lean formalization.

This repository records an independent check of that Lean formalization on an ordinary Windows 11 PC. The work (paper reading, setup, build, checks, this write-up) was done by Claude Opus 5.5 at my request; I ran it on my own machine.

**[Türkçe özet aşağıda](#türkçe-özet)**

## Result

| Check | Result |
| --- | --- |
| Build of `OAI.LinearAlgebra.MatrixMultiplication.Main` (9433 jobs, incl. Mathlib) | Succeeded, no errors, no `sorry` warnings |
| Axioms of the three theorems | Only `propext`, `Classical.choice`, `Quot.sound` ([axioms.txt](results/axioms.txt)) |
| Statements and definitions vs. the standalone challenge file | Identical after full elaboration (`pp.all`) ([statement_diff.txt](results/statement_diff.txt)) |
| Kernel-bypass constructs in the proof sources (`skipKernelTC`, `unsafe`, `implemented_by`, `native_decide`, …) | None found (empty [kernel_bypass_scan.txt](results/kernel_bypass_scan.txt)) |

Checked theorems:

```lean
theorem OAI.MatrixMultiplication.complex_omega_le_nine_quarters :
    Arithmetic.omega ℂ ≤ (9 : ℝ) / 4
theorem OAI.MatrixMultiplication.complex_alpha_gt_93_div_200 :
    (93 : ℝ) / 200 < Arithmetic.complexAlpha
theorem OAI.MatrixMultiplication.complex_rectangular_omega_lt_523_div_250 :
    Arithmetic.rectangularOmega ℂ ((709 : ℝ) / 1000) < (523 : ℝ) / 250
```

`Arithmetic.omega` is defined in the [challenge file](https://github.com/openai/math/blob/main/lean/ComparatorChallenges/MatrixMultiplication.lean) in the standard way: straight-line programs with field constants, addition, subtraction and multiplication (no division), each operation costing 1, correct on all inputs, for every size n, up to an arbitrary positive exponent slack.

Versions: openai/math `adc7f1241b42e322a6451854ab7e4b4c146bf78a`, Lean `v4.34.1`, Mathlib `d13f23b723b8a846827a245b89c10fc7d3f11612`.

## How the statement check works

OpenAI's recommended verifier, [Comparator](https://github.com/leanprover/comparator), needs `landrun`, a Linux-only sandbox, so it does not run on Windows. The same core question, "does the compiled proof prove exactly the statement in the challenge file?", was checked this way:

1. [`Challenge.lean`](check/Challenge.lean): the official challenge file (definitions + statements with `sorry`, importing only Mathlib), followed by [`prints.txt`](check/prints.txt), which prints the three theorem types and all 18 definitions they depend on with `set_option pp.all true`.
2. [`Solution.lean`](check/Solution.lean): imports the compiled proof module and runs the same print commands, then `#print axioms`.
3. The two outputs are compared line by line, after removing source positions, the `#print axioms` lines and the challenge file's own three `declaration uses 'sorry'` warnings. The diff is empty, so [statement_diff.txt](results/statement_diff.txt) is an empty file. The raw outputs are in [solution_output.txt](results/solution_output.txt) and [challenge_output.txt](results/challenge_output.txt).

`pp.all` prints fully elaborated terms with every implicit argument and instance, so a proof that, for example, changed the meaning of `≤` or `ℝ` through a different instance would show up as a difference.

## What this does and does not show

- It shows that the Lean kernel accepted a proof of ω(ℂ) ≤ 9/4 with the standard definition of ω, using only the three standard axioms.
- It does **not** replace Comparator: there was no sandbox and no second, independent kernel replay (e.g. lean4checker/nanoda). The remaining trust is in the Lean kernel and toolchain.
- It says nothing about the other 721 manuscripts, and it is not an expert review of the paper's mathematics or its significance. Before the build, Claude also read the 13-page paper and found no errors in the steps it checked; that informal reading is not part of the evidence here.

## Reproducing on Windows

[`scripts/setup_and_build_windows.sh`](scripts/setup_and_build_windows.sh) (Git Bash) installs everything under `D:\lean` (~16 GB) and builds the proof; [`scripts/run_checks.sh`](scripts/run_checks.sh) runs the checks above. Three Windows-specific problems came up, none of which is documented upstream:

1. **Line endings.** Git for Windows defaults to `core.autocrlf=true`; the repo's dependency compatibility patches then fail with `patch does not apply`. Fix: check out with `core.autocrlf=false` and set it for lake's git calls via `GIT_CONFIG_COUNT/KEY/VALUE`.
2. **Invalid file name in a dependency.** AINTLIB contains a file named `2026-07-16T07:39:08Z`; `:` is not allowed in Windows file names, so cloning fails (it looks like a network error: `early EOF`). Fix: shallow-fetch the pinned commit and exclude that file with a sparse checkout.
3. **Transient build errors.** Parallel builds occasionally failed with `failed to read file '...olean'`. Rerunning `lake build` resumes and these disappear (three passes were needed here).

---

## Türkçe özet

OpenAI'ın 6 Ekim 2026'da yayınladığı openai/math reposundaki 107 numaralı sonuç, **matris çarpım üssünün (ω) en fazla 9/4 olduğunu** iddia ediyor ve bir Lean formalizasyonuyla geliyor. Bu repo, o formalizasyonun sıradan bir Windows 11 bilgisayarda bağımsız olarak kontrolünün kaydı. İş (makaleyi okuma, kurulum, derleme, kontroller, bu yazı) benim isteğim üzerine Claude Opus 5.5 tarafından yapıldı; ben kendi bilgisayarımda çalıştırdım.

**Sonuç:** Kanıt hatasız ve `sorry` olmadan derlendi. Üç teorem de yalnızca Lean'in standart üç aksiyomuna dayanıyor. Teorem ifadeleri ve kullandıkları tanımlar, yalnızca Mathlib'le derlenen bağımsız challenge dosyasındakilerle tam açılmış gösterimde (`pp.all`) birebir aynı. Kanıt kaynaklarında Lean çekirdeğini atlatabilecek bir yapı bulunmadı.

**Sınırlar:** Resmi Comparator aracı Linux'a özgü olduğu için çalıştırılmadı; özü elle yapıldı, ama sandbox ve ikinci bağımsız çekirdek kontrolü yok. Diğer 721 makale hakkında bir şey söylemiyor; makalenin matematiksel önemi uzmanların değerlendirmesine kalıyor.

**Windows'ta tekrar etmek için** yukarıdaki betikler ve üç Windows sorunu (satır sonları, AINTLIB'deki geçersiz dosya adı, geçici derleme hataları) ve çözümleri kullanılabilir.
