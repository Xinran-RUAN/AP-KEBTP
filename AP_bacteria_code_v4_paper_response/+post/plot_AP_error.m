function plot_AP_error(eps_list, errT, filename)
filename = utils.resolve_project_path(filename);
utils.make_dir(fileparts(filename));
figure('Color','w'); loglog(eps_list, errT, 'o-', 'LineWidth', 2, 'MarkerSize', 7);
xlabel('$\varepsilon$','Interpreter','latex'); ylabel('$\|\rho^\varepsilon-\rho\|_2$','Interpreter','latex');
set(gca,'FontSize',16,'LineWidth',1.2); grid on; box on;
saveas(gcf, filename);
end
