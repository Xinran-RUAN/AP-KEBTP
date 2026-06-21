function plot_AP_profiles_paper()
%PLOT_AP_PROFILES_PAPER  Paper-style post-processing for run_AP_profiles.
%
% This script reads
%   data/AP_profiles/AP_profiles.mat
% and generates
%   post/figures/AP_profiles_paper.pdf/png
%   post/figures/AP_error_paper.pdf/png
%   post/figures/AP_speed_paper.pdf/png
%
% It does not modify run_AP_profiles.m and does not use the saved variable
% named Tfinal.

clear; clc; close all;

root_dir = find_project_root();
data_file = fullfile(root_dir, 'data', 'AP_profiles', 'AP_profiles.mat');
fig_dir   = fullfile(root_dir, 'post', 'figures');

if ~exist(data_file, 'file')
    error('Data file not found:\n%s\nPlease run run_AP_profiles first.', data_file);
end
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

S = load(data_file);
need = {'macro','kins','eps_list'};
for q = 1:numel(need)
    if ~isfield(S, need{q})
        error('Missing variable "%s" in AP_profiles.mat.', need{q});
    end
end

macro = S.macro;
kins = S.kins;
eps_list = S.eps_list(:).';

if isfield(S, 'snap_times') && ~isempty(S.snap_times)
    snap_times = S.snap_times(:).';
else
    snap_times = get_snap_times(macro.snap, []);
end

if isfield(S, 'err_snap') && ~isempty(S.err_snap)
    err_snap = S.err_snap;
else
    err_snap = compute_error_by_time(macro, kins);
end

if isfield(S, 'err_final') && ~isempty(S.err_final)
    err_final = S.err_final(:).';
else
    err_final = compute_error_final(macro, kins);
end

x = get_grid_x(macro);
dx = get_grid_dx(macro, x);

plot_profile_snapshots(x, macro, kins, eps_list, snap_times, fig_dir);
plot_error_figures(eps_list, err_snap, err_final, snap_times, fig_dir);
plot_speed_figure(x, dx, macro, kins, eps_list, snap_times, fig_dir);

fprintf('\nPaper-style AP figures saved in:\n%s\n', fig_dir);

end


function root_dir = find_project_root()
this_file = mfilename('fullpath');
this_dir = fileparts(this_file);

cands = {this_dir, fileparts(this_dir), fileparts(fileparts(this_dir))};
for k = 1:numel(cands)
    cand = cands{k};
    if isempty(cand), continue; end
    if exist(fullfile(cand, 'data'), 'dir') || exist(fullfile(cand, 'startup_AP_bacteria.m'), 'file')
        root_dir = cand;
        return;
    end
end
root_dir = fileparts(this_dir);
end


function x = get_grid_x(macro)
if ~isfield(macro, 'grid')
    error('macro.grid does not exist.');
end

g = macro.grid;
if isfield(g, 'x')
    x = g.x(:);
elseif isfield(g, 'xc')
    x = g.xc(:);
elseif isfield(g, 'xr')
    x = g.xr(:);
elseif isfield(g, 'xrho')
    x = g.xrho(:);
else
    if isfield(macro, 'U') && isfield(macro.U, 'rho')
        Nx = numel(macro.U.rho);
    elseif isfield(macro, 'snap') && ~isempty(macro.snap)
        Nx = numel(macro.snap(1).rho);
    else
        error('Cannot infer grid size.');
    end

    if ~isfield(g, 'dx')
        error('Cannot infer x because macro.grid.dx is missing.');
    end
    x = ((0:Nx-1)' + 0.5) * g.dx;
end
end


function dx = get_grid_dx(macro, x)
if isfield(macro, 'grid') && isfield(macro.grid, 'dx')
    dx = macro.grid.dx;
elseif numel(x) >= 2
    dx = mean(diff(x));
else
    error('Cannot determine dx.');
end
end


function times = get_snap_times(snaps, fallback)
if isempty(snaps)
    times = fallback;
    return;
end

times = nan(1, numel(snaps));
for k = 1:numel(snaps)
    if isfield(snaps(k), 't')
        times(k) = snaps(k).t;
    elseif ~isempty(fallback) && numel(fallback) >= k
        times(k) = fallback(k);
    else
        times(k) = k - 1;
    end
end
end


function err_snap = compute_error_by_time(macro, kins)
nEps = numel(kins);
nT = numel(macro.snap);
err_snap = nan(nEps, nT);

x = get_grid_x(macro);
dx = get_grid_dx(macro, x);

for m = 1:nEps
    nk = min(numel(kins{m}.snap), nT);
    for k = 1:nk
        rho_k = kins{m}.snap(k).rho(:);
        rho_m = macro.snap(k).rho(:);
        err_snap(m,k) = sqrt(dx * sum((rho_k - rho_m).^2));
    end
end
end


function err_final = compute_error_final(macro, kins)
nEps = numel(kins);
err_final = nan(1, nEps);

x = get_grid_x(macro);
dx = get_grid_dx(macro, x);
rho_m = macro.U.rho(:);

for m = 1:nEps
    rho_k = kins{m}.U.rho(:);
    err_final(m) = sqrt(dx * sum((rho_k - rho_m).^2));
end
end


function plot_profile_snapshots(x, macro, kins, eps_list, snap_times, fig_dir)
want_times = [1, 10, 20, 50];
plot_times = want_times(want_times >= min(snap_times) & want_times <= max(snap_times));

if isempty(plot_times)
    idx = round(linspace(1, numel(snap_times), 4));
    idx = unique(max(1, min(numel(snap_times), idx)));
else
    idx = zeros(size(plot_times));
    for q = 1:numel(plot_times)
        [~, idx(q)] = min(abs(snap_times - plot_times(q)));
    end
end

figure('Color','w','Position',[100 100 920 650]);
line_styles = {'-', '--', '-.', ':'};

for q = 1:numel(idx)
    subplot(2, 2, q); hold on; box on;
    idt = idx(q);

    for m = 1:numel(eps_list)
        if numel(kins{m}.snap) < idt
            continue;
        end
        plot(x, kins{m}.snap(idt).rho(:), ...
            'LineStyle', line_styles{mod(m-1, numel(line_styles))+1}, ...
            'LineWidth', 1.5, ...
            'DisplayName', sprintf('$\\varepsilon=%g$', eps_list(m)));
    end

    plot(x, macro.snap(idt).rho(:), 'k-', ...
        'LineWidth', 1.9, ...
        'DisplayName', 'macro');

    xlabel('$x$', 'Interpreter','latex');
    ylabel('$\rho(x,t)$', 'Interpreter','latex');
    title(sprintf('(%c) $T=%g$', char('a'+q-1), snap_times(idt)), ...
        'Interpreter','latex', 'FontWeight','normal');

    set(gca, 'FontSize',11, 'LineWidth',0.9, 'TickLabelInterpreter','latex');
    grid on;

    if q == 1
        legend('Interpreter','latex', 'Location','northeast', 'Box','off');
    end
end

for q = numel(idx)+1:4
    subplot(2,2,q); axis off;
end

export_figure(gcf, fullfile(fig_dir, 'AP_profiles_paper'));
end


function plot_error_figures(eps_list, err_snap, err_final, snap_times, fig_dir)
figure('Color','w','Position',[100 100 960 380]);
line_styles = {'-', '--', '-.', ':'};

subplot(1,2,1); hold on; box on;
for m = 1:numel(eps_list)
    semilogy(snap_times, err_snap(m,:), ...
        'LineStyle', line_styles{mod(m-1,numel(line_styles))+1}, ...
        'LineWidth', 1.5, ...
        'DisplayName', sprintf('$\\varepsilon=%g$', eps_list(m)));
end
xlabel('$t$', 'Interpreter','latex');
ylabel('$E_\varepsilon(t)$', 'Interpreter','latex');
title('(a) Error history', 'Interpreter','latex', 'FontWeight','normal');
set(gca, 'FontSize',11, 'LineWidth',0.9, 'TickLabelInterpreter','latex');
legend('Interpreter','latex', 'Location','best', 'Box','off');
grid on;

subplot(1,2,2); hold on; box on;
eps_col = eps_list(:);
E_col = err_final(:);
valid = isfinite(eps_col) & eps_col > 0 & isfinite(E_col) & E_col > 0;
eps_col = eps_col(valid);
E_col = E_col(valid);
[eps_col, order] = sort(eps_col);
E_col = E_col(order);

loglog(eps_col, E_col, 'o-', ...
    'LineWidth', 1.6, ...
    'MarkerSize', 6, ...
    'DisplayName', 'numerical error');

if numel(eps_col) >= 2
    pp = polyfit(log(eps_col), log(E_col), 1);
    rate = pp(1);
    Cref = E_col(end) / eps_col(end)^rate;
    loglog(eps_col, Cref * eps_col.^rate, 'k--', ...
        'LineWidth', 1.3, ...
        'DisplayName', sprintf('slope %.2f', rate));
end

xlabel('$\varepsilon$', 'Interpreter','latex');
ylabel('$E_\varepsilon(T)$', 'Interpreter','latex');
title('(b) Final-time convergence', 'Interpreter','latex', 'FontWeight','normal');
set(gca, 'FontSize',11, 'LineWidth',0.9, 'TickLabelInterpreter','latex');
legend('Interpreter','latex', 'Location','best', 'Box','off');
grid on;

export_figure(gcf, fullfile(fig_dir, 'AP_error_paper'));
end


function plot_speed_figure(x, dx, macro, kins, eps_list, snap_times, fig_dir)
xmass_macro = compute_center_of_mass_history(x, dx, macro.snap);
speed_macro = finite_diff_speed(snap_times(:), xmass_macro(:));

figure('Color','w','Position',[100 100 560 400]); hold on; box on;
plot(snap_times, speed_macro, 'k-', 'LineWidth',1.9, 'DisplayName','macro');

line_styles = {'-', '--', '-.', ':'};
for m = 1:numel(eps_list)
    this_times = get_snap_times(kins{m}.snap, snap_times);
    xmass_kin = compute_center_of_mass_history(x, dx, kins{m}.snap);
    speed_kin = finite_diff_speed(this_times(:), xmass_kin(:));

    plot(this_times, speed_kin, ...
        'LineStyle', line_styles{mod(m-1,numel(line_styles))+1}, ...
        'LineWidth', 1.5, ...
        'DisplayName', sprintf('$\\varepsilon=%g$', eps_list(m)));
end

xlabel('$t$', 'Interpreter','latex');
ylabel('wave speed', 'Interpreter','latex');
title('Wave speed history', 'Interpreter','latex', 'FontWeight','normal');
set(gca, 'FontSize',11, 'LineWidth',0.9, 'TickLabelInterpreter','latex');
legend('Interpreter','latex', 'Location','best', 'Box','off');
grid on;

export_figure(gcf, fullfile(fig_dir, 'AP_speed_paper'));
end


function xmass = compute_center_of_mass_history(x, dx, snaps)
xmass = nan(1, numel(snaps));
for k = 1:numel(snaps)
    rho = snaps(k).rho(:);
    mass = dx * sum(rho);
    if mass > 0 && isfinite(mass)
        xmass(k) = dx * sum(x(:) .* rho) / mass;
    end
end
end


function speed = finite_diff_speed(t, xmass)
t = t(:);
xmass = xmass(:);
n = numel(t);
speed = nan(n, 1);

if n == 1
    return;
elseif n == 2
    speed(:) = (xmass(2)-xmass(1))/(t(2)-t(1));
    return;
end

speed(1) = (xmass(2)-xmass(1))/(t(2)-t(1));
speed(end) = (xmass(end)-xmass(end-1))/(t(end)-t(end-1));
for k = 2:n-1
    speed(k) = (xmass(k+1)-xmass(k-1))/(t(k+1)-t(k-1));
end
end


function export_figure(fig_handle, basename)
try
    exportgraphics(fig_handle, [basename, '.pdf'], 'ContentType','vector');
catch
    warning('exportgraphics for PDF failed. Falling back to saveas.');
    saveas(fig_handle, [basename, '.pdf']);
end

try
    exportgraphics(fig_handle, [basename, '.png'], 'Resolution',300);
catch
    warning('exportgraphics for PNG failed. Falling back to saveas.');
    saveas(fig_handle, [basename, '.png']);
end
end
