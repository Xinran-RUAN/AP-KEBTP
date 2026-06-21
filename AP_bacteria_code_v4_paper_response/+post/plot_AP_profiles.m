function plot_AP_profiles(macro, kins, eps_list, filename)
filename = utils.resolve_project_path(filename);
utils.make_dir(fileparts(filename));
figure('Color','w'); hold on;
plot(macro.grid.x, macro.U.rho, 'k--', 'LineWidth', 2);
leg = {'macro'};
for m = 1:numel(kins)
    plot(kins{m}.grid.x, kins{m}.U.rho, 'LineWidth', 1.6);
    leg{end+1} = sprintf('$\\varepsilon=%g$', eps_list(m)); %#ok<AGROW>
end
xlabel('$x$','Interpreter','latex'); ylabel('$\rho$','Interpreter','latex');
legend(leg,'Interpreter','latex','Location','best');
set(gca,'FontSize',16,'LineWidth',1.2); box on;
saveas(gcf, filename);
end
