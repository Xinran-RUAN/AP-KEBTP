function plot_AP_error_by_time(eps_list, err_snap, snap_times, filename)
%PLOT_AP_ERROR_BY_TIME Plot AP errors for all saved output times.
filename = utils.resolve_project_path(filename);
utils.make_dir(fileparts(filename));

figure('Color','w'); hold on;
leg = cell(1, numel(snap_times));
for k = 1:numel(snap_times)
    loglog(eps_list, err_snap(:,k), 'o-', 'LineWidth', 2, 'MarkerSize', 7);
    leg{k} = sprintf('$t=%.4g$', snap_times(k));
end
xlabel('$\varepsilon$','Interpreter','latex');
ylabel('$\|\rho^\varepsilon-\rho\|_2$','Interpreter','latex');
legend(leg,'Interpreter','latex','Location','best');
set(gca,'FontSize',16,'LineWidth',1.2); grid on; box on;
saveas(gcf, filename);
end
