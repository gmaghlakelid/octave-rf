# octave-rf Phase V — Validation against MATLAB RF Toolbox

This directory holds the infrastructure to validate `octave-rf` against
MATLAB's proprietary RF Toolbox, for two properties:

1. **Usage parity** — function signatures, argument conventions, and data
   structures match MATLAB's as closely as legally/practically possible, so
   user code calling `octave-rf` functions ports to MATLAB RF Toolbox (or
   vice-versa) with minimal changes.
2. **Numerical parity** — for identical inputs, both implementations produce
   identical outputs to floating-point precision.

---

## Layout

| File | Role |
|---|---|
| `run_matlab.m`       | Run in MATLAB (needs RF Toolbox). Produces `matlab_results.mat`. |
| `run_octave.m`       | Run in Octave (needs `pkg load rf` or `addpath ../inst`). Produces `octave_results.mat`. |
| `compare_results.m`  | Portable (MATLAB or Octave). Loads both `.mat` files, diffs every numeric field, prints the pass/fail table, and writes `reports/VALIDATION_REPORT_YYYY-MM-DD.md`. |
| `reports/`           | Dated Markdown reports committed to the repo (artifact for paper citation / GitHub browsing). |
| `*_results.mat`      | Binary artifacts — `.gitignored`, regenerable. |

---

## Quick start

### Step 1 — Generate MATLAB reference (MATLAB + RF Toolbox required)

On a Windows machine with MATLAB R2020b or newer installed:

```matlab
cd D:\Claude_work\octave-rf\validation
run_matlab
%   -> matlab_results.mat
```

### Step 2 — Generate Octave reference

On any machine with Octave ≥ 8.0 and either the installed `rf` package or
this repo on the Octave path:

```octave
cd D:/Claude_work/octave-rf/validation
run_octave
%   -> octave_results.mat
```

### Step 3 — Compare (runs in either MATLAB or Octave)

Copy both `.mat` files to the same directory, then:

```matlab
compare_results
```

Prints a pass/fail table and writes `reports/VALIDATION_REPORT_YYYY-MM-DD.md`.

### Running against multiple MATLAB versions

`run_matlab.m` writes two `.mat` files on every run:

| File | Purpose |
|---|---|
| `matlab_results.mat`           | Canonical name — `compare_results.m` reads this. Overwritten on every run. |
| `matlab_results_<RELEASE>.mat` | Release-stamped archive (e.g., `matlab_results_R2020b.mat`). Survives subsequent runs from other releases. |

To validate `octave-rf` against both **MATLAB R2020b** and a current release
(e.g., **R2025a**):

```matlab
% On the R2020b machine:
cd D:\Claude_work\octave-rf\validation
run_matlab                              % writes matlab_results.mat
                                        %   AND matlab_results_R2020b.mat
% Copy matlab_results_R2020b.mat to the R2025 machine (scp / USB / etc.)

% On the R2025 machine:
cd D:\Claude_work\octave-rf\validation
run_matlab                              % writes matlab_results.mat
                                        %   AND matlab_results_R2025a.mat
% Now you have both _R2020b and _R2025a stamped files in the same dir.
```

Then run the comparison twice, renaming the stamped file to the canonical
name each time:

```matlab
% Compare against R2020b reference:
copyfile('matlab_results_R2020b.mat', 'matlab_results.mat');
compare_results      % -> reports/VALIDATION_REPORT_YYYY-MM-DD.md (save/rename this)

% Compare against R2025a reference:
copyfile('matlab_results_R2025a.mat', 'matlab_results.mat');
compare_results      % -> reports/VALIDATION_REPORT_YYYY-MM-DD.md (save/rename this)
```

Rename the two generated reports (e.g. `..._R2020b.md` and `..._R2025a.md`)
before running the second comparison so they are not overwritten.

> **Also valuable**: compare the two MATLAB release outputs against each
> other (not just against Octave). Any `max|Δ|` between `_R2020b.mat` and
> `_R2025a.mat` is MATLAB's own bit-drift across versions — expected to
> be ≤ 1e-14 but worth measuring.

---

## What is tested

Three tiers, all at `z0 = 50 Ω`.

### Tier 1 — Hardcoded conversions (24 values, numerical parity)

Small, well-conditioned 2×2×K, 3×3×K, and 4×4×K S-matrices built
deterministically in both scripts (bit-identical inputs).  Exercises every
conversion in `octave-rf`:

- S ↔ T, S ↔ Z, S ↔ Y, S ↔ ABCD, S ↔ H, S ↔ G
- N-port Z (3-port) and Y (4-port)
- Port reorder (`snp2smp`)
- Mixed-mode (`s2smm` → `Sdd`, `Scc`, round-trip `smm2s`)

Expected tolerance: `max|Δ| ≤ 1e-13`.

### Tier 2 — Measured stripline cascade / de-embed (6 values)

Uses `examples/pcb_stripline_119mm.s2p` (measured 119 mm stripline) and
`examples/pcb_stripline_238mm.s2p` (same stripline, 2× length).  Exercises
`cascadesparams` and `deembedsparams` on a real measured dataset with 7000
frequency points.

Expected tolerance: `max|Δ| ≤ 1e-10`.

> **Note**: Tier 2 does *not* compare `cascade(119, 119)` against the
> physical 238 mm measurement — physical connector reflections make those
> differ.  It compares only that **MATLAB** and **Octave** produce the same
> mathematical cascade result.

### Tier 3 — IEEE 370 case_01 de-embedding (5 values)

Uses the IEEE P370 reference files in `examples/`:

- `case_01_F-DUT1-F.s2p` — simulated fixture-DUT-fixture cascade
- `case_01_fixL.s2p`     — extracted left fixture (IEEE P370 TG1 output)

Workflow: construct right fixture by port-swap of left fixture
(`snp2smp(fixL, [2 1])` — valid for IEEE370's symmetric 2×thru split), then
de-embed to recover the DUT.

Expected tolerance: `max|Δ| ≤ 1e-10` between MATLAB and Octave.

Tier 3 validates MATLAB↔Octave numerical agreement on a real SI workflow.
It does **not** validate the physical accuracy of the de-embedded DUT vs
the ground-truth `case_01_DUT1.s2p` — that would validate the IEEE P370 TG1
algorithm, which is outside the scope of this octave-rf package.

---

## Usage-syntax parity — side by side

The operations tested above, expressed in each environment:

| Operation | MATLAB (RF Toolbox) | Octave (pkg rf) |
|---|---|---|
| Load Touchstone file          | `s = sparameters('x.s2p')`          | `[f, S, z0] = fromtouchn('x.s2p');` then `s = sparameters(S, f);` |
| Extract single S-element      | `S21 = rfparam(s, 2, 1)`            | `S21 = rfparam(s, 2, 1)` |
| S → T                         | `T = s2t(s.Parameters)`             | `T = s2t(s.Parameters)` |
| T → S                         | `S = t2s(T)`                        | `S = t2s(T)` |
| S → Z                         | `Z = s2z(s.Parameters, 50)`         | `Z = s2z(s.Parameters, 50)` |
| Z → S                         | `S = z2s(Z, 50)`                    | `S = z2s(Z, 50)` |
| S → Y                         | `Y = s2y(s.Parameters, 50)`         | `Y = s2y(s.Parameters, 50)` |
| S → ABCD                      | `A = s2abcd(s.Parameters, 50)`      | `A = s2abcd(s.Parameters, 50)` |
| Cascade                       | `sc = cascadesparams(sa, sb)`       | `sc = cascadesparams(sa, sb)` |
| De-embed                      | `sd = deembedsparams(sm, sf1, sf2)` | `sd = deembedsparams(sm, sf1, sf2)` |
| Renormalize                   | `s2 = sparameters(s1.Parameters, s1.Frequencies, 75)` | `s2 = sparameters(s1, 75)` (Form 3) |
| Port reorder (N-port)         | `Sp = snp2smp(S, 50, [3 4 1 2], 50)` | `Sp = snp2smp(S, [3 4 1 2])` |
| Mixed-mode (4→Sdd/Sdc/Scd/Scc)| `[Sdd,Sdc,Scd,Scc] = s2smm(S)`       | `Smm = s2smm(S, [1 3 2 4])`; slice `Smm(1:2,1:2,:)` etc |
| Mixed-mode → single-ended     | `S = smm2s(Sdd,Sdc,Scd,Scc)`         | `S = smm2s(Sdd,Sdc,Scd,Scc, [1 3 2 4])` |

### Documented differences

- **Touchstone I/O**: MATLAB's `sparameters(filename)` reads `.s2p`/`.s4p`
  directly; `octave-rf` does not ship a Touchstone reader yet.  Use the
  bundled `examples/fromtouchn.m` or `scikit-rf`'s Touchstone parser.  A
  future `readtouchstone.m` is on the roadmap.
- **`sparameters` fields**: MATLAB's class exposes `.Parameters`,
  `.Frequencies`, `.Impedance`, `.NumPorts`.  `octave-rf`'s struct exposes
  only `.Parameters` and `.Frequencies` — the Form-2 constructor
  `sparameters(P, f, z0)` renormalises to 50 Ω internally (documented
  design choice for the IEEE P370 workflow).
- **`snp2smp`** signature: MATLAB's takes `(S, z0, newports, termz)` with
  explicit impedances; `octave-rf`'s takes just `(S, portorder)` and
  assumes matched terminations at the reference impedance.
- **`s2smm` / `smm2s`**: MATLAB's `s2smm(S)` returns four separate outputs
  `[Sdd, Sdc, Scd, Scc]` and assumes standard port pairing.  `octave-rf`'s
  `s2smm(S, portorder)` returns the full 4×4 mixed-mode matrix and takes
  an explicit `portorder = [D+1 D-1 D+2 D-2]`.
- **`s2g` / `g2s`**: not currently exposed by MATLAB's RF Toolbox.
  `run_matlab.m` includes a local H-inverse helper so Tier 1 can still
  compare these.

---

## Tolerances and what they mean

| Symbol | Meaning |
|---|---|
| `max|Δ|` | Maximum element-wise absolute difference between MATLAB and Octave outputs |
| `max_rel` | Maximum element-wise relative difference (avoiding 0/0 on all-zero references) |
| Tier 1 target | `1e-13` — both implementations use the same closed-form matrix algebra; any deviation is purely IEEE-754 rounding |
| Tier 2/3 target | `1e-10` — file-based workflows cascade multiple matrix inversions, accumulating rounding |

A result at `max|Δ| = 2e-16` is "bit-identical within one ulp" — the gold
standard.  `1e-12 … 1e-10` indicates inversion-accumulated rounding on
large matrices, also acceptable for signal-integrity engineering.

---

## Reports

Successful runs write a dated Markdown report to
`reports/VALIDATION_REPORT_YYYY-MM-DD.md` with the full pass/fail table.
These reports are committed so they are visible on GitHub and can be cited
by SHA from the EPEPS/EMC+SIPI paper.

---

## Troubleshooting

**`matlab_results.mat` missing when running compare_results**: you need to
run `run_matlab` on a MATLAB machine first, then copy the `.mat` file into
this directory before running `compare_results`.

**`rf` package not found in Octave**: either install the package
(`pkg install https://github.com/Sparamix/octave-rf/.../rf-x.y.z.tar.gz`)
or add `../inst` to the Octave path manually — `run_octave.m` does this
automatically when invoked via its full path.

**Frequency-count mismatch between `pcb_stripline_119mm.s2p` and
`_238mm.s2p`**: both files in `examples/` share the same 7000-point grid
by construction.  If you replace them with your own measurements, ensure
the frequency grids match to < 1 mHz.

**MATLAB release compatibility**: `run_matlab.m` uses only RF Toolbox APIs
available from R2014b onward (R2020b is fully supported).  If you hit an
"Undefined function" error on an older release, report which function and
we'll add a version-gated fallback similar to `local_s2g` / `local_g2s`.
The `contains()` helper used only in the toolbox-version banner needs
R2016b+ — on older releases the banner shows `(n/a)` but the rest of the
script works.

---

## Why this matters

For `octave-rf` to be credible as a drop-in replacement for users who
cannot afford MATLAB + RF Toolbox, we have to demonstrate — not just claim
— that:

1. The math is identical to floating-point precision on the same inputs.
2. The calling conventions line up well enough that porting is trivial.

The combination of **Tier 1** (machine-epsilon agreement on hardcoded
matrices), **Tier 2** (real measured 7000-point dataset), and **Tier 3**
(standard IEEE 370 SI workflow) covers the three use-cases a reviewer or
user would want to see before trusting the package.
