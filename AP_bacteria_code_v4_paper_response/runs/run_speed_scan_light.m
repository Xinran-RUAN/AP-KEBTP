function out = run_speed_scan_light()
%RUN_SPEED_SCAN_LIGHT Light parameter scan for wave speed.
% This is intentionally modest. Increase chi lists only after single case is stable.
% Data are saved in <project_root>/data/speed_scan.
this_file = mfilename('fullpath');
runs_dir  = fileparts(this_file);
root_dir  = fileparts(runs_dir);
run(fullfile(root_dir, 'startup_AP_bacteria.m'));

data_dir = fullfile(root_dir, 'data', 'speed_scan');
fig_dir  = fullfile(root_dir, 'post', 'figures');
snapshot_dir = fullfile(data_dir, 'snapshots');
utils.make_dir(data_dir);
utils.make_dir(fig_dir);
utils.make_dir(snapshot_dir);

p0 = model.default_params();
p0.Tfinal = 40;
p0.output_times = 0:5:p0.Tfinal;    % save intermediate profiles in the scan
p0.dt = 1e-2;
p0.dx = 0.2;
p0.dv = 0.04;
p0.eps = 1e-2;
p0.verbose = false;
p0.report_dt = 5;
p0.save_snapshots_to_disk = true;
p0.snapshot_dir = snapshot_dir;
p0.save_g_snapshots = false;        % compact scan snapshots: rho, S, N only

chiN_list = 0:0.25:2;
chiS_list = 0:0.25:2;
S_macro = nan(numel(chiN_list), numel(chiS_list));
S_kin = nan(size(S_macro));
S_pred = nan(size(S_macro));
partial_file = fullfile(data_dir, 'speed_scan_light_partial.mat');

for i = 1:numel(chiN_list)
    for j = 1:numel(chiS_list)
        p = p0;
        p.chiN = chiN_list(i);
        p.chiS = chiS_list(j);
        p.snapshot_tag = ['chiN_' utils.num_to_tag(p.chiN) '_chiS_' utils.num_to_tag(p.chiS)];
        fprintf('scan chiN=%.2f chiS=%.2f\n', p.chiN, p.chiS);
        grid_pred = model.make_grid(p);
        [chiS_eff, chiN_eff] = src.effective_chi_macro(p, grid_pred);
        S_pred(i,j) = src.analytic_speed_macro(chiS_eff, chiN_eff, p.DS, p.alpha);
        macro = src.run_model(p, 'macro');
        S_macro(i,j) = macro.speed;
        kin = src.run_model(p, 'kinetic');
        S_kin(i,j) = kin.speed;

        % Save progress after every parameter pair.
        save(partial_file, 'p0', 'chiN_list', 'chiS_list', ...
            'S_pred', 'S_macro', 'S_kin', 'snapshot_dir');
    end
end

mat_file = fullfile(data_dir, 'speed_scan_light.mat');
fig_file = fullfile(fig_dir, 'speed_scan_light.png');
save(mat_file, 'p0', 'chiN_list', 'chiS_list', 'S_pred', 'S_macro', 'S_kin', 'snapshot_dir');
post.plot_speed_scan(chiN_list, chiS_list, S_pred, S_macro, S_kin, fig_file);

fprintf('Saved data: %s\n', mat_file);
fprintf('Saved partial data: %s\n', partial_file);
fprintf('Saved snapshots in: %s\n', snapshot_dir);
fprintf('Saved figure: %s\n', fig_file);

if nargout > 0
    out = struct('p0', p0, 'chiN_list', chiN_list, 'chiS_list', chiS_list, ...
        'S_pred', S_pred, 'S_macro', S_macro, 'S_kin', S_kin, ...
        'data_dir', data_dir, 'fig_dir', fig_dir, 'snapshot_dir', snapshot_dir, ...
        'mat_file', mat_file, 'partial_file', partial_file, 'fig_file', fig_file);
end
end
