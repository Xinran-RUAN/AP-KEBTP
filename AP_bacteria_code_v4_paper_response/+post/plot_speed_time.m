function plot_speed_time(macro, kins, eps_list, filename)
filename = utils.resolve_project_path(filename);
utils.make_dir(fileparts(filename));
figure('Color','w'); hold on;
plot(macro.cm_t, gradient(macro.cm_x)./gradient(macro.cm_t), 'k--', 'LineWidth', 2);
leg = {'macro'};
for m = 1:numel(kins)
    t = kins{m}.cm_t; x = kins{m}.cm_x;
    plot(t, gradient(x)./gradient(t), 'LineWidth', 1.5);
    leg{end+1} = sprintf('$\\varepsilon=%g$', eps_list(m)); %#ok<AGROW>
end
xlabel('$t$','Interpreter','latex'); ylabel('wave speed','Interpreter','latex');
legend(leg,'Interpreter','latex','Location','best');
set(gca,'FontSize',16,'LineWidth',1.2); grid on; box on;
saveas(gcf, filename);
end
