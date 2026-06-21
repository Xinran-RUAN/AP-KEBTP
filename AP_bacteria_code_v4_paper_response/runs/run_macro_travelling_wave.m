function out = run_macro_travelling_wave()
%RUN_MACRO_TRAVELLING_WAVE Generate macroscopic travelling pulse figures.
% Data are saved in <project_root>/data/macro_travelling_wave.

this_file = mfilename('fullpath');
runs_dir  = fileparts(this_file);
root_dir  = fileparts(runs_dir);
run(fullfile(root_dir, 'startup_AP_bacteria.m'));

fig_dir  = fullfile(root_dir, 'post', 'figures');
data_dir = fullfile(root_dir, 'data', 'macro_travelling_wave');
snapshot_dir = fullfile(data_dir, 'snapshots');
utils.make_dir(fig_dir);
utils.make_dir(data_dir);
utils.make_dir(snapshot_dir);

p = model.default_params();
p.Tfinal = 100;
p.output_times = 0:1:p.Tfinal;       % save all integer-time profiles
p.dt = 1e-3;
p.dx = 0.01;
p.verbose = true;
p.report_dt = 10;
p.save_snapshots_to_disk = true;
p.snapshot_dir = snapshot_dir;
p.save_g_snapshots = false;

% Paper comparison: limiting macro response, normalized sign response.
p.response_eps = 0;
p.phi_type = 'sign';
p.normalize_phi_amplitude = true;

% Quick parameter diagnostic before the long run.
grid0 = model.make_grid(p);
[chiS_eff, chiN_eff, chi_info] = src.effective_chi_macro(p, grid0);
sigma_pred = src.analytic_speed_macro(chiS_eff, chiN_eff, p.DS, p.alpha);
fprintf('Macro settings: response_eps=%g, phi_type=%s, phi_scale_total=%.6g\n', ...
    p.response_eps, p.phi_type, chi_info.phi_scale_total);
fprintf('Effective chi: chiS=%.6g, chiN=%.6g, predicted sigma=%.6g\n', ...
    chiS_eff, chiN_eff, sigma_pred);
U0 = model.initial_data(grid0, p);
fprintf('Initial mass approximately %.6g\n', grid0.dx*sum(U0.rho));

macro = src.run_model(p, 'macro');
compare = post.plot_macro_travelling_wave(macro, p, fig_dir);

mat_file = fullfile(data_dir, 'macro_travelling_wave.mat');
compare_file = fullfile(data_dir, 'compare_profile_data.csv');
Tcompare = table(compare.x(:), compare.rho_numeric(:), ...
    compare.rho_analytical_mass(:), compare.rho_analytical_peak(:), ...
    'VariableNames', {'x', 'rho_numeric', 'rho_analytical_mass', 'rho_analytical_peak'});
writetable(Tcompare, compare_file);
save(mat_file, 'p', 'macro', 'compare', 'snapshot_dir', 'Tcompare', ...
    'chiS_eff', 'chiN_eff', 'sigma_pred', '-v7.3');

fprintf('Saved data: %s\n', mat_file);
fprintf('Saved comparison table: %s\n', compare_file);
fprintf('Saved snapshots in: %s\n', snapshot_dir);
fprintf('Saved figures in: %s\n', fig_dir);

if nargout > 0
    out = struct('p', p, 'macro', macro, 'compare', compare, ...
        'data_dir', data_dir, 'fig_dir', fig_dir, 'snapshot_dir', snapshot_dir, ...
        'mat_file', mat_file, 'compare_file', compare_file, ...
        'chiS_eff', chiS_eff, 'chiN_eff', chiN_eff, 'sigma_pred', sigma_pred);
end
end
