%% validation/run_octave.m
%%
%% Octave-side reference generator for the octave-rf vs. MATLAB RF Toolbox
%% numerical-parity validation (Phase V).
%%
%% Runs every tier-1/tier-2/tier-3 operation defined in validation/README.md
%% using the octave-rf package (inst/) and saves the outputs to
%% `octave_results.mat` (MATLAB v6 format, readable by both MATLAB and
%% Octave).
%%
%% Usage (from the octave-rf repo root or the validation/ directory):
%%
%%     cd D:/Claude_work/octave-rf/validation
%%     octave-cli --no-gui -q run_octave.m
%%
%% or inside an Octave session:
%%
%%     addpath('../inst');  addpath('../examples');
%%     run_octave
%%
%% The companion script validation/run_matlab.m writes
%% `matlab_results.mat` with the same field layout, and
%% validation/compare_results.m diffs the two.

%% --- Setup ----------------------------------------------------------------
this_dir = fileparts (mfilename ('fullpath'));
addpath (fullfile (this_dir, '..', 'inst'));      %% octave-rf functions
addpath (fullfile (this_dir, '..', 'examples'));  %% fromtouchn.m

%% fromtouchn.m in examples/ uses legacy syntax — silence those warnings only
%% during file reads.  Library-code warnings would still surface.
warning_state_orig = warning ('query', 'all');

examples_dir = fullfile (this_dir, '..', 'examples');

printf ('\n');
printf ('========================================================\n');
printf (' octave-rf  ->  Phase V validation (Octave side)\n');
printf ('========================================================\n');
printf (' Octave version:  %s\n', version ());
printf (' octave-rf path:  %s\n', fullfile (this_dir, '..', 'inst'));
printf ('\n');

%% --- Build hardcoded test matrices ---------------------------------------
%% Fixed, deterministic inputs shared verbatim with run_matlab.m.  Values
%% chosen so S21 is well away from 0 and (I - S) is non-singular at every
%% frequency — i.e., the conversions s2t / s2z / s2y / s2abcd / s2h / s2g
%% are all well-defined.

K2 = 8;
S2 = zeros (2, 2, K2);
for k = 1:K2
  phi = (k - 1) * 0.20;   %% deterministic phase advance
  S2(1,1,k) = 0.10 * exp (1j * phi)       + 0.02;
  S2(2,2,k) = 0.08 * exp (1j * (phi+0.3)) + 0.03;
  S2(2,1,k) = 0.85 * exp (-1j * phi);    %% |S21| = 0.85 (bounded away from 0)
  S2(1,2,k) = S2(2,1,k);                 %% reciprocal
endfor

K3 = 5;
S3 = zeros (3, 3, K3);
for k = 1:K3
  phi = (k - 1) * 0.25;
  a = 0.05 + 0.03*k;
  S3(:,:,k) = [  a*exp(1j*phi),     0.40*exp(-1j*phi),  0.10*exp(1j*0.1*k);
                 0.40*exp(-1j*phi),  a*exp(1j*(phi+0.2)), 0.20*exp(-1j*0.2*k);
                 0.10*exp(1j*0.1*k), 0.20*exp(-1j*0.2*k),  a*exp(1j*(phi+0.4)) ];
endfor

K4 = 5;
S4 = zeros (4, 4, K4);
for k = 1:K4
  phi = (k - 1) * 0.30;
  %% Dense, reciprocal, diagonally dominant single-ended 4-port.
  D   = 0.05 + 0.02*k;
  off = 0.15;
  S4(:,:,k) = D*exp(1j*phi) * eye(4) + off * ((ones(4) - eye(4)) .* exp(1j*phi*0.5));
  S4(:,:,k) = 0.5*(S4(:,:,k) + transpose (S4(:,:,k)));  %% enforce reciprocity
endfor

z0 = 50.0;

%% --- Tier 1: hardcoded conversions ---------------------------------------
printf ('Tier 1 -- hardcoded conversions ...\n');

tier1 = struct ();

%% S <-> T
tier1.S2_input         = S2;
tier1.s2t              = s2t (S2);
tier1.t2s_roundtrip    = t2s (tier1.s2t);

%% S <-> Z (2-port)
tier1.s2z_2p           = s2z (S2, z0);
tier1.z2s_2p_roundtrip = z2s (tier1.s2z_2p, z0);

%% S <-> Y (2-port)
tier1.s2y_2p           = s2y (S2, z0);
tier1.y2s_2p_roundtrip = y2s (tier1.s2y_2p, z0);

%% S <-> ABCD
tier1.s2abcd           = s2abcd (S2, z0);
tier1.abcd2s_roundtrip = abcd2s (tier1.s2abcd, z0);

%% S <-> H
tier1.s2h              = s2h (S2, z0);
tier1.h2s_roundtrip    = h2s (tier1.s2h, z0);

%% S <-> G
tier1.s2g              = s2g (S2, z0);
tier1.g2s_roundtrip    = g2s (tier1.s2g, z0);

%% N-port Z/Y
tier1.S3_input         = S3;
tier1.s2z_3p           = s2z (S3, z0);
tier1.z2s_3p_roundtrip = z2s (tier1.s2z_3p, z0);
tier1.S4_input         = S4;
tier1.s2y_4p           = s2y (S4, z0);
tier1.y2s_4p_roundtrip = y2s (tier1.s2y_4p, z0);

%% Port reorder
tier1.snp2smp_4to1     = snp2smp (S4, [4 3 2 1]);

%% Mixed-mode (4-port).  portorder = [D+1 D-1 D+2 D-2].
%% We use [1 3 2 4]: pair 1 = {1, 3}, pair 2 = {2, 4}.
portorder              = [1 3 2 4];
tier1.mm_portorder     = portorder;
tier1.s2smm            = s2smm (S4, portorder);
Sdd                    = tier1.s2smm(1:2, 1:2, :);
Sdc                    = tier1.s2smm(1:2, 3:4, :);
Scd                    = tier1.s2smm(3:4, 1:2, :);
Scc                    = tier1.s2smm(3:4, 3:4, :);
tier1.Sdd              = Sdd;
tier1.Scc              = Scc;
tier1.smm2s_roundtrip  = smm2s (Sdd, Sdc, Scd, Scc, portorder);

printf ('   done.\n');

%% --- Tier 2: measured stripline cascade / deembed ------------------------
printf ('Tier 2 -- measured stripline workflow ...\n');

warning ('off', 'all');
[freq119, S_119, z0_119] = fromtouchn (fullfile (examples_dir, 'pcb_stripline_119mm.s2p'));
[freq238, S_238, z0_238] = fromtouchn (fullfile (examples_dir, 'pcb_stripline_238mm.s2p'));
warning (warning_state_orig);

if (numel (freq119) != numel (freq238))
  error ('run_octave: pcb_stripline 119mm and 238mm files have different frequency counts (%d vs %d) — cannot compare on a common grid', numel (freq119), numel (freq238));
end
if (max (abs (freq119 - freq238)) > 1e-3)
  error ('run_octave: pcb_stripline files have different frequency grids (max diff %.3g Hz)', max (abs (freq119 - freq238)));
end

tier2 = struct ();
tier2.freq              = freq119(:);
tier2.S_119             = S_119;
tier2.S_238             = S_238;

%% Cascade two 119mm halves.
tier2.cascade_119_119   = cascadesparams (S_119, S_119);

%% De-embed: given the measured 238mm trace, remove 119mm on the left and
%% a port-swapped 119mm on the right.  For a symmetric reciprocal 2xthru
%% this is equivalent to removing "half and half".
S_119_halfL             = S_119;
S_119_halfR             = snp2smp (S_119, [2 1]);
tier2.S_119_halfR       = S_119_halfR;
tier2.deembed_238_119   = deembedsparams (S_238, S_119_halfL, S_119_halfR);

printf ('   done (%d frequency points).\n', numel (freq119));

%% --- Tier 3: IEEE 370 case_01 de-embedding -------------------------------
printf ('Tier 3 -- IEEE 370 case_01 de-embedding ...\n');

warning ('off', 'all');
[freq_fdf, S_FDF,  z0_fdf]  = fromtouchn (fullfile (examples_dir, 'case_01_F-DUT1-F.s2p'));
[freq_fxl, S_fixL, z0_fxl]  = fromtouchn (fullfile (examples_dir, 'case_01_fixL.s2p'));
warning (warning_state_orig);

if (numel (freq_fdf) != numel (freq_fxl))
  error ('run_octave: case_01 F-DUT-F and fixL files have different frequency counts');
end

tier3 = struct ();
tier3.freq              = freq_fdf(:);
tier3.S_FDF             = S_FDF;
tier3.S_fixL            = S_fixL;
tier3.S_fixR            = snp2smp (S_fixL, [2 1]);
tier3.deembed_case01    = deembedsparams (S_FDF, tier3.S_fixL, tier3.S_fixR);

printf ('   done (%d frequency points).\n', numel (freq_fdf));

%% --- Pack and save -------------------------------------------------------
results = struct ();
results.meta.producer   = 'octave-rf';
results.meta.version    = version ();
results.meta.timestamp  = datestr (now, 'yyyy-mm-dd HH:MM:SS');
results.meta.inputs.S2  = S2;
results.meta.inputs.S3  = S3;
results.meta.inputs.S4  = S4;
results.meta.inputs.z0  = z0;
results.tier1           = tier1;
results.tier2           = tier2;
results.tier3           = tier3;

output_path = fullfile (this_dir, 'octave_results.mat');
save ('-v6', output_path, 'results');

printf ('\n');
printf ('Saved:  %s\n', output_path);
printf ('        %d fields under results.tier1\n', numel (fieldnames (tier1)));
printf ('        %d fields under results.tier2\n', numel (fieldnames (tier2)));
printf ('        %d fields under results.tier3\n', numel (fieldnames (tier3)));
printf ('\n');
printf ('Next step:  run validation/run_matlab.m on a MATLAB machine, then\n');
printf ('            validation/compare_results.m to diff the two .mat files.\n');
printf ('========================================================\n');
