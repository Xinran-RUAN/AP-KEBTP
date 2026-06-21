function compare = plot_macro_travelling_wave(macro, p, fig_dir)
%PLOT_MACRO_TRAVELLING_WAVE Create profiles.eps and compare_profile.eps.
% The comparison figure uses the analytical profile in the travelling
% coordinate z=x-x_peak.  The plotted analytical curve is mass-normalized,
% as in the manuscript; a peak-normalized version is also returned for
% diagnostics.

fig_dir = utils.resolve_project_path(fig_dir);
utils.make_dir(fig_dir);

% Figure 1(a): profiles at T=20,60,100.
fig = figure('Color','w','Position',[100 100 560 420]); hold on;
times_wanted = [20 60 100];
for q = 1:numel(times_wanted)
    k = local_find_time(macro.snap, times_wanted(q));
    if ~isempty(k)
        plot(macro.grid.x, macro.snap(k).rho, 'LineWidth', 1.6, ...
            'DisplayName', sprintf('$T=%g$', times_wanted(q)));
    end
end
xlabel('$x$','Interpreter','latex'); ylabel('$\rho$','Interpreter','latex');
legend('Interpreter','latex','Location','best');
set(gca,'FontSize',14,'LineWidth',1.1); box on;
saveas(fig, fullfile(fig_dir, 'profiles.eps'), 'epsc');
saveas(fig, fullfile(fig_dir, 'profiles.png'));
close(fig);

% Figure 1(b): numerical profile at T=100 vs analytical profile.
k = local_find_time(macro.snap, 100);
if isempty(k), k = numel(macro.snap); end
x = macro.grid.x;
rho = macro.snap(k).rho;
[~,ip] = max(rho);
xp = x(ip);

[rho_an_mass, info_mass] = src.analytic_profile_macro(macro.grid, rho, p, xp, 'mass');
[rho_an_peak, info_peak] = src.analytic_profile_macro(macro.grid, rho, p, xp, 'peak');

fig = figure('Color','w','Position',[100 100 560 420]); hold on;
plot(x, rho, 'LineWidth', 1.8, 'DisplayName','Numerical');
plot(x, rho_an_mass, '--', 'LineWidth', 1.8, 'DisplayName','Analytical');
xlim([max(0,xp-15), min(max(x),xp+25)]);
xlabel('$x$','Interpreter','latex'); ylabel('$\rho$','Interpreter','latex');
legend('Interpreter','latex','Location','best');
set(gca,'FontSize',14,'LineWidth',1.1); box on;
saveas(fig, fullfile(fig_dir, 'compare_profile.eps'), 'epsc');
saveas(fig, fullfile(fig_dir, 'compare_profile.png'));
close(fig);

compare = struct();
compare.t = macro.snap(k).t;
compare.x = x;
compare.rho_numeric = rho;
compare.rho_analytical = rho_an_mass;
compare.rho_analytical_mass = rho_an_mass;
compare.rho_analytical_peak = rho_an_peak;
compare.info_mass = info_mass;
compare.info_peak = info_peak;
compare.x_peak = xp;
end

function idx = local_find_time(snap, tt)
idx = [];
if isempty(snap), return; end
times = arrayfun(@(s) s.t, snap);
[err,k] = min(abs(times-tt));
if err < 1e-8 || err < 0.55
    idx = k;
end
end
