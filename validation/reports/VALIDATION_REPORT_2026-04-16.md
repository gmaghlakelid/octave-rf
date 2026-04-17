# octave-rf Phase V Validation Report

**Date**: 2026-04-16 20:38:31  
**MATLAB**: MATLAB RF Toolbox (25.2.0.2998904 (R2025b))  
**Octave**: octave-rf (11.1.0)  

## Summary

**36 PASS / 0 FAIL** across 36 pair-wise comparisons.

## Tolerance rule

A field PASSES if either `max|delta| <= tol_abs` OR `max_rel <= tol_rel`.

| Tier | tol_abs | tol_rel | Description |
|---|---|---|---|
| Tier 1 | 1e-12 | 1e-12 | Hardcoded 2/3/4-port conversions and mixed-mode |
| Tier 2 | 1e-10 | 1e-09 | Measured stripline cascade/de-embed (7000 freqs) |
| Tier 3 | 1e-10 | 1e-09 | IEEE 370 case_01 de-embedding (2500 freqs) |

## Convention note

`octave-rf` uses the same T-parameter element ordering as MATLAB RF
Toolbox (Pupalaikis convention compatible with MATLAB), so `s2t` / `t2s`
output is directly comparable without any element reordering.

## Results

| Pair | Tier | Field | max\|Δ\| | max_rel | tol_abs | tol_rel | Status | Note |
|---|---|---|---|---|---|---|---|---|
| MATLAB vs Octave | tier1 | `tier1.S2_input` | 0.00e+00 | 0.00e+00 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.S3_input` | 1.39e-17 | 1.39e-16 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.S4_input` | 0.00e+00 | 0.00e+00 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.Scc` | 6.21e-17 | 2.52e-16 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.Sdd` | 2.86e-17 | 3.23e-16 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.abcd2s_roundtrip` | 3.51e-16 | 1.33e-15 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.g2s_roundtrip` | 3.00e-15 | 2.08e-14 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.h2s_roundtrip` | 3.23e-15 | 2.92e-14 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.mm_portorder` | 0.00e+00 | 0.00e+00 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.s2abcd` | 9.74e-15 | 4.13e-16 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.s2g` | 9.32e-13 | 1.26e-14 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.s2h` | 1.89e-13 | 1.24e-14 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.s2smm` | 6.21e-17 | 1.16e-01 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.s2t` | 1.57e-16 | 1.83e-16 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.s2y_2p` | 2.86e-17 | 5.57e-16 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.s2y_4p` | 1.04e-17 | 6.06e-16 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.s2z_2p` | 2.18e-12 | 1.72e-15 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.s2z_3p` | 2.93e-14 | 4.56e-16 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.smm2s_roundtrip` | 6.94e-17 | 4.63e-16 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.snp2smp_4to1` | 0.00e+00 | 0.00e+00 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.t2s_roundtrip` | 1.57e-16 | 1.85e-16 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.y2s_2p_roundtrip` | 4.58e-16 | 3.47e-15 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.y2s_4p_roundtrip` | 2.92e-16 | 2.66e-15 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.z2s_2p_roundtrip` | 1.56e-15 | 1.45e-14 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier1 | `tier1.z2s_3p_roundtrip` | 1.57e-16 | 1.39e-15 | 1e-12 | 1e-12 | PASS |  |
| MATLAB vs Octave | tier2 | `tier2.S_119` | 0.00e+00 | 0.00e+00 | 1e-10 | 1e-09 | PASS |  |
| MATLAB vs Octave | tier2 | `tier2.S_119_halfR` | 0.00e+00 | 0.00e+00 | 1e-10 | 1e-09 | PASS |  |
| MATLAB vs Octave | tier2 | `tier2.S_238` | 0.00e+00 | 0.00e+00 | 1e-10 | 1e-09 | PASS |  |
| MATLAB vs Octave | tier2 | `tier2.cascade_119_119` | 5.63e-14 | 1.99e-11 | 1e-10 | 1e-09 | PASS |  |
| MATLAB vs Octave | tier2 | `tier2.deembed_238_119` | 7.88e-13 | 3.11e-10 | 1e-10 | 1e-09 | PASS |  |
| MATLAB vs Octave | tier2 | `tier2.freq` | 0.00e+00 | 0.00e+00 | 1e-10 | 1e-09 | PASS |  |
| MATLAB vs Octave | tier3 | `tier3.S_FDF` | 0.00e+00 | 0.00e+00 | 1e-10 | 1e-09 | PASS |  |
| MATLAB vs Octave | tier3 | `tier3.S_fixL` | 0.00e+00 | 0.00e+00 | 1e-10 | 1e-09 | PASS |  |
| MATLAB vs Octave | tier3 | `tier3.S_fixR` | 0.00e+00 | 0.00e+00 | 1e-10 | 1e-09 | PASS |  |
| MATLAB vs Octave | tier3 | `tier3.deembed_case01` | 4.78e-15 | 2.14e-13 | 1e-10 | 1e-09 | PASS |  |
| MATLAB vs Octave | tier3 | `tier3.freq` | 0.00e+00 | 0.00e+00 | 1e-10 | 1e-09 | PASS |  |

## Reproduction

```matlab
% On MATLAB (needs RF Toolbox):
cd D:\Claude_work\octave-rf\validation
run_matlab
```

```octave
% On Octave (needs pkg rf installed or inst/ on path):
cd D:/Claude_work/octave-rf/validation
run_octave
```

```bash
# On any machine with scikit-rf (optional third reference):
cd D:/Claude_work/octave-rf/validation
python run_python.py
```

```
% Portable (MATLAB or Octave):
compare_results
```
