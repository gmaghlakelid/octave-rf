%% validation/run_matlab.m
%%
%% MATLAB-side reference generator for the octave-rf vs. MATLAB RF Toolbox
%% numerical-parity validation (Phase V).
%%
%% Runs every tier-1/tier-2/tier-3 operation defined in validation/README.md
%% using the MATLAB RF Toolbox and saves the outputs to
%% `matlab_results.mat` (MATLAB v6 format).
%%
%% Requires:
%%   - MATLAB R2020b or newer
%%   - RF Toolbox (for sparameters, s2t, t2s, s2z, ..., cascadesparams,
%%     deembedsparams, snp2smp, s2smm, smm2s)
%%
%% Usage (from a MATLAB session on Windows):
%%
%%     cd D:\Claude_work\octave-rf\validation
%%     run_matlab
%%
%% Produces:
%%     matlab_results.mat  -- companion to octave_results.mat
%%
%% Then run validation\compare_results.m (portable, runs in MATLAB or
%% Octave) to diff the two.

%% --- Setup ----------------------------------------------------------------
this_dir     = fileparts(mfilename('fullpath'));
examples_dir = fullfile(this_dir, '..', 'examples');

fprintf('\n');
fprintf('========================================================\n');
fprintf(' MATLAB RF Toolbox  ->  Phase V validation (MATLAB side)\n');
fprintf('========================================================\n');
fprintf(' MATLAB version:  %s\n', version());
fprintf(' RF Toolbox:      %s\n', matlab_toolbox_version('RF'));
fprintf('\n');

%% --- Build the SAME hardcoded test matrices as run_octave.m --------------
%% Must match exactly — the bit patterns are what we compare.

K2 = 8;
S2 = zeros(2, 2, K2);
for k = 1:K2
    phi = (k - 1) * 0.20;
    S2(1,1,k) = 0.10 * exp(1j*phi)       + 0.02;
    S2(2,2,k) = 0.08 * exp(1j*(phi+0.3)) + 0.03;
    S2(2,1,k) = 0.85 * exp(-1j*phi);
    S2(1,2,k) = S2(2,1,k);
end

K3 = 5;
S3 = zeros(3, 3, K3);
for k = 1:K3
    phi = (k - 1) * 0.25;
    a = 0.05 + 0.03*k;
    S3(:,:,k) = [  a*exp(1j*phi),      0.40*exp(-1j*phi),  0.10*exp(1j*0.1*k);
                   0.40*exp(-1j*phi),  a*exp(1j*(phi+0.2)), 0.20*exp(-1j*0.2*k);
                   0.10*exp(1j*0.1*k), 0.20*exp(-1j*0.2*k),  a*exp(1j*(phi+0.4)) ];
end

K4 = 5;
S4 = zeros(4, 4, K4);
for k = 1:K4
    phi = (k - 1) * 0.30;
    D   = 0.05 + 0.02*k;
    off = 0.15;
    S4(:,:,k) = D*exp(1j*phi) * eye(4) + off * ((ones(4) - eye(4)) .* exp(1j*phi*0.5));
    S4(:,:,k) = 0.5*(S4(:,:,k) + transpose(S4(:,:,k)));
end

z0 = 50.0;

%% --- Tier 1: hardcoded conversions ---------------------------------------
fprintf('Tier 1 -- hardcoded conversions ...\n');

tier1 = struct();

%% S <-> T
tier1.S2_input         = S2;
tier1.s2t              = s2t(S2);
tier1.t2s_roundtrip    = t2s(tier1.s2t);

%% S <-> Z (2-port)
tier1.s2z_2p           = s2z(S2, z0);
tier1.z2s_2p_roundtrip = z2s(tier1.s2z_2p, z0);

%% S <-> Y (2-port)
tier1.s2y_2p           = s2y(S2, z0);
tier1.y2s_2p_roundtrip = y2s(tier1.s2y_2p, z0);

%% S <-> ABCD
tier1.s2abcd           = s2abcd(S2, z0);
tier1.abcd2s_roundtrip = abcd2s(tier1.s2abcd, z0);

%% S <-> H
tier1.s2h              = s2h(S2, z0);
tier1.h2s_roundtrip    = h2s(tier1.s2h, z0);

%% S <-> G.  MATLAB RF Toolbox does NOT currently expose s2g / g2s.  We
%% compute them via the same H-inverse route used by octave-rf so the
%% reference can still be produced and compared.
tier1.s2g              = local_s2g(S2, z0);
tier1.g2s_roundtrip    = local_g2s(tier1.s2g, z0);

%% N-port Z/Y
tier1.S3_input         = S3;
tier1.s2z_3p           = s2z(S3, z0);
tier1.z2s_3p_roundtrip = z2s(tier1.s2z_3p, z0);
tier1.S4_input         = S4;
tier1.s2y_4p           = s2y(S4, z0);
tier1.y2s_4p_roundtrip = y2s(tier1.s2y_4p, z0);

%% Port reorder.  MATLAB's snp2smp takes (s_params, z0, newports, termz).
%% For a pure port-reorder at z0=50 with matched terminations, the result
%% is the same row/column permutation that octave-rf implements.
tier1.snp2smp_4to1     = snp2smp(S4, z0, [4 3 2 1], z0);

%% Mixed-mode (4-port).  portorder convention: octave-rf uses numeric
%% [D+1 D-1 D+2 D-2].  MATLAB RF Toolbox's s2smm uses integer port grouping
%% 1 (for [1 3 2 4] style pairs).  Here we match octave-rf's [1 3 2 4]:
%% pair 1 = ports {1, 3}, pair 2 = ports {2, 4}.  MATLAB's corresponding
%% call is s2smm(s, 2) with ports pre-reordered, OR s2smm(s) with
%% 'sdd11', 'sdd21', ... outputs.  We use the numeric block form for
%% direct array comparison.
portorder              = [1 3 2 4];
tier1.mm_portorder     = portorder;

%% Reorder ports to [D+1, D-1, D+2, D-2] before applying MATLAB's s2smm.
S4_reord               = snp2smp(S4, z0, portorder, z0);
%% MATLAB's s2smm with option 1 uses the differential/common mode transform
%% M = (1/sqrt(2)) * [1 -1 0 0; 0 0 1 -1; 1 1 0 0; 0 0 1 1] (matches octave-rf).
[sdd, sdc, scd, scc]   = s2smm(S4_reord);
% Re-pack as a 4x4xK matrix with block ordering [Sdd Sdc; Scd Scc]
% (rows/cols: [d1 d2 c1 c2]) — same convention as octave-rf's s2smm output.
K = size(S4, 3);
S_mm = zeros(4, 4, K);
S_mm(1:2, 1:2, :) = sdd;
S_mm(1:2, 3:4, :) = sdc;
S_mm(3:4, 1:2, :) = scd;
S_mm(3:4, 3:4, :) = scc;
tier1.s2smm            = S_mm;
tier1.Sdd              = sdd;
tier1.Scc              = scc;

%% smm2s round-trip.  MATLAB's smm2s takes (sdd, sdc, scd, scc) and returns
%% a 4-port sparameters matrix with ports in [D+1 D-1 D+2 D-2] order; we
%% then invert the port reorder to recover the original [1 2 3 4] order.
S4_reord_rt            = smm2s(sdd, sdc, scd, scc);
inv_po = zeros(1, 4);
for i = 1:4
    inv_po(portorder(i)) = i;
end
S4_rt = zeros(4, 4, K);
for k = 1:K
    S4_rt(:, :, k) = S4_reord_rt(inv_po, inv_po, k);
end
tier1.smm2s_roundtrip  = S4_rt;

fprintf('   done.\n');

%% --- Tier 2: measured stripline cascade / deembed ------------------------
fprintf('Tier 2 -- measured stripline workflow ...\n');

%% MATLAB's sparameters(filename) handles Touchstone natively.
sp119 = sparameters(fullfile(examples_dir, 'pcb_stripline_119mm.s2p'));
sp238 = sparameters(fullfile(examples_dir, 'pcb_stripline_238mm.s2p'));

freq119 = sp119.Frequencies;
freq238 = sp238.Frequencies;
S_119 = sp119.Parameters;
S_238 = sp238.Parameters;

if (numel(freq119) ~= numel(freq238))
    error('run_matlab: pcb_stripline 119mm and 238mm files have different frequency counts');
end

tier2 = struct();
tier2.freq              = freq119(:);
tier2.S_119             = S_119;
tier2.S_238             = S_238;

%% Cascade two 119mm halves.  MATLAB's cascadesparams takes sparameters
%% objects and returns an sparameters object — extract .Parameters for the
%% raw-array comparison.
sp_cascade              = cascadesparams(sp119, sp119);
tier2.cascade_119_119   = sp_cascade.Parameters;

%% De-embed.  Construct port-swapped right fixture.  MATLAB's snp2smp at
%% z0=50 with matched terminations realises pure port reorder.
S_119_halfR             = snp2smp(S_119, z0, [2 1], z0);
sp_fixL                 = sparameters(S_119,       freq119, z0);
sp_fixR                 = sparameters(S_119_halfR, freq119, z0);
tier2.S_119_halfR       = S_119_halfR;
sp_deembed              = deembedsparams(sp238, sp_fixL, sp_fixR);
tier2.deembed_238_119   = sp_deembed.Parameters;

fprintf('   done (%d frequency points).\n', numel(freq119));

%% --- Tier 3: IEEE 370 case_01 de-embedding -------------------------------
fprintf('Tier 3 -- IEEE 370 case_01 de-embedding ...\n');

sp_FDF   = sparameters(fullfile(examples_dir, 'case_01_F-DUT1-F.s2p'));
sp_fixL3 = sparameters(fullfile(examples_dir, 'case_01_fixL.s2p'));

freq_fdf = sp_FDF.Frequencies;
S_FDF    = sp_FDF.Parameters;
S_fixL   = sp_fixL3.Parameters;

tier3 = struct();
tier3.freq              = freq_fdf(:);
tier3.S_FDF             = S_FDF;
tier3.S_fixL            = S_fixL;
tier3.S_fixR            = snp2smp(S_fixL, z0, [2 1], z0);

sp_fixR3                = sparameters(tier3.S_fixR, freq_fdf, z0);
sp_dut                  = deembedsparams(sp_FDF, sp_fixL3, sp_fixR3);
tier3.deembed_case01    = sp_dut.Parameters;

fprintf('   done (%d frequency points).\n', numel(freq_fdf));

%% --- Pack and save -------------------------------------------------------
results = struct();
results.meta.producer   = 'MATLAB RF Toolbox';
results.meta.version    = version();
results.meta.timestamp  = datestr(now, 'yyyy-mm-dd HH:MM:SS');
results.meta.inputs.S2  = S2;
results.meta.inputs.S3  = S3;
results.meta.inputs.S4  = S4;
results.meta.inputs.z0  = z0;
results.tier1           = tier1;
results.tier2           = tier2;
results.tier3           = tier3;

%% Two outputs:
%%   1. matlab_results.mat       -- canonical name read by compare_results.m
%%   2. matlab_results_<REL>.mat -- release-stamped archive so multiple
%%                                   MATLAB versions can coexist in the dir
%%                                   (e.g., matlab_results_R2020b.mat and
%%                                   matlab_results_R2025a.mat side-by-side).
canonical_path = fullfile(this_dir, 'matlab_results.mat');
save(canonical_path, 'results', '-v6');

release_tag = regexprep(version('-release'), '[^A-Za-z0-9]', '');
stamped_path = fullfile(this_dir, sprintf('matlab_results_%s.mat', release_tag));
save(stamped_path, 'results', '-v6');

fprintf('\n');
fprintf('Saved:  %s\n', canonical_path);
fprintf('        %s\n', stamped_path);
fprintf('        %d fields under results.tier1\n', numel(fieldnames(tier1)));
fprintf('        %d fields under results.tier2\n', numel(fieldnames(tier2)));
fprintf('        %d fields under results.tier3\n', numel(fieldnames(tier3)));
fprintf('\n');
fprintf('Next step:  copy this .mat to the machine with octave_results.mat,\n');
fprintf('            then run validation/compare_results.m to diff them.\n');
fprintf('            To compare a different MATLAB release, rename the\n');
fprintf('            corresponding matlab_results_<REL>.mat to\n');
fprintf('            matlab_results.mat before running compare_results.\n');
fprintf('========================================================\n');


%% -------------------------------------------------------------------------
%% Local helpers: MATLAB RF Toolbox does not currently expose s2g / g2s.
%% We compute them via the H-inverse route used by octave-rf (s2g.m line 54+,
%% g2s.m).  These helpers keep run_matlab.m self-contained.
%% -------------------------------------------------------------------------
function G = local_s2g(S, z0)
    K = size(S, 3);
    H = s2h(S, z0);
    G = zeros(2, 2, K);
    for k = 1:K
        h11 = H(1,1,k); h12 = H(1,2,k);
        h21 = H(2,1,k); h22 = H(2,2,k);
        d = h11*h22 - h12*h21;
        if d == 0
            error('local_s2g: det(H) is zero at frequency index %d', k);
        end
        G(1,1,k) =  h22 / d;
        G(1,2,k) = -h12 / d;
        G(2,1,k) = -h21 / d;
        G(2,2,k) =  h11 / d;
    end
end

function S = local_g2s(G, z0)
    K = size(G, 3);
    H = zeros(2, 2, K);
    for k = 1:K
        g11 = G(1,1,k); g12 = G(1,2,k);
        g21 = G(2,1,k); g22 = G(2,2,k);
        d = g11*g22 - g12*g21;
        if d == 0
            error('local_g2s: det(G) is zero at frequency index %d', k);
        end
        H(1,1,k) =  g22 / d;
        H(1,2,k) = -g12 / d;
        H(2,1,k) = -g21 / d;
        H(2,2,k) =  g11 / d;
    end
    S = h2s(H, z0);
end

function v = matlab_toolbox_version(short_name)
    %% Best-effort toolbox version lookup; returns '(n/a)' if not found.
    v = '(n/a)';
    try
        vers = ver();
        for i = 1:numel(vers)
            if contains(vers(i).Name, 'RF Toolbox') || strcmp(short_name, 'RF')
                if contains(vers(i).Name, 'RF')
                    v = sprintf('%s (%s)', vers(i).Version, vers(i).Release);
                    return;
                end
            end
        end
    catch
    end
end
