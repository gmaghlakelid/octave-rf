%% validation/compare_results.m
%%
%% Load matlab_results.mat and octave_results.mat from the validation/
%% directory, diff them field-by-field, and write a dated Markdown report
%% to reports/VALIDATION_REPORT_YYYY-MM-DD.md.
%%
%% Portable: runs unmodified in either MATLAB or Octave.
%%
%% Usage:
%%   1. Produce matlab_results.mat  (validation/run_matlab.m  on MATLAB)
%%   2. Produce octave_results.mat  (validation/run_octave.m  on Octave)
%%   3. Place both files in validation/  and run this script.
%%
%% Tolerances (max absolute error, element-wise):
%%   Tier 1 (hardcoded conversions):      1e-13
%%   Tier 2 (measured stripline workflow): 1e-10
%%   Tier 3 (IEEE 370 case_01):            1e-10

this_dir = fileparts (mfilename ('fullpath'));
matlab_mat = fullfile (this_dir, 'matlab_results.mat');
octave_mat = fullfile (this_dir, 'octave_results.mat');

if ~exist (matlab_mat, 'file')
    error ('compare_results: %s not found.  Run validation/run_matlab.m first.', matlab_mat);
end
if ~exist (octave_mat, 'file')
    error ('compare_results: %s not found.  Run validation/run_octave.m first.', octave_mat);
end

ML = load (matlab_mat);
OC = load (octave_mat);

fprintf ('\n');
fprintf ('========================================================\n');
fprintf (' octave-rf  <-> MATLAB RF Toolbox  validation comparison\n');
fprintf ('========================================================\n');
fprintf ('  MATLAB produced by: %s  @ %s\n', ML.results.meta.producer, ML.results.meta.timestamp);
fprintf ('  Octave produced by: %s  @ %s\n', OC.results.meta.producer, OC.results.meta.timestamp);
fprintf ('\n');

%% Tolerances per tier.
tol = struct ('tier1', 1e-13, 'tier2', 1e-10, 'tier3', 1e-10);

%% Accumulate a results table: {name, max_abs, max_rel, tol, PASS/FAIL}.
rows = {};
n_pass = 0;
n_fail = 0;

tiers = {'tier1', 'tier2', 'tier3'};
tier_titles = {'Tier 1 - hardcoded conversions', ...
               'Tier 2 - measured stripline workflow', ...
               'Tier 3 - IEEE 370 case_01 de-embedding'};

for ti = 1:length (tiers)
    tname = tiers{ti};
    if ~isfield (ML.results, tname) || ~isfield (OC.results, tname)
        fprintf ('%s SKIPPED (missing from one side)\n', tier_titles{ti});
        continue;
    end
    fprintf ('%s\n', tier_titles{ti});
    fprintf ('--------------------------------------------------------\n');

    ML_t = ML.results.(tname);
    OC_t = OC.results.(tname);

    fn = union (fieldnames (ML_t), fieldnames (OC_t));

    for fi = 1:length (fn)
        name = fn{fi};
        full = sprintf ('%s.%s', tname, name);

        if ~isfield (ML_t, name) || ~isfield (OC_t, name)
            %% Field present on only one side - report and continue.
            fprintf ('  %-32s MISSING (ML:%d OC:%d)\n', full, ...
                     isfield (ML_t, name), isfield (OC_t, name));
            rows{end+1} = {full, NaN, NaN, tol.(tname), 'MISSING'};
            n_fail = n_fail + 1;
            continue;
        end

        A = ML_t.(name);
        B = OC_t.(name);

        %% Skip anything non-numeric (portorder integers, strings, etc.)
        if ischar (A) || iscell (A) || isstruct (A)
            fprintf ('  %-32s (skipped - non-numeric)\n', full);
            continue;
        end

        %% Normalise to same size, complex-safe
        if ~isequal (size (A), size (B))
            fprintf ('  %-32s SIZE MISMATCH (ML %s, OC %s)\n', full, ...
                     mat2str (size (A)), mat2str (size (B)));
            rows{end+1} = {full, NaN, NaN, tol.(tname), 'SIZE'};
            n_fail = n_fail + 1;
            continue;
        end

        diff_abs = abs (A(:) - B(:));
        max_abs  = max (diff_abs);
        denom    = max (abs (A(:)), abs (B(:)));
        denom(denom < eps) = eps;   % avoid 0/0 on all-zero references
        max_rel  = max (diff_abs ./ denom);

        passed = (max_abs <= tol.(tname));
        status = 'FAIL';
        if passed
            status = 'PASS';
            n_pass = n_pass + 1;
        else
            n_fail = n_fail + 1;
        end

        fprintf ('  %-32s max|d|=%.2e  max_rel=%.2e  %s\n', full, max_abs, max_rel, status);
        rows{end+1} = {full, max_abs, max_rel, tol.(tname), status};
    end
    fprintf ('\n');
end

fprintf ('--------------------------------------------------------\n');
fprintf ('SUMMARY: %d PASS, %d FAIL\n', n_pass, n_fail);
fprintf ('========================================================\n');

%% --- Write dated Markdown report ----------------------------------------
date_str = datestr (now, 'yyyy-mm-dd');
report_path = fullfile (this_dir, 'reports', ...
                        sprintf ('VALIDATION_REPORT_%s.md', date_str));

fid = fopen (report_path, 'w');
if fid < 0
    warning ('compare_results: could not open %s for writing', report_path);
else
    fprintf (fid, '# octave-rf <-> MATLAB RF Toolbox Validation Report\n\n');
    fprintf (fid, '**Date**: %s  \n', datestr (now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf (fid, '**MATLAB side**: %s (%s)  \n', ML.results.meta.producer, ML.results.meta.version);
    fprintf (fid, '**Octave side**: %s (%s)  \n', OC.results.meta.producer, OC.results.meta.version);
    fprintf (fid, '\n');
    fprintf (fid, '## Summary\n\n');
    fprintf (fid, '**%d PASS / %d FAIL** across %d comparisons.\n\n', ...
             n_pass, n_fail, length (rows));
    fprintf (fid, '## Tolerances\n\n');
    fprintf (fid, '| Tier | max\\|Δ\\| tolerance | Description |\n');
    fprintf (fid, '|---|---|---|\n');
    fprintf (fid, '| Tier 1 | %.0e | Hardcoded 2/3/4-port conversions and mixed-mode |\n', tol.tier1);
    fprintf (fid, '| Tier 2 | %.0e | Measured stripline cascade/de-embed (7000 freqs) |\n', tol.tier2);
    fprintf (fid, '| Tier 3 | %.0e | IEEE 370 case_01 de-embedding (2500 freqs) |\n', tol.tier3);
    fprintf (fid, '\n');
    fprintf (fid, '## Results\n\n');
    fprintf (fid, '| Test | max\\|Δ\\| | max relative | Tolerance | Status |\n');
    fprintf (fid, '|---|---|---|---|---|\n');
    for ri = 1:length (rows)
        r = rows{ri};
        if isnan (r{2})
            fprintf (fid, '| `%s` | n/a | n/a | %.0e | %s |\n', r{1}, r{4}, r{5});
        else
            fprintf (fid, '| `%s` | %.2e | %.2e | %.0e | %s |\n', ...
                     r{1}, r{2}, r{3}, r{4}, r{5});
        end
    end
    fprintf (fid, '\n');
    fprintf (fid, '## Reproduction\n\n');
    fprintf (fid, '```matlab\n');
    fprintf (fid, '%% On MATLAB (needs RF Toolbox):\n');
    fprintf (fid, 'cd D:\\Claude_work\\octave-rf\\validation\n');
    fprintf (fid, 'run_matlab\n');
    fprintf (fid, '```\n\n');
    fprintf (fid, '```octave\n');
    fprintf (fid, '%% On Octave (needs pkg rf installed or inst/ on path):\n');
    fprintf (fid, 'cd D:/Claude_work/octave-rf/validation\n');
    fprintf (fid, 'run_octave\n');
    fprintf (fid, '```\n\n');
    fprintf (fid, '```\n');
    fprintf (fid, '%% Portable (MATLAB or Octave):\n');
    fprintf (fid, 'compare_results\n');
    fprintf (fid, '```\n');
    fclose (fid);
    fprintf ('\nReport written to: %s\n', report_path);
end

%% Portable: MATLAB and Octave both accept fprintf(format, ...) to stdout.
%% No helper function needed.
