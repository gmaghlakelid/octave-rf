# MATLAB RF Toolbox Compatibility Guide

This guide documents how `octave-rf` relates to MATLAB RF Toolbox: what
works identically, what differs, and how to write portable code that runs
in both environments.

**Goal**: IEEE P370 de-embedding code (and general S-parameter workflows)
should run independently in GNU Octave while remaining compatible with
MATLAB RF Toolbox syntax.

---

## Quick reference — function compatibility table

| Function | MATLAB RF Toolbox | octave-rf | Compatible? | Notes |
|---|---|---|---|---|
| `s2t(S)` | yes | yes | identical | Same element ordering (Pupalaikis convention) |
| `t2s(T)` | yes | yes | identical | |
| `s2z(S, z0)` | yes | yes | identical | N-port, uniform z0 |
| `z2s(Z, z0)` | yes | yes | identical | |
| `s2y(S, z0)` | yes | yes | identical | |
| `y2s(Y, z0)` | yes | yes | identical | |
| `s2abcd(S, z0)` | yes | yes | identical | 2-port only |
| `abcd2s(A, z0)` | yes | yes | identical | |
| `s2h(S, z0)` | yes | yes | identical | 2-port only |
| `h2s(H, z0)` | yes | yes | identical | |
| `s2g(S, z0)` | no | yes | octave-rf extra | MATLAB does not have s2g/g2s |
| `g2s(G, z0)` | no | yes | octave-rf extra | |
| `cascadesparams` | yes | yes | identical | Accepts raw arrays and sparameters structs |
| `deembedsparams` | yes | yes | identical | |
| `embedsparams` | no | yes | octave-rf extra | Convenience wrapper: `cascadesparams(f1, dut, f2)` |
| `renormsparams` | no | yes | octave-rf extra | MATLAB uses `sparameters(obj, z0_new)` instead |
| `snp2smp` | yes | yes | compatible | See "snp2smp" section below |
| `s2smm` | yes | yes | compatible | See "Mixed-mode" section below |
| `smm2s` | yes | yes | compatible | See "Mixed-mode" section below |
| `s2sdd` | yes | yes | compatible | portorder optional (default [1 2 3 4]) |
| `s2scc` | yes | yes | compatible | portorder optional (default [1 2 3 4]) |
| `sparameters` | yes (class) | yes (struct) | compatible | See "sparameters" section below |
| `rfparam` | yes | yes | identical | |
| `ifft_symmetric` | built-in `ifft(x,'symmetric')` | yes | octave-rf shim | Use `ifft_symmetric(x)` for portable code |

---

## Identical functions (no differences)

These functions have the same signatures, the same default arguments, and
produce bit-identical results (validated to floating-point precision against
MATLAB R2025b; see `doc/VALIDATION_REPORT_MATLAB_R2025b.md`):

- **S-parameter conversions**: `s2t`, `t2s`, `s2z`, `z2s`, `s2y`, `y2s`,
  `s2abcd`, `abcd2s`, `s2h`, `h2s`
- **Network operations**: `cascadesparams`, `deembedsparams`
- **Index extraction**: `rfparam(s, i, j)`

Portable code using only these functions runs unmodified in both MATLAB
and Octave.

---

## Compatible functions (minor signature differences)

### `snp2smp` — port reorder

| Form | MATLAB | octave-rf |
|---|---|---|
| `snp2smp(S, z0, order, z0_term)` | yes | yes |
| `snp2smp(S, order)` | no | yes |

MATLAB requires the 4-argument form with explicit reference impedances.
octave-rf accepts both the 4-argument (MATLAB-compatible) form and the
simpler 2-argument form (pure row/column permutation).

**Portable code**: use the 4-argument form.
```matlab
Sp = snp2smp(S, 50, [4 3 2 1], 50);   % works in both
```

### `s2smm` — single-ended to mixed-mode

| Form | MATLAB | octave-rf |
|---|---|---|
| `[Sdd,Sdc,Scd,Scc] = s2smm(S)` | yes | yes |
| `Smm = s2smm(S)` | yes (full 4x4) | yes (full 4x4) |
| `s2smm(S, portorder)` | no | yes |

MATLAB's `s2smm(S)` assumes adjacent-pair port pairing [1 2 3 4].
octave-rf defaults to the same pairing when `portorder` is omitted, and
also accepts an explicit `portorder` argument for non-standard pairing.

**Portable code**: omit `portorder` if your pairing is [1 2 3 4] (the
most common case); use the 4-output form for individual blocks.
```matlab
[Sdd, Sdc, Scd, Scc] = s2smm(S);   % works in both
```

### `s2sdd` / `s2scc` — extract differential / common-mode block

| Form | MATLAB | octave-rf |
|---|---|---|
| `s2sdd(S)` | yes (default pairing) | yes (default [1 2 3 4]) |
| `s2sdd(S, portorder)` | no | yes |

**Portable code**: omit `portorder` for the standard adjacent-pair case.
```matlab
Sdd = s2sdd(S);    % works in both
Scc = s2scc(S);    % works in both
```

### `smm2s` — mixed-mode to single-ended

| Form | MATLAB | octave-rf |
|---|---|---|
| `smm2s(Sdd, Sdc, Scd, Scc)` | yes | no (requires portorder) |
| `smm2s(Sdd, Sdc, Scd, Scc, portorder)` | no | yes |

This is the one remaining asymmetry: MATLAB's `smm2s` does not take a
`portorder` argument; octave-rf requires it.

**Portable code**: wrap with a default when portability is needed.
```matlab
% In octave-rf:
S = smm2s(Sdd, Sdc, Scd, Scc, [1 2 3 4]);
% In MATLAB:
S = smm2s(Sdd, Sdc, Scd, Scc);
```

---

## `sparameters` object

MATLAB's `sparameters` is a class; octave-rf's is a plain struct.  Both
expose the same four fields:

| Field | MATLAB | octave-rf | Notes |
|---|---|---|---|
| `.Parameters` | NxNxK complex | same | Identical layout |
| `.Frequencies` | Kx1 double (Hz) | same | Identical layout |
| `.Impedance` | scalar or vector | scalar (always 50) | See note below |
| `.NumPorts` | integer | integer | |

**Impedance convention**: MATLAB's `sparameters(P, f, z0)` stores the
S-parameters at the original `z0` and sets `.Impedance = z0`.  octave-rf's
constructor renormalizes to 50 ohm internally and sets `.Impedance = 50`.
This means that for `z0 != 50`, the stored `.Parameters` arrays will differ
between the two environments even though they represent the same physical
network.

**Portable code**: always work at z0 = 50 ohm (the SI/IEEE P370 standard),
or use the conversion functions (`s2z`, `z2s`) which take an explicit `z0`
argument and produce identical results in both environments.

### Constructor forms

| Form | MATLAB | octave-rf |
|---|---|---|
| `sparameters(P, f)` | yes | yes |
| `sparameters(P, f, z0)` | yes (stores at z0) | yes (renorms to 50) |
| `sparameters(obj, z0_new)` | yes (renorm) | yes (renorm) |
| `sparameters(filename)` | yes | **no** |

**Touchstone file I/O**: MATLAB's `sparameters('file.s2p')` reads Touchstone
files directly.  octave-rf does not have this form.  Use the bundled
`fromtouchn.m` reader (in `examples/`) or any other Touchstone parser:
```octave
[freq, S, z0] = fromtouchn('myfile.s2p');
s = sparameters(S, freq);
```

---

## octave-rf extras (not in MATLAB)

These functions are provided by octave-rf but do not exist in MATLAB RF
Toolbox.  Code that uses them will not run in MATLAB without providing
equivalent helpers.

| Function | Purpose | MATLAB equivalent |
|---|---|---|
| `s2g(S, z0)` / `g2s(G, z0)` | S to/from inverse-hybrid G-parameters | Compute via `s2h` + matrix inverse |
| `renormsparams(S, z_new, z_old)` | Renormalize S-parameters | `sparameters(sparameters(S,f,z_old), z_new)` |
| `embedsparams(dut, fix1, fix2)` | Embed DUT inside fixtures | `cascadesparams(fix1, cascadesparams(dut, fix2))` |
| `ifft_symmetric(x)` | `real(ifft(x))` | `ifft(x, 'symmetric')` |

---

## Writing portable MATLAB/Octave code

### Recommended pattern for Touchstone loading

```matlab
if exist('OCTAVE_VERSION', 'builtin')
    %% Octave path
    [freq, S, z0] = fromtouchn('myfile.s2p');
    s = sparameters(S, freq);
else
    %% MATLAB path
    s = sparameters('myfile.s2p');
end

%% From here on, code is identical in both:
T   = s2t(s.Parameters);
Z   = s2z(s.Parameters, 50);
S21 = rfparam(s, 2, 1);
Sdd = s2sdd(s.Parameters);
sc  = cascadesparams(s, s);
```

### Functions safe to call identically in both environments

```matlab
s2t, t2s, s2z, z2s, s2y, y2s, s2abcd, abcd2s, s2h, h2s,
rfparam, cascadesparams, deembedsparams,
s2sdd, s2scc, s2smm (with no portorder and [Sdd,Sdc,Scd,Scc] outputs)
```

### Functions requiring care

```matlab
snp2smp     — use 4-arg form: snp2smp(S, 50, order, 50)
smm2s       — MATLAB takes 4 args, octave-rf takes 5 (extra portorder)
sparameters — file-reading form not available in octave-rf
```

---

## Validation

All compatible functions have been cross-validated against MATLAB R2025b
RF Toolbox (v25.2) to floating-point precision.  See
[VALIDATION_REPORT_MATLAB_R2025b.md](VALIDATION_REPORT_MATLAB_R2025b.md)
for the full 36-field comparison (36/36 PASS).
