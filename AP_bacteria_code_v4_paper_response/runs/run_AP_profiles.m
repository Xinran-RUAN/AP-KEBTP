function summary = run_AP_profiles()
%RUN_AP_PROFILES AP profile and L2 error tests for eps -> 0.
%
% This driver produces the following outputs under the project root:
%   data/AP_profiles/AP_profiles.mat
%   data/AP_profiles/AP_profiles_partial.mat
%   data/AP_profiles/AP_error_summary.csv
%   data/AP_profiles/AP_error_by_time.csv
%   data/AP_profiles/AP_relative_error_by_time.csv
%   data/AP_profiles/snapshots/*.mat
%   post/figures/AP_profiles_final.png
%   post/figures/AP_profiles_snapshots.png
%   post/figures/AP_error_final.png
%   post/figures/AP_error_by_time.png
%   post/figures/AP_speed_time.png
%
% If called with an output argument, it also returns a summary struct.
this_file = mfilename('fullpath');
runs_dir  = fileparts(this_file);
root_dir  = fileparts(runs_dir);
run(fullfile(root_dir, 'startup_AP_bacteria.m'));

data_dir = fullfile(root_dir, 'data', 'AP_profiles');
fig_dir  = fullfile(root_dir, 'post', 'figures');
snapshot_dir = fullfile(data_dir, 'snapshots');
utils.make_dir(data_dir);
utils.make_dir(fig_dir);
utils.make_dir(snapshot_dir);

p = model.default_params();
p.Tfinal = 30;
p.output_times = 0:1e-1:p.Tfinal;      % save snapshots every one time unit
p.dt = 1e-3;
p.dx = 0.1;
p.verbose = true;                  % print progress in the Command Window
p.report_dt = 1;                   % print diagnostics every one time unit
p.save_snapshots_to_disk = true;   % save one .mat file at each output time
p.snapshot_dir = snapshot_dir;
p.save_g_snapshots = false;        % keep snapshot files compact for eps scan

% eps_list = [1e-1, 5e-2, 2e-2, 1e-2, 5e-3, 2e-3, 1e-3]; % snapshot dt = 1
eps_list = [1e-1, 5e-2, 1e-2]; % snapshot dt = 1e-1
partial_file = fullfile(data_dir, 'AP_profiles_partial.mat');

fprintf('Running macroscopic limiting model\n');
macro = src.run_model(p, 'macro');

kins = cell(size(eps_list));
err_final = zeros(size(eps_list));
relerr_final = zeros(size(eps_list));
speeds = zeros(size(eps_list));

nT = numel(macro.snap);
snap_times = zeros(1, nT);
for k = 1:nT
    snap_times(k) = macro.snap(k).t;
end
err_snap = nan(numel(eps_list), nT);
relerr_snap = nan(numel(eps_list), nT);

rho_ref_norm_final = sqrt(macro.grid.dx * sum(macro.U.rho.^2));
for m = 1:numel(eps_list)
    pp = p;
    pp.eps = eps_list(m);
    fprintf('Running kinetic model with eps = %g\n', pp.eps);
    kins{m} = src.run_model(pp, 'kinetic');

    err_final(m) = src.l2_error(kins{m}.U.rho, macro.U.rho, macro.grid);
    relerr_final(m) = err_final(m) / max(rho_ref_norm_final, eps);
    speeds(m) = kins{m}.speed;

    nk = min(numel(kins{m}.snap), nT);
    for k = 1:nk
        err_snap(m,k) = src.l2_error(kins{m}.snap(k).rho, macro.snap(k).rho, macro.grid);
        rho_ref_norm = sqrt(macro.grid.dx * sum(macro.snap(k).rho.^2));
        relerr_snap(m,k) = err_snap(m,k) / max(rho_ref_norm, eps);
    end

    % Save progress after each epsilon so long runs still leave usable data.
    save(partial_file, 'p', 'eps_list', 'macro', 'kins', 'err_final', ...
        'relerr_final', 'err_snap', 'relerr_snap', 'speeds', 'snap_times', ...
        'snapshot_dir', '-v7.3');
end

macro_speed = macro.speed;

% Diagnostic tables.
Tfinal = table(eps_list(:), err_final(:), relerr_final(:), speeds(:), ...
    repmat(macro_speed, numel(eps_list), 1), abs(speeds(:) - macro_speed), ...
    'VariableNames', {'eps', 'L2_error_final', 'relative_L2_error_final', ...
    'speed_kinetic', 'speed_macro', 'speed_difference'});

Ttime = array2table([eps_list(:), err_snap], ...
    'VariableNames', [{'eps'}, local_time_varnames(snap_times)]);
TtimeRel = array2table([eps_list(:), relerr_snap], ...
    'VariableNames', [{'eps'}, local_time_varnames(snap_times)]);

writetable(Tfinal, fullfile(data_dir, 'AP_error_summary.csv'));
writetable(Ttime, fullfile(data_dir, 'AP_error_by_time.csv'));
writetable(TtimeRel, fullfile(data_dir, 'AP_relative_error_by_time.csv'));

fprintf('\nFinal-time AP error and speed summary:\n');
disp(Tfinal);

summary = struct();
summary.p = p;
summary.eps_list = eps_list;
summary.snap_times = snap_times;
summary.err_final = err_final;
summary.relerr_final = relerr_final;
summary.err_snap = err_snap;
summary.relerr_snap = relerr_snap;
summary.speeds = speeds;
summary.macro_speed = macro_speed;
summary.final_table = Tfinal;
summary.error_by_time_table = Ttime;
summary.relative_error_by_time_table = TtimeRel;
summary.data_dir = data_dir;
summary.fig_dir = fig_dir;
summary.snapshot_dir = snapshot_dir;
summary.partial_file = partial_file;

mat_file = fullfile(data_dir, 'AP_profiles.mat');
save(mat_file, 'p', 'eps_list', 'macro', 'kins', ...
    'err_final', 'relerr_final', 'err_snap', 'relerr_snap', 'speeds', ...
    'macro_speed', 'snap_times', 'Tfinal', 'Ttime', 'TtimeRel', 'summary', '-v7.3');

post.plot_AP_profiles(macro, kins, eps_list, fullfile(fig_dir, 'AP_profiles_final.png'));
post.plot_AP_profiles_snapshots(macro, kins, eps_list, fullfile(fig_dir, 'AP_profiles_snapshots.png'));
post.plot_AP_error(eps_list, err_final, fullfile(fig_dir, 'AP_error_final.png'));
post.plot_AP_error_by_time(eps_list, err_snap, snap_times, fullfile(fig_dir, 'AP_error_by_time.png'));
post.plot_speed_time(macro, kins, eps_list, fullfile(fig_dir, 'AP_speed_time.png'));

fprintf('Saved data: %s\n', mat_file);
fprintf('Saved partial data: %s\n', partial_file);
fprintf('Saved snapshots in: %s\n', snapshot_dir);
fprintf('Saved figures in: %s\n', fig_dir);
end

function names = local_time_varnames(times)
names = cell(1, numel(times));
for k = 1:numel(times)
    s = sprintf('t_%g', times(k));
    s = strrep(s, '.', 'p');
    s = strrep(s, '-', 'm');
    names{k} = matlab.lang.makeValidName(s);
end
end
