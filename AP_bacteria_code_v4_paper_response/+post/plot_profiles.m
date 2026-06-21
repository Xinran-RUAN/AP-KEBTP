function plot_profiles(macro, kin, filename)
filename = utils.resolve_project_path(filename);
utils.make_dir(fileparts(filename));
figure('Color','w'); hold on;
if ~isempty(macro)
    plot(macro.grid.x, macro.U.rho, 'k--', 'LineWidth', 2);
end
plot(kin.grid.x, kin.U.rho, 'LineWidth', 2);
xlabel('$x$','Interpreter','latex'); ylabel('$\rho$','Interpreter','latex');
legend_entries = {};
if ~isempty(macro), legend_entries{end+1}='macro'; end %#ok<AGROW>
legend_entries{end+1}=sprintf('kinetic eps=%g', kin.params.eps);
legend(legend_entries,'Location','best');
set(gca,'FontSize',16,'LineWidth',1.2); box on;
saveas(gcf, filename);
end
