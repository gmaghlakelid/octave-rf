# octave-rf Examples

Self-contained Octave scripts demonstrating the octave-rf package on real measurement data.
Each script runs standalone — no additional toolboxes required.

## Quick Start

```octave
cd octave-rf/examples
octave-cli --no-gui -q demo_basic_conversions.m
octave-cli --no-gui -q demo_deembed.m
octave-cli --no-gui -q demo_mixed_mode.m
```

## Demo Scripts

| Script | What it shows |
|--------|---------------|
| `demo_basic_conversions.m` | S↔T, S↔Z, S↔Y, S↔ABCD, S↔H, S↔G, renormalization, port reordering |
| `demo_deembed.m` | IEEE P370 NZC de-embedding: 2×thru → fixtures → DUT recovery |
| `demo_mixed_mode.m` | Mixed-mode (Sdd/Scc/Sdc/Scd) analysis of a 4-port differential cable |

## Example S-Parameter Files

| File | Type | Points | Description |
|------|------|--------|-------------|
| `pcb_stripline_119mm.s2p` | 2-port | 7 000 | Real PCB stripline, 2×thru, DC–35 GHz |
| `pcb_stripline_238mm.s2p` | 2-port | 7 000 | Same PCB, FIX-DUT-FIX, for de-embedding |
| `case_01_2xThru.s2p` | 2-port | 2 500 | IEEE P370 TG1 synthetic 2×thru |
| `case_01_F-DUT1-F.s2p` | 2-port | 2 500 | IEEE P370 FIX-DUT-FIX cascade |
| `case_01_DUT1.s2p` | 2-port | 2 500 | IEEE P370 ground-truth DUT |
| `case_01_fixL.s2p` | 2-port | 2 500 | Pre-extracted left fixture (from Octave NZC) |
| `CABLE1_RX_pair.s4p` | 4-port | 6 401 | Differential cable RX pair, 10 MHz–40 GHz |
| `CABLE1_TX_pair.s4p` | 4-port | 6 401 | Differential cable TX pair |

All files are Touchstone 1.0 format, 50 Ω reference.

## Touchstone Reader

The `fromtouchn` function (in `inst/`) reads Touchstone files.  It is also
called internally by `sparameters(filename)`.  See `help fromtouchn`.

## Numerical Results

Running the demos should produce the following representative results:

**demo_basic_conversions.m** (pcb_stripline_119mm, 7000 pts):

| Conversion | Round-trip max\|diff\| |
|------------|----------------------|
| S ↔ T | 3.82e-15 |
| S ↔ Z | 1.84e-15 |
| S ↔ Y | 2.49e-15 |
| S ↔ ABCD | 5.44e-15 |
| S ↔ H | 1.85e-15 |
| S ↔ G | 3.78e-15 |
| Renorm 50→75→50 Ω | 2.03e-15 |
| Port swap round-trip | 0.00e+00 |

**demo_deembed.m** (case_01, 2500 pts):

| Test | max\|diff\| |
|------|------------|
| De-embedded DUT vs ground truth | 1.06e-11 |
| Embed/de-embed identity round-trip | 8.46e-16 |

**demo_mixed_mode.m** (CABLE1_RX_pair, 6401 pts):

| Test | max\|diff\| |
|------|------------|
| smm2s round-trip | 4.97e-16 |
| s2z/z2s 4-port round-trip | 2.22e-15 |

## References

- Pupalaikis, P.J., *S-Parameters for Signal Integrity*, Cambridge University Press, 2020.
- Hall, S.H. and Heck, H.L., *Advanced Signal Integrity for High-Speed Digital Designs*, Wiley, 2009.
- Resso, M. and Bogatin, E., *Signal Integrity Characterization Techniques*, IEC, 2018.
- IEEE P370 TG1, *Standard for Electrical Characterization of Printed Circuit Board and Related Interconnects at Frequencies up to 50 GHz*, 2020.
