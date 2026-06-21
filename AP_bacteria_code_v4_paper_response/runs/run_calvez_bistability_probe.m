function out = run_calvez_bistability_probe()
%RUN_CALVEZ_BISTABILITY_PROBE Optional and exploratory only.
% This does NOT reproduce the full well-balanced bistability study. It only provides
% a starting point with the four-velocity grid used in Calvez--Gosse--Twarogowska.
% Data are saved in <project_root>/data/calvez_probe.
this_file = mfilename('fullpath');
runs_dir  = fileparts(this_file);
root_dir  = fileparts(runs_dir);
run(fullfile(root_dir, 'startup_AP_bacteria.m'));

data_dir = fullfile(root_dir, 'data', 'calvez_probe');
fig_dir  = fullfile(root_dir, 'post', 'figures');
snapshot_dir = fullfile(data_dir, 'snapshots');
utils.make_dir(data_dir);
utils.make_dir(fig_dir);
utils.make_dir(snapshot_dir);

p = model.default_params();
p.velocity_mode = 'four';
p.dx = 0.05;
p.dt = 5e-3;
p.Tfinal = 30;
p.output_times = 0:5:p.Tfinal;
p.chiS = 0.48;
p.chiN = 0.44;
p.DS = 0.5;
p.alpha = 40;
p.DN = 1;
p.beta = 1;
p.gamma = 1;
p.N0 = 400;
p.eps = 1;
p.verbose = true;
p.report_dt = 5;
p.save_snapshots_to_disk = true;
p.snapshot_dir = snapshot_dir;
p.save_g_snapshots = true;

kin = src.run_model(p, 'kinetic');

mat_file = fullfile(data_dir, 'calvez_probe.mat');
fig_file = fullfile(fig_dir, 'calvez_probe_profiles.png');
save(mat_file, 'p', 'kin', 'snapshot_dir', '-v7.3');
post.plot_profiles([], kin, fig_file);

fprintf('Saved data: %s\n', mat_file);
fprintf('Saved snapshots in: %s\n', snapshot_dir);
fprintf('Saved figure: %s\n', fig_file);

if nargout > 0
    out = struct('p', p, 'kin', kin, ...
        'data_dir', data_dir, 'fig_dir', fig_dir, 'snapshot_dir', snapshot_dir, ...
        'mat_file', mat_file, 'fig_file', fig_file);
end
end
