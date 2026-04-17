# octave-rf Publication Checklist

Step-by-step guide to publish `octave-rf` as a registered GNU Octave package.

**Status legend**: ⬜ TODO  ✅ DONE  ⚠️ BLOCKED / needs attention

---

## Phase A — Textbook Reference Verification ✅ DONE (2026-04-15)

Verified every formula in all 26 .m files against physical books (Pozar,
Pupalaikis, Hall & Heck).  Added exact page + equation numbers to every
citation.  Caught and corrected several wrong references:

- Pozar Eq. 4.54-4.55 cited for T-parameters → actually reference plane
  shifts (removed)
- Pupalaikis mixed-mode cited as Ch. 8 → actually Ch. 7 §7.3 (fixed)
- Hall & Heck mixed-mode cited as Ch. 8 → actually Ch. 7 + §9.2.7 (fixed)
- Pozar Table 4.2 cited for H/G parameters → table doesn't include them
  (clarified)

**Artifacts**: `doc/REFERENCES.md` (verified citations), all `inst/*.m` files
updated.

---

## Phase A.1 — Test Hardening ✅ DONE (2026-04-15)

Fixed the `s2z.m` BIST tests that produced "matrix singular to machine
precision" warnings.  Root cause: unseeded `rand()` and an ideal-thru test
case with formally undefined Z-parameters.

**Result**: 85 → 100 BIST tests, zero warnings across all files.

**Deferred** (recommended before formal release):
- Deterministic seeding for all rand-using tests (~20 files)
- `%!error` coverage for all input-validation paths
- Tighter tolerances where safe
- Cross-function consistency tests

---

## Phase V — MATLAB + scikit-rf Validation ✅ DONE (2026-04-16/17)

### V.1 — Validation infrastructure ✅

Created `validation/` with 3 generators + 1 comparator:
- `run_matlab.m` — MATLAB R2025b RF Toolbox (25.2)
- `run_octave.m` — octave-rf on Octave 11.1.0
- `run_python.py` — scikit-rf 1.11.0 + NumPy 2.4.3
- `compare_results.m` — portable, diffs all pairs, writes dated reports

### V.2 — Convention fix discovered by validation ✅

The validation caught a T-parameter element-ordering mismatch between
octave-rf and MATLAB.  Root cause: octave-rf originally used Pupalaikis
Convention A (T11 = -det(S)/S21); MATLAB uses the other ordering
(T11 = 1/S21).  Both are mathematically equivalent (rot180 relationship),
but the difference broke direct compatibility.

**Fix**: changed `s2t.m` and `t2s.m` to use the MATLAB-compatible ordering.
`cascadesparams`/`deembedsparams`/`embedsparams` needed no changes (rot180
distributes over matrix multiplication).

### V.3 — Three-way results ✅

| Pair | Tests | Status |
|---|---|---|
| MATLAB R2025b vs octave-rf | 36/36 | PASS |
| scikit-rf 1.11.0 vs octave-rf | 36/36 | PASS |
| MATLAB R2025b vs scikit-rf | 36/36 | PASS |
| **Total** | **108/108** | **0 FAIL** |

**Artifacts**: `doc/VALIDATION_REPORT_MATLAB_R2025b.md`,
`doc/VALIDATION_REPORT_3WAY.md`, `validation/reports/`.

---

## Phase M — MATLAB Compatibility Fixes ✅ DONE (2026-04-16/17)

Closed all fixable API gaps found during validation:

| Fix | Description |
|---|---|
| `s2t`/`t2s` element ordering | Switched to MATLAB-compatible Pupalaikis convention |
| `snp2smp` 4-arg form | Now accepts `snp2smp(S, z0, order, z0_term)` |
| `s2smm` default portorder | portorder optional (default [1 2 3 4]); supports `[Sdd,Sdc,Scd,Scc] = s2smm(S)` 4-output form |
| `s2sdd`/`s2scc` default portorder | portorder optional (default [1 2 3 4]) |
| `smm2s` default portorder | portorder optional (default [1 2 3 4]) |
| `sparameters` fields | Added `.Impedance` and `.NumPorts` (matching MATLAB) |
| `sparameters(filename)` | Reads Touchstone files via bundled `fromtouchn` |
| `round(x, n)` shim | Extends Octave's `round` with MATLAB's 2-arg syntax (needed by IEEE P370 TG3 code) |

**Artifacts**: `doc/MATLAB_COMPATIBILITY_GUIDE.md`, updated `inst/*.m` files.

---

## Phase B — GitHub Repository ✅ DONE (2026-04-16)

- ✅ B1: Repo created at https://github.com/Sparamix/octave-rf (public, BSD-3)
- ✅ B2: Code pushed (extracted from sparamix_py370 feat/tg1-deembed subtree,
  then developed independently in the standalone repo)
- ✅ B3: `.gitignore` added
- ✅ B4: GitHub Actions CI (`apt-get install octave` + BIST run on every push)
- ✅ B5: `workflow_dispatch` added for manual CI trigger
- ✅ README.md: concise, with function table, quick example, doc links,
  AI-assisted development disclosure

---

## Phase C — Release Tarball ⬜ TODO

### C1 — Build the tarball

```bash
cd D:/Claude_work
cp -r octave-rf rf-0.1.0
# Remove non-package files
rm -rf rf-0.1.0/.git rf-0.1.0/.github rf-0.1.0/validation
tar -czf rf-0.1.0.tar.gz rf-0.1.0/
rm -rf rf-0.1.0
```

### C2 — Test the tarball locally

```octave
pkg install D:/Claude_work/rf-0.1.0.tar.gz
pkg load rf
pkg test rf
% Expected: 100/100 PASS, 0 FAIL
```

### C3 — Compute SHA256

```bash
sha256sum rf-0.1.0.tar.gz    # Linux/macOS
Get-FileHash rf-0.1.0.tar.gz  # Windows PowerShell
```

### C4 — Create GitHub Release

1. Go to https://github.com/Sparamix/octave-rf/releases/new
2. Tag: `v0.1.0`
3. Title: `rf 0.1.0`
4. Attach `rf-0.1.0.tar.gz`
5. Publish

---

## Phase D — Register with GNU Octave Package Index ⬜ TODO

1. Fork https://github.com/gnu-octave/packages
2. Create `packages/rf.yaml` with SHA256 from C3
3. Test with sandbox
4. Submit PR

---

## Phase E — Community Promotion ⬜ TODO

- [ ] Octave Discourse (https://octave.discourse.group/)
- [ ] SI-List (si-list@freelists.org)
- [ ] Reddit: r/rfelectronics, r/signalprocessing
- [ ] DesignCon / EPEPS LinkedIn groups
- [ ] Reference in IEEE paper when submitted

---

## Phase F — Upstream IEEE P370 Bug Fix PR ⬜ TODO

7 bugs found in IEEE P370 Octave code (U-001 through U-007).
See `sparamix_py370/octave-rf/upstream-contributions/PR1-bugfixes/`.

- [ ] Create GitLab account on https://opensource.ieee.org
- [ ] Fork IEEE P370 repo, submit merge request with 5 patched files

---

## Phase G — Post-Publication Maintenance ⬜ FUTURE

- [ ] Monitor GitHub Issues
- [ ] Test on new Octave releases
- [ ] v0.2.0 roadmap: Touchstone 2.0 support, >4-port mixed-mode,
      TG3 quality metric wrappers
- [ ] Run validation on MATLAB R2020b (user's work laptop)

---

## Remaining Technical Items

- [x] Pozar reference verification — ✅ Phase A
- [x] s2z BIST warning fix — ✅ Phase A.1
- [x] MATLAB validation (R2025b) — ✅ Phase V
- [x] scikit-rf validation — ✅ Phase V
- [x] T-parameter convention fix — ✅ Phase V.2
- [x] MATLAB compatibility fixes (8 items) — ✅ Phase M
- [x] GitHub repo + CI — ✅ Phase B
- [x] README + docs + AI disclosure — ✅ Phase B
- [ ] Release tarball + pkg install test — ⬜ Phase C
- [ ] gnu-octave/packages registration — ⬜ Phase D
- [ ] MATLAB R2020b validation run — ⬜ (user's work laptop)
- [ ] Community promotion — ⬜ Phase E
- [ ] Upstream IEEE P370 bug fix PR — ⬜ Phase F
