function out = run_single_case()
%RUN_SINGLE_CASE Quick check for one kinetic AP run and one macro run.
% Data are saved in <project_root>/data/single_case.
% Figures are saved in <project_root>/post/figures.
this_file = mfilename('fullpath');
runs_dir  = fileparts(this_file);
root_dir  = fileparts(runs_dir);
run(fullfile(root_dir, 'startup_AP_bacteria.m'));

data_dir = fullfile(root_dir, 'data', 'single_case');
fig_dir  = fullfile(root_dir, 'post', 'figures');
snapshot_dir = fullfile(data_dir, 'snapshots');
utils.make_dir(data_dir);
utils.make_dir(fig_dir);
utils.make_dir(snapshot_dir);

p = model.default_params();
p.Tfinal = 20;
p.output_times = 0:1:p.Tfinal;       % store every integer time, including t=0
p.dt = 1e-2;
p.dx = 0.1;
p.eps = 1e-2;
p.verbose = true;
p.report_dt = 1;
p.save_snapshots_to_disk = true;
p.snapshot_dir = snapshot_dir;
p.save_g_snapshots = true;           % single case is small enough to keep g

macro = src.run_model(p, 'macro');
kin   = src.run_model(p, 'kinetic');

mat_file = fullfile(data_dir, 'single_case.mat');
fig_file = fullfile(fig_dir, 'single_case_profiles.png');
save(mat_file, 'p', 'macro', 'kin', 'snapshot_dir', '-v7.3');
post.plot_profiles(macro, kin, fig_file);

fprintf('macro speed %.6g, kinetic speed %.6g\n', macro.speed, kin.speed);
fprintf('Saved data: %s\n', mat_file);
fprintf('Saved snapshots in: %s\n', snapshot_dir);
fprintf('Saved figure: %s\n', fig_file);

if nargout > 0
    out = struct('p', p, 'macro', macro, 'kin', kin, ...
        'data_dir', data_dir, 'fig_dir', fig_dir, 'snapshot_dir', snapshot_dir, ...
        'mat_file', mat_file, 'fig_file', fig_file);
end
end
