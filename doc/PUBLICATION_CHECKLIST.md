# octave-rf Publication Checklist

Step-by-step guide to publish `octave-rf` as a registered GNU Octave package
and promote it to the community.

**Status legend**: ⬜ TODO  ✅ DONE  ⚠️ BLOCKED

---

## Phase A — Textbook Reference Verification ✅ COMPLETE (2026-04-15)

All Pozar, Pupalaikis, and Hall & Heck citations in `doc/REFERENCES.md` and in every
`.m` file have been verified against the physical books.  Several corrections were
identified and applied.

**Books used**:
- Pozar, D.M., *Microwave Engineering*, 4th ed., Wiley, 2012. ISBN 978-0-470-63155-3.
- Pupalaikis, P.J., *S-Parameters for Signal Integrity*, Cambridge, 2020. ISBN 978-1-108-48996-6.
- Hall, S.H. and Heck, H.L., *Advanced Signal Integrity for High-Speed Digital Designs*,
  Wiley-IEEE Press, 2009. ISBN 978-0-470-19235-1.

### Verification Results

| ✅ | Function(s) | Finding / Correction |
|----|-------------|----------------------|
| ✅ | `s2t` / `t2s` | Pozar Eq. 4.54–4.55 are reference plane shifts, **NOT T-parameters**. Pozar does not cover chain scattering T-parameters. Removed Pozar citation. Primary: [PUP] §3.6 Eq. 3.31–3.34 (p.68). Secondary: [H&H] §9.2.4 (p.390). |
| ✅ | `s2z` / `z2s` | [POZ] §4.3 Eq. 4.44–4.45 (p.181), Table 4.2 (p.192) confirmed. [PUP] §3.4.1–3.4.2 Tables 3.2–3.3 (p.55–56) matches. [H&H] §9.2.1 (p.355). |
| ✅ | `s2y` / `y2s` | [POZ] §4.2 Eq. 4.26–4.27 (p.175), Table 4.2 (p.192). [PUP] §3.4.3–3.4.4 Tables 3.4–3.5 (p.57, 59). |
| ✅ | `s2abcd` / `abcd2s` | [POZ] §4.4 Eq. 4.69 (p.189), Table 4.2 (p.192). [PUP] §3.4.5–3.4.6 Tables 3.6–3.7 Eq. 3.20 (p.60–61). [H&H] §9.2.3 (p.382). |
| ✅ | `s2h` / `h2s` / `s2g` / `g2s` | **Pozar Table 4.2 (p.192) does NOT include H or G parameters**. Removed the misleading "§4.4 Table 4.2" citation. Primary reference is [PUP] Ch. 1 §1.2 (p.16). |
| ✅ | `renormsparams` | [POZ] §4.3 Eq. 4.44–4.45 (p.181) confirmed. [PUP] Ch. 5 §5.1 (p.134) is the primary. [H&H] §9.2.6 (p.399). |
| ✅ | `cascadesparams` | Pozar §4.4 Eq. 4.71 (p.189) covers **ABCD cascade** (analogous to T-matrix cascade — Pozar doesn't present T-matrix cascade explicitly). Primary: [PUP] §3.7 Eq. 3.35 (p.69). |
| ✅ | Mixed-mode (4 fns) | **Chapter numbers were WRONG**. Was "Ch. 8" → now [PUP] **Ch. 7 §7.3.2**, Eq. 7.24–7.27 (p.197–199). H&H was "Ch. 8" → now [H&H] **Ch. 7** (p.297) + **§9.2.7** (p.400). |
| ✅ | `deembedsparams` / `embedsparams` | [PUP] §3.8–3.9 (p.69–70), Ch. 10 (p.282). [H&H] §9.2.4–9.2.5 (p.390, 395). |

### Actions Completed
1. ✅ Removed all `[VERIFY WITH BOOK]` / `[VERIFY EQUATION NUMBERS WITH BOOK]` tags from all 24 .m files
2. ✅ Removed all `†` markers and `[VERIFY]` notes from `doc/REFERENCES.md`
3. ✅ Removed `[VERIFY — not yet confirmed]` from the [POZ] table entry in REFERENCES.md
4. ✅ Added specific page numbers and equation numbers to every citation
5. ✅ Corrected the wrong Pozar T-parameter citation
6. ✅ Corrected the wrong Pupalaikis mixed-mode chapter (Ch. 8 → Ch. 7)
7. ✅ Corrected the wrong Hall & Heck mixed-mode chapter (Ch. 8 → Ch. 7 + §9.2.7)
8. ✅ Noted explicitly that Pozar Table 4.2 does not cover H/G parameters

---

## Phase B — GitHub Repository Creation

### B1 — Create the repo

1. Go to https://github.com/new (create under the `Sparamix` account)
2. Repository name: `octave-rf`
3. Description: `RF and microwave network parameter utilities for GNU Octave — enables IEEE P370 de-embedding code to run independently in Octave while remaining compatible with MATLAB RF Toolbox syntax`
4. Visibility: **Public**
5. License: **BSD 3-Clause**
6. Do NOT initialize with README (you'll push existing code)
7. Click "Create repository"

### B2 — Extract the subfolder and push

Run these commands from the `sparamix-py370/` directory:

```bash
# Extract octave-rf/ into a standalone repo
# Method: git subtree split (preserves history from this branch)

cd D:/Claude_work/sparamix_py370

# Create a branch containing only the octave-rf/ subtree
git subtree split --prefix=octave-rf -b octave-rf-standalone

# Create a new local repo from that branch
mkdir D:/Claude_work/octave-rf-repo
cd D:/Claude_work/octave-rf-repo
git init
git pull D:/Claude_work/sparamix_py370 octave-rf-standalone

# Add the GitHub remote and push
git remote add origin https://github.com/Sparamix/octave-rf.git
git branch -M main
git push -u origin main
```

### B3 — Add .gitignore and CI

In the new `octave-rf-repo/`:

```bash
# Create .gitignore
cat > .gitignore << 'EOF'
*.oct
*.o
*.a
fntests.log
octaverc
*.tar.gz
EOF
git add .gitignore
git commit -m "chore: add .gitignore"
git push
```

### B4 — Set up GitHub Actions CI

Create `.github/workflows/test.yml`:

```yaml
name: Octave Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        octave: ['8.4.0', '9.2.0', '10.1.0']
    steps:
      - uses: actions/checkout@v4
      - uses: matlab-actions/setup-octave@v1
        with:
          octave-version: ${{ matrix.octave }}
      - name: Run BIST tests
        run: |
          octave --no-gui -q --eval "
            pkg install $(pwd)
            pkg load rf
            pkg test rf
          "
```

```bash
git add .github/
git commit -m "ci: add GitHub Actions Octave test matrix"
git push
```

---

## Phase C — Release Tarball

### C1 — Build the tarball

```bash
cd D:/Claude_work/octave-rf-repo

# The tarball must contain a top-level directory named rf-0.1.0/
# pkg install expects: rf-0.1.0.tar.gz containing rf-0.1.0/DESCRIPTION etc.

cd ..
cp -r octave-rf-repo rf-0.1.0
tar -czf rf-0.1.0.tar.gz rf-0.1.0/
rm -rf rf-0.1.0
```

### C2 — Test the tarball locally

```octave
% In Octave:
pkg install D:/Claude_work/rf-0.1.0.tar.gz
pkg load rf
pkg test rf
% Expected: PASS 81/81, FAIL 0
```

### C3 — Compute SHA256

```bash
# Windows (PowerShell):
Get-FileHash rf-0.1.0.tar.gz -Algorithm SHA256

# Linux/macOS:
sha256sum rf-0.1.0.tar.gz
```

Save the output — you'll need it for the `rf.yaml` package index file.

### C4 — Create GitHub Release

1. Go to https://github.com/Sparamix/octave-rf/releases/new
2. Tag: `v0.1.0` (create new tag on main)
3. Release title: `rf 0.1.0 — Initial release`
4. Description (copy-paste):

```
## rf 0.1.0 — S-parameter utilities for GNU Octave

Provides the S-parameter utility functions needed to run IEEE P370 de-embedding
code independently in Octave while remaining compatible with MATLAB RF Toolbox
syntax.

### Install
```octave
pkg install https://github.com/Sparamix/octave-rf/releases/download/v0.1.0/rf-0.1.0.tar.gz
pkg load rf
```

### What's included
- 24 functions: S↔T, S↔Z, S↔Y, S↔ABCD, S↔H, S↔G, cascade, de-embed, embed,
  renormalize, port reorder, mixed-mode (Sdd/Scc), sparameters object
- 81 built-in self-tests, all passing
- Example S-parameter files + runnable demo scripts
- Full cross-validation against scikit-rf and Python reference to machine epsilon

### IEEE P370 compatibility
With this package installed, the `IEEEP3702xThru_Octave.m` NZC algorithm runs
unmodified in Octave using only `pkg load rf`.
```

5. Attach the `rf-0.1.0.tar.gz` file as a release asset
6. Click "Publish release"

---

## Phase D — Register with GNU Octave Package Index

The package index lives at https://github.com/gnu-octave/packages

### D1 — Fork the packages repo

1. Go to https://github.com/gnu-octave/packages
2. Click "Fork" → fork to your personal GitHub account

### D2 — Create rf.yaml

In your fork, create `package/rf.yaml`:

```yaml
---
description: >-
  RF and microwave network parameter utilities.
  S-parameter conversions (S↔T, S↔Z, S↔Y, S↔ABCD, S↔H, S↔G),
  de-embedding, cascading, port reordering, renormalization, and
  mixed-mode conversion for differential pairs.
  Enables IEEE P370 de-embedding code to run independently in GNU
  Octave while remaining compatible with MATLAB RF Toolbox syntax.
homepage: 'https://github.com/Sparamix/octave-rf'
icon: 'https://raw.githubusercontent.com/Sparamix/octave-rf/main/doc/icon.png'
maintainer:
  - 'Giorgi Maghlakelidze <giorgi.snp@pm.me>'
name: rf
versions:
  - id: 'v0.1.0'
    date: '2026-03-28'
    sha256: '<paste SHA256 from Step C3>'
    url: 'https://github.com/Sparamix/octave-rf/releases/download/v0.1.0/rf-0.1.0.tar.gz'
    depends:
      - pkg: 'octave'
        min: '6.0.0'
```

### D3 — Create a package icon (optional but recommended)

Create a simple 128×128 PNG icon and save to `doc/icon.png` in your octave-rf repo.
Push it before creating the PR (the packages index needs the icon URL to be live).

### D4 — Test with packages-sandbox

The packages repo has a sandbox tester. In your fork:

```bash
git clone https://github.com/YOUR_USERNAME/packages.git
cd packages
# Install the sandbox tool (see packages repo README)
python3 packages.py build rf
```

Fix any errors before submitting the PR.

### D5 — Submit the PR

1. Push your `package/rf.yaml` to your fork
2. Open a Pull Request to `gnu-octave/packages` main branch
3. PR title: `Add rf package — RF/microwave network parameter utilities`
4. PR description:

```
Adds the `rf` package providing S-parameter conversions and network operations
for RF and microwave engineering.

Enables IEEE P370 de-embedding code to run independently in GNU Octave while
remaining compatible with MATLAB RF Toolbox syntax.

- 24 functions, 81 BIST tests, 0 failures
- Tested on Octave 8, 9, 10, 11
- Full validation report: https://github.com/Sparamix/octave-rf/blob/main/doc/VALIDATION_REPORT.md
- License: BSD-3-Clause
```

---

## Phase E — Promotion

### E1 — Octave community

- [ ] Post to **Octave Discourse** (https://octave.discourse.group/)
  - Category: "Packages"
  - Title: "New package: `rf` — RF/microwave network parameters for Octave"
  - Include: what it does, how to install, link to GitHub, mention IEEE P370 use case

- [ ] Post to **Octave mailing list** (help@octave.org)
  - Announce new package, brief description, installation command

### E2 — Signal integrity community

- [ ] Post to **SI-List** (si-list@freelists.org)
  - Announce that IEEE P370 de-embedding now runs independently in Octave
  - Include installation command, link to GitHub and examples

- [ ] Post to **Signal Integrity Academy** forums (if applicable)

- [ ] Post to **DesignCon / EPEPS LinkedIn groups**

### E3 — Open-source/RF communities

- [ ] Reddit: **r/rfelectronics**, **r/signalprocessing**, **r/electronics**
  - Short post linking to GitHub + key one-liner: "first RF package for Octave"

- [ ] **Hackaday.io** project page (optional)

### E4 — Academic channels (when paper is submitted)

- [ ] Reference the package in the IEEE EPEPS 2026 paper abstract
- [ ] Reference the package in the IEEE EMC+SIPI 2026 paper
- [ ] After acceptance, add DOI to README and package description

---

## Phase F — Upstream Bug Fix PR (IEEE P370)

See `upstream-contributions/PR1-bugfixes/README.md` for full details.

- [ ] Create a GitLab account on https://opensource.ieee.org (if not already done)
- [ ] Fork the IEEE P370 repo: https://opensource.ieee.org/elec-char/ieee-370/
- [ ] Create branch `fix/octave-compatibility-bugs`
- [ ] Copy the 5 patched files from `upstream-contributions/PR1-bugfixes/files/` to the fork:
  - `TG1/IEEEP3702xThru_Octave.m`
  - `TG1/IEEEP370Zc2xThru_Octave.m`
  - `TG3/qualityCheckFrequencyDomain.m`
  - `TG3/qualityCheck.m`
  - `TG3/extrapolateMatrix.m`
- [ ] Open Merge Request using the title and description from `PR1-bugfixes/README.md`
- [ ] Monitor for reviewer feedback

---

## Phase G — Post-Publication Maintenance

- [ ] Monitor GitHub Issues; respond within 1 week
- [ ] When Octave releases a new version, run `pkg test rf` and verify
- [ ] For version 0.2.0, consider adding:
  - Touchstone file reader (`readtouchstone.m`) so users don't need `fromtouchn.m`
  - TG3 quality metric wrappers (bridge to `sparamix.py370`)
  - Support for >4-port mixed-mode (Nport generalization)
- [ ] Update `NEWS` file and `DESCRIPTION` version for each release

---

## Remaining Technical Items

- [x] **Pozar verification** (Phase A above) — ✅ done 2026-04-15
- [ ] **ZC E2E test** — once the U-007 upstream bug fix is accepted (or use local patched copy),
      add a test for `IEEEP370Zc2xThru_Octave.m` in `test/test_e2e_ieee370.m`
- [ ] **`doc/VALIDATION_REPORT.md`** — internal package summary doc (lower priority;
      primarily for users who want to understand validation depth)
- [ ] **GitHub release URL** — update `octave-rf/README.md` installation line once the
      actual release exists (currently points to a URL that doesn't exist yet)
