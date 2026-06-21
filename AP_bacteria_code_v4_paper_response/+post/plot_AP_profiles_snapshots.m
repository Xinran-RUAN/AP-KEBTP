function plot_AP_profiles_snapshots(macro, kins, eps_list, filename)
%PLOT_AP_PROFILES_SNAPSHOTS Compare rho profiles at selected output times.
filename = utils.resolve_project_path(filename);
utils.make_dir(fileparts(filename));

selected_times = [1 10 20 50];
fig_dir = fileparts(filename);

% Create one EPS file per selected time, matching the names used in the paper.
for q = 1:numel(selected_times)
    tt = selected_times(q);
    km = local_find_time(macro.snap, tt);
    if isempty(km), continue; end
    fig = figure('Color','w','Position',[100 100 520 400]); hold on;
    for m = 1:numel(kins)
        kk = local_find_time(kins{m}.snap, tt);
        if ~isempty(kk)
            plot(kins{m}.grid.x, kins{m}.snap(kk).rho, 'LineWidth', 1.5);
        end
    end
    plot(macro.grid.x, macro.snap(km).rho, 'k--', 'LineWidth', 2);
    leg = arrayfun(@(e) sprintf('$\\varepsilon=%g$', e), eps_list, 'UniformOutput', false);
    leg{end+1} = 'macro';
    xlabel('$x$','Interpreter','latex');
    ylabel('$\rho(x)$','Interpreter','latex');
    title(sprintf('$T=%g$', tt), 'Interpreter','latex');
    legend(leg,'Interpreter','latex','Location','best');
    set(gca,'FontSize',14,'LineWidth',1.1); box on;
    saveas(fig, fullfile(fig_dir, sprintf('T_%g.eps', tt)), 'epsc');
    close(fig);
end

% Also create a combined figure for quick inspection.
nT = numel(selected_times);
fig = figure('Color','w','Position',[100 100 900 650]);
for q = 1:nT
    tt = selected_times(q);
    km = local_find_time(macro.snap, tt);
    if isempty(km), continue; end
    subplot(2,2,q); hold on;
    for m = 1:numel(kins)
        kk = local_find_time(kins{m}.snap, tt);
        if ~isempty(kk)
            plot(kins{m}.grid.x, kins{m}.snap(kk).rho, 'LineWidth', 1.2);
        end
    end
    plot(macro.grid.x, macro.snap(km).rho, 'k--', 'LineWidth', 1.8);
    xlabel('$x$','Interpreter','latex');
    ylabel('$\rho(x)$','Interpreter','latex');
    title(sprintf('$T=%g$', tt), 'Interpreter','latex');
    set(gca,'FontSize',12,'LineWidth',1.0); box on;
    if q == 1
        leg = arrayfun(@(e) sprintf('$\\varepsilon=%g$', e), eps_list, 'UniformOutput', false);
        leg{end+1} = 'macro';
        legend(leg,'Interpreter','latex','Location','best');
    end
end
saveas(fig, filename);
close(fig);
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
