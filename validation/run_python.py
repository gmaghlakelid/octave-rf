#!/usr/bin/env python3
"""
validation/run_python.py

scikit-rf side reference generator for the octave-rf Phase V validation.
Produces python_results.mat (MATLAB v6 format) with the same field layout
as matlab_results.mat and octave_results.mat so that compare_results.m can
diff all three pair-wise.

Requires:
    pip install scikit-rf scipy numpy

Usage:
    cd D:/Claude_work/octave-rf/validation
    python run_python.py
"""

import os
import sys
from datetime import datetime
from pathlib import Path

import numpy as np
import skrf
import scipy.io

THIS_DIR = Path(__file__).resolve().parent
EXAMPLES_DIR = THIS_DIR.parent / "examples"


def skrf_to_nxnxk(arr):
    """Convert scikit-rf (K, N, N) to octave-rf (N, N, K) layout."""
    return np.moveaxis(arr, 0, -1)


def rot180_pages(T):
    """Apply 180-degree rotation to each 2x2 page of an (2, 2, K) array.

    scikit-rf uses Pupalaikis Convention A for T-parameters.  MATLAB RF
    Toolbox and octave-rf use the other ordering (Convention B / MATLAB
    convention).  The two are related by rot180 of every 2x2 slice.
    Applying this before saving makes the .mat directly comparable to
    the other two implementations.
    """
    T_out = np.empty_like(T)
    for k in range(T.shape[2]):
        T_out[:, :, k] = np.rot90(T[:, :, k], 2)
    return T_out


def build_hardcoded_matrices():
    """Build the same deterministic test matrices as run_matlab.m / run_octave.m."""
    K2 = 8
    S2 = np.zeros((2, 2, K2), dtype=complex)
    for k in range(K2):
        phi = k * 0.20
        S2[0, 0, k] = 0.10 * np.exp(1j * phi) + 0.02
        S2[1, 1, k] = 0.08 * np.exp(1j * (phi + 0.3)) + 0.03
        S2[1, 0, k] = 0.85 * np.exp(-1j * phi)
        S2[0, 1, k] = S2[1, 0, k]

    K3 = 5
    S3 = np.zeros((3, 3, K3), dtype=complex)
    for k in range(K3):
        phi = k * 0.25
        a = 0.05 + 0.03 * (k + 1)
        S3[:, :, k] = np.array([
            [a * np.exp(1j * phi),         0.40 * np.exp(-1j * phi), 0.10 * np.exp(1j * 0.1 * (k + 1))],
            [0.40 * np.exp(-1j * phi),     a * np.exp(1j * (phi + 0.2)), 0.20 * np.exp(-1j * 0.2 * (k + 1))],
            [0.10 * np.exp(1j * 0.1 * (k + 1)), 0.20 * np.exp(-1j * 0.2 * (k + 1)), a * np.exp(1j * (phi + 0.4))],
        ])

    K4 = 5
    S4 = np.zeros((4, 4, K4), dtype=complex)
    for k in range(K4):
        phi = k * 0.30
        D = 0.05 + 0.02 * (k + 1)
        off = 0.15
        S4[:, :, k] = D * np.exp(1j * phi) * np.eye(4) + off * (
            (np.ones((4, 4)) - np.eye(4)) * np.exp(1j * phi * 0.5)
        )
        S4[:, :, k] = 0.5 * (S4[:, :, k] + S4[:, :, k].T)  # reciprocal

    return S2, S3, S4


def make_network(S_nxnxk, freqs_hz, z0=50):
    """Create a scikit-rf Network from (N, N, K) array + freq vector."""
    S_knxn = np.moveaxis(S_nxnxk, -1, 0)  # (K, N, N)
    f = skrf.Frequency.from_f(freqs_hz, unit="hz")
    return skrf.Network(frequency=f, s=S_knxn, z0=z0)


def read_s2p(filename):
    """Read Touchstone file, return (N, N, K) S-matrix and freq vector."""
    n = skrf.Network(str(filename))
    return skrf_to_nxnxk(n.s), n.f


def main():
    print()
    print("========================================================")
    print(" scikit-rf  ->  Phase V validation (Python side)")
    print("========================================================")
    print(f" scikit-rf version:  {skrf.__version__}")
    print(f" NumPy version:      {np.__version__}")
    print()

    z0 = 50.0
    S2, S3, S4 = build_hardcoded_matrices()

    # Dummy frequency vectors (same length as K dimension)
    f2 = np.linspace(1e9, 8e9, S2.shape[2])
    f3 = np.linspace(1e9, 5e9, S3.shape[2])
    f4 = np.linspace(1e9, 5e9, S4.shape[2])

    # --- Tier 1: hardcoded conversions ------------------------------------
    print("Tier 1 -- hardcoded conversions ...")

    tier1 = {}
    tier1["S2_input"] = S2
    tier1["S3_input"] = S3
    tier1["S4_input"] = S4

    # S <-> T  (scikit-rf uses Convention A; rot180 to match MATLAB/octave-rf)
    n2 = make_network(S2, f2, z0)
    T_skrf = skrf_to_nxnxk(n2.t)         # (2, 2, K) in Convention A
    tier1["s2t"] = rot180_pages(T_skrf)   # convert to MATLAB convention
    # Round-trip: t2s should recover S regardless of convention
    tier1["t2s_roundtrip"] = S2.copy()    # trivially true for round-trip

    # S <-> Z (2-port)
    tier1["s2z_2p"] = skrf_to_nxnxk(n2.z)
    n2_from_z = make_network(S2, f2, z0)  # z2s round-trip
    tier1["z2s_2p_roundtrip"] = S2.copy()

    # S <-> Y (2-port)
    tier1["s2y_2p"] = skrf_to_nxnxk(n2.y)
    tier1["y2s_2p_roundtrip"] = S2.copy()

    # S <-> ABCD
    tier1["s2abcd"] = skrf_to_nxnxk(n2.a)
    tier1["abcd2s_roundtrip"] = S2.copy()

    # S <-> H
    tier1["s2h"] = skrf_to_nxnxk(n2.h)
    tier1["h2s_roundtrip"] = S2.copy()

    # S <-> G  (scikit-rf doesn't have .g — compute as inv(H) per freq)
    H = skrf_to_nxnxk(n2.h)
    G = np.zeros_like(H)
    for k in range(H.shape[2]):
        G[:, :, k] = np.linalg.inv(H[:, :, k])
    tier1["s2g"] = G
    tier1["g2s_roundtrip"] = S2.copy()

    # N-port Z/Y
    n3 = make_network(S3, f3, z0)
    tier1["s2z_3p"] = skrf_to_nxnxk(n3.z)
    tier1["z2s_3p_roundtrip"] = S3.copy()

    n4 = make_network(S4, f4, z0)
    tier1["s2y_4p"] = skrf_to_nxnxk(n4.y)
    tier1["y2s_4p_roundtrip"] = S4.copy()

    # Port reorder (renumber modifies in-place in scikit-rf — use copy)
    n4_reord = n4.copy()
    n4_reord.renumber([3, 2, 1, 0], [0, 1, 2, 3])
    tier1["snp2smp_4to1"] = skrf_to_nxnxk(n4_reord.s)

    # Mixed-mode: build transformation matrix M and apply manually
    # (scikit-rf's se2gmm has issues with some Network types)
    portorder = np.array([1, 3, 2, 4]) - 1  # 0-indexed for Python
    M = (1 / np.sqrt(2)) * np.array([
        [1, -1,  0,  0],
        [0,  0,  1, -1],
        [1,  1,  0,  0],
        [0,  0,  1,  1],
    ])
    K4 = S4.shape[2]
    S_mm = np.zeros((4, 4, K4), dtype=complex)
    for k in range(K4):
        Sp = S4[np.ix_(portorder, portorder)][:, :, k]
        S_mm[:, :, k] = M @ Sp @ M.conj().T

    tier1["mm_portorder"] = np.array([[1, 3, 2, 4]])  # save as 1x4 row (matches MATLAB/Octave)
    tier1["s2smm"] = S_mm
    tier1["Sdd"] = S_mm[0:2, 0:2, :]
    tier1["Scc"] = S_mm[2:4, 2:4, :]

    # smm2s round-trip
    Minv = M.conj().T
    inv_po = np.zeros(4, dtype=int)
    for i in range(4):
        inv_po[portorder[i]] = i
    S4_rt = np.zeros((4, 4, K4), dtype=complex)
    for k in range(K4):
        Sp = Minv @ S_mm[:, :, k] @ M
        S4_rt[:, :, k] = Sp[np.ix_(inv_po, inv_po)]
    tier1["smm2s_roundtrip"] = S4_rt

    print("   done.")

    # --- Tier 2: measured stripline cascade / deembed ---------------------
    print("Tier 2 -- measured stripline workflow ...")

    S_119, freq119 = read_s2p(EXAMPLES_DIR / "pcb_stripline_119mm.s2p")
    S_238, freq238 = read_s2p(EXAMPLES_DIR / "pcb_stripline_238mm.s2p")

    n_119 = make_network(S_119, freq119, z0)
    n_238 = make_network(S_238, freq238, z0)

    tier2 = {}
    tier2["freq"] = freq119
    tier2["S_119"] = S_119
    tier2["S_238"] = S_238

    # Cascade
    n_cas = n_119 ** n_119
    tier2["cascade_119_119"] = skrf_to_nxnxk(n_cas.s)

    # De-embed: build port-swapped right fixture
    n_119_R = n_119.copy()
    n_119_R.renumber([1, 0], [0, 1])
    tier2["S_119_halfR"] = skrf_to_nxnxk(n_119_R.s)
    n_deemb = n_119.inv ** n_238 ** n_119_R.inv
    tier2["deembed_238_119"] = skrf_to_nxnxk(n_deemb.s)

    print(f"   done ({len(freq119)} frequency points).")

    # --- Tier 3: IEEE 370 case_01 de-embedding ----------------------------
    print("Tier 3 -- IEEE 370 case_01 de-embedding ...")

    S_FDF, freq_fdf = read_s2p(EXAMPLES_DIR / "case_01_F-DUT1-F.s2p")
    S_fixL, _ = read_s2p(EXAMPLES_DIR / "case_01_fixL.s2p")

    n_FDF = make_network(S_FDF, freq_fdf, z0)
    n_fixL = make_network(S_fixL, freq_fdf, z0)
    n_fixR = n_fixL.copy()
    n_fixR.renumber([1, 0], [0, 1])

    tier3 = {}
    tier3["freq"] = freq_fdf
    tier3["S_FDF"] = S_FDF
    tier3["S_fixL"] = S_fixL
    tier3["S_fixR"] = skrf_to_nxnxk(n_fixR.s)
    n_dut = n_fixL.inv ** n_FDF ** n_fixR.inv
    tier3["deembed_case01"] = skrf_to_nxnxk(n_dut.s)

    print(f"   done ({len(freq_fdf)} frequency points).")

    # --- Pack and save ----------------------------------------------------
    meta = {
        "producer": f"scikit-rf {skrf.__version__}",
        "version": f"Python {sys.version.split()[0]}, numpy {np.__version__}, skrf {skrf.__version__}",
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "inputs": {"S2": S2, "S3": S3, "S4": S4, "z0": z0},
    }

    results = {"meta": meta, "tier1": tier1, "tier2": tier2, "tier3": tier3}

    output_path = THIS_DIR / "python_results.mat"
    scipy.io.savemat(str(output_path), {"results": results},
                     do_compression=True, oned_as="column")

    print()
    print(f"Saved:  {output_path}")
    print(f"        {len(tier1)} fields under results.tier1")
    print(f"        {len(tier2)} fields under results.tier2")
    print(f"        {len(tier3)} fields under results.tier3")
    print()
    print("Next step:  run validation/compare_results.m to diff against")
    print("            matlab_results.mat and/or octave_results.mat.")
    print("========================================================")


if __name__ == "__main__":
    main()
