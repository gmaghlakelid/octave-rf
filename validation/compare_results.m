%% validation/compare_results.m
%%
%% Load matlab_results.mat, octave_results.mat, and (optionally)
%% python_results.mat from the validation/ directory, diff them
%% pair-wise, and write a dated Markdown report.
%%
%% Portable: runs unmodified in either MATLAB or Octave.
%%
%% Usage:
%%   1. Produce matlab_results.mat   (validation/run_matlab.m on MATLAB)
%%   2. Produce octave_results.mat   (validation/run_octave.m on Octave)
%%   3. (Optional) produce python_results.mat  (validation/run_python.py
%%                 with scikit-rf installed)
%%   4. Run this script from validation/.
%%
%% Tolerance rule: PASS if  max|delta| <= tol_abs  OR  max_rel <= tol_rel.
%% Per-tier tolerances:
%%   Tier 1 (hardcoded conversions):        abs 1e-12,  rel 1e-12
%%   Tier 2 (measured stripline workflow):  abs 1e-10,  rel 1e-9
%%   Tier 3 (IEEE 370 case_01):             abs 1e-10,  rel 1e-9
%%
%% MATLAB s2t/t2s convention (documented in the report): MATLAB RF Toolbox
%% uses Pupalaikis Convention B  ((a1,b1)^T = T * (b2,a2)^T, cascade =
%% T_R*T_L).  octave-rf and scikit-rf use Convention A  ((b1,a1)^T = T *
%% (a2,b2)^T, cascade = T_L*T_R).  The two T matrices are related by
%% rot180 (both rows and columns reversed).  The comparison applies this
%% adjustment when one side is MATLAB so the numerical diff reflects the
%% underlying math rather than the element ordering.

this_dir   = fileparts (mfilename ('fullpath'));
matlab_mat = fullfile (this_dir, 'matlab_results.mat');
octave_mat = fullfile (this_dir, 'octave_results.mat');
python_mat = fullfile (this_dir, 'python_results.mat');

have_matlab = exist (matlab_mat, 'file') == 2;
have_octave = exist (octave_mat, 'file') == 2;
have_python = exist (python_mat, 'file') == 2;

if ~have_octave
    error ('compare_results: octave_results.mat is required.  Run run_octave first.');
end
if ~have_matlab && ~have_python
    error ('compare_results: need matlab_results.mat and/or python_results.mat to compare against.');
end

%% Load everything we have.
OC = load (octave_mat);
sides = struct ('octave', OC.results);
if have_matlab
    ML = load (matlab_mat);
    sides.matlab = ML.results;
end
if have_python
    PY = load (python_mat);
    sides.python = PY.results;
end

fprintf ('\n');
fprintf ('========================================================\n');
fprintf (' octave-rf Phase V validation comparison\n');
fprintf ('========================================================\n');
if have_matlab
    fprintf ('  MATLAB: %s  @ %s\n', ML.results.meta.producer, ML.results.meta.timestamp);
end
fprintf ('  Octave: %s  @ %s\n', OC.results.meta.producer, OC.results.meta.timestamp);
if have_python
    fprintf ('  Python: %s  @ %s\n', PY.results.meta.producer, PY.results.meta.timestamp);
end
fprintf ('\n');

%% Build the list of pair comparisons we will run.
pairs = {};
if have_matlab
    pairs{end+1} = {'matlab', 'octave', 'MATLAB vs Octave'};
end
if have_python
    pairs{end+1} = {'python', 'octave', 'Python vs Octave'};
end
if have_matlab && have_python
    pairs{end+1} = {'matlab', 'python', 'MATLAB vs Python'};
end

%% Tolerances.
tol_abs = struct ('tier1', 1e-12, 'tier2', 1e-10, 'tier3', 1e-10);
tol_rel = struct ('tier1', 1e-12, 'tier2', 1e-9,  'tier3', 1e-9);

tiers = {'tier1', 'tier2', 'tier3'};
tier_titles = {'Tier 1 - hardcoded conversions', ...
               'Tier 2 - measured stripline workflow', ...
               'Tier 3 - IEEE 370 case_01 de-embedding'};

%% All rows for the Markdown report, across all pairs.
all_report_rows = {};   % each row: {pair_label, tier, field, max_abs, max_rel, tol_abs, tol_rel, status, note}
total_pass = 0;
total_fail = 0;

for pi = 1:length (pairs)
    p        = pairs{pi};
    A_name   = p{1};
    B_name   = p{2};
    label    = p{3};
    A_res    = sides.(A_name);
    B_res    = sides.(B_name);

    fprintf ('####  %s  ####\n', label);
    fprintf ('--------------------------------------------------------\n');

    for ti = 1:length (tiers)
        tname = tiers{ti};
        if ~isfield (A_res, tname) || ~isfield (B_res, tname)
            continue;
        end
        fprintf ('%s\n', tier_titles{ti});

        A_t = A_res.(tname);
        B_t = B_res.(tname);
        fn  = union (fieldnames (A_t), fieldnames (B_t));

        for fi = 1:length (fn)
            name = fn{fi};
            full = sprintf ('%s.%s', tname, name);

            if ~isfield (A_t, name) || ~isfield (B_t, name)
                fprintf ('  %-32s MISSING (%s:%d %s:%d)\n', full, ...
                         A_name, isfield(A_t, name), B_name, isfield(B_t, name));
                all_report_rows{end+1} = {label, tname, full, NaN, NaN, ...
                                          tol_abs.(tname), tol_rel.(tname), ...
                                          'MISSING', ''};
                total_fail = total_fail + 1;
                continue;
            end

            A = A_t.(name);
            B = B_t.(name);

            if ischar (A) || iscell (A) || isstruct (A)
                continue;   % skip non-numeric
            end

            if ~isequal (size (A), size (B))
                fprintf ('  %-32s SIZE MISMATCH %s vs %s\n', full, ...
                         mat2str (size (A)), mat2str (size (B)));
                all_report_rows{end+1} = {label, tname, full, NaN, NaN, ...
                                          tol_abs.(tname), tol_rel.(tname), ...
                                          'SIZE', ''};
                total_fail = total_fail + 1;
                continue;
            end

            %% Apply MATLAB convention-B -> A adjustment for s2t / t2s.
            %% (MATLAB RF Toolbox outputs a rot180-flipped T matrix compared
            %% to Pupalaikis Convention A, which octave-rf and scikit-rf use.)
            note = '';
            %% No convention adjustment needed: octave-rf s2t/t2s now uses
            %% the same element ordering as MATLAB RF Toolbox.

            diff_v = A(:) - B(:);
            max_abs = max (abs (diff_v));

            denom = max (abs (A(:)), abs (B(:)));
            denom(denom < eps) = eps;
            max_rel = max (abs (diff_v) ./ denom);

            tol_a = tol_abs.(tname);
            tol_r = tol_rel.(tname);
            passed = (max_abs <= tol_a) || (max_rel <= tol_r);
            if passed
                status = 'PASS';
                total_pass = total_pass + 1;
            else
                status = 'FAIL';
                total_fail = total_fail + 1;
            end

            if isempty (note)
                fprintf ('  %-32s max|d|=%.2e  rel=%.2e  %s\n', ...
                         full, max_abs, max_rel, status);
            else
                fprintf ('  %-32s max|d|=%.2e  rel=%.2e  %s  (%s)\n', ...
                         full, max_abs, max_rel, status, note);
            end

            all_report_rows{end+1} = {label, tname, full, max_abs, max_rel, ...
                                      tol_a, tol_r, status, note};
        end
        fprintf ('\n');
    end
    fprintf ('\n');
end

fprintf ('--------------------------------------------------------\n');
fprintf ('GRAND TOTAL: %d PASS, %d FAIL\n', total_pass, total_fail);
fprintf ('========================================================\n');

%% --- Write dated Markdown report ---------------------------------------
date_str = datestr (now, 'yyyy-mm-dd');
report_path = fullfile (this_dir, 'reports', ...
                        sprintf ('VALIDATION_REPORT_%s.md', date_str));
fid = fopen (report_path, 'w');
if fid < 0
    warning ('compare_results: could not open %s for writing', report_path);
else
    fprintf (fid, '# octave-rf Phase V Validation Report\n\n');
    fprintf (fid, '**Date**: %s  \n', datestr (now, 'yyyy-mm-dd HH:MM:SS'));
    if have_matlab
        fprintf (fid, '**MATLAB**: %s (%s)  \n', ML.results.meta.producer, ML.results.meta.version);
    end
    fprintf (fid, '**Octave**: %s (%s)  \n', OC.results.meta.producer, OC.results.meta.version);
    if have_python
        fprintf (fid, '**Python**: %s (%s)  \n', PY.results.meta.producer, PY.results.meta.version);
    end
    fprintf (fid, '\n');
    fprintf (fid, '## Summary\n\n');
    fprintf (fid, '**%d PASS / %d FAIL** across %d pair-wise comparisons.\n\n', ...
             total_pass, total_fail, length (all_report_rows));
    fprintf (fid, '## Tolerance rule\n\n');
    fprintf (fid, 'A field PASSES if either `max|delta| <= tol_abs` OR `max_rel <= tol_rel`.\n\n');
    fprintf (fid, '| Tier | tol_abs | tol_rel | Description |\n');
    fprintf (fid, '|---|---|---|---|\n');
    fprintf (fid, '| Tier 1 | %.0e | %.0e | Hardcoded 2/3/4-port conversions and mixed-mode |\n', tol_abs.tier1, tol_rel.tier1);
    fprintf (fid, '| Tier 2 | %.0e | %.0e | Measured stripline cascade/de-embed (7000 freqs) |\n', tol_abs.tier2, tol_rel.tier2);
    fprintf (fid, '| Tier 3 | %.0e | %.0e | IEEE 370 case_01 de-embedding (2500 freqs) |\n', tol_abs.tier3, tol_rel.tier3);
    fprintf (fid, '\n');
    fprintf (fid, '## Convention note\n\n');
    fprintf (fid, '`octave-rf` uses the same T-parameter element ordering as MATLAB RF\n');
    fprintf (fid, 'Toolbox (Pupalaikis convention compatible with MATLAB), so `s2t` / `t2s`\n');
    fprintf (fid, 'output is directly comparable without any element reordering.\n\n');
    fprintf (fid, '## Results\n\n');
    fprintf (fid, '| Pair | Tier | Field | max\\|Δ\\| | max_rel | tol_abs | tol_rel | Status | Note |\n');
    fprintf (fid, '|---|---|---|---|---|---|---|---|---|\n');
    for ri = 1:length (all_report_rows)
        r = all_report_rows{ri};
        if isnan (r{4})
            fprintf (fid, '| %s | %s | `%s` | n/a | n/a | %.0e | %.0e | %s | %s |\n', ...
                     r{1}, r{2}, r{3}, r{6}, r{7}, r{8}, r{9});
        else
            fprintf (fid, '| %s | %s | `%s` | %.2e | %.2e | %.0e | %.0e | %s | %s |\n', ...
                     r{1}, r{2}, r{3}, r{4}, r{5}, r{6}, r{7}, r{8}, r{9});
        end
    end
    fprintf (fid, '\n');
    fprintf (fid, '## Reproduction\n\n');
    fprintf (fid, '```matlab\n%% On MATLAB (needs RF Toolbox):\ncd D:\\Claude_work\\octave-rf\\validation\nrun_matlab\n```\n\n');
    fprintf (fid, '```octave\n%% On Octave (needs pkg rf installed or inst/ on path):\ncd D:/Claude_work/octave-rf/validation\nrun_octave\n```\n\n');
    fprintf (fid, '```bash\n# On any machine with scikit-rf (optional third reference):\ncd D:/Claude_work/octave-rf/validation\npython run_python.py\n```\n\n');
    fprintf (fid, '```\n%% Portable (MATLAB or Octave):\ncompare_results\n```\n');
    fclose (fid);
    fprintf ('\nReport written to: %s\n', report_path);
end

%% Helper: apply rot180 to every page of a 3-D array.  (rot90(X, 2) is the
%% MATLAB/Octave spelling of 180-degree rotation.)
function Y = rot180_pages (X)
    Y = zeros (size (X), 'like', X);
    for k = 1:size (X, 3)
        Y(:, :, k) = rot90 (X(:, :, k), 2);
    end
end
