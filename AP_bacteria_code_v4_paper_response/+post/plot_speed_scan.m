function plot_speed_scan(chiN, chiS, S_pred, S_macro, S_kin, filename)
%PLOT_SPEED_SCAN Plot and save wave speed scans.
filename = utils.resolve_project_path(filename);
utils.make_dir(fileparts(filename));
fig_dir = fileparts(filename);

fig = figure('Color','w','Position',[100 100 1200 360]);
subplot(1,3,1); local_panel(chiN, chiS, S_pred, 'Predicted wave speed');
subplot(1,3,2); local_panel(chiN, chiS, S_macro, 'Wave speed for the macro model');
subplot(1,3,3); local_panel(chiN, chiS, S_kin, 'Wave speed for the kinetic model');
set(findall(gcf,'Type','axes'),'FontSize',14,'LineWidth',1.2);
saveas(fig, filename);
saveas(fig, fullfile(fig_dir,'travelling_speed_all.eps'), 'epsc');
close(fig);

local_single(chiN, chiS, S_pred, fullfile(fig_dir,'travelling_speed_analytic.eps'), 'Predicted wave speed');
local_single(chiN, chiS, S_macro, fullfile(fig_dir,'travelling_speed_numeric_macro.eps'), 'Wave speed for the macro model');
local_single(chiN, chiS, S_kin, fullfile(fig_dir,'travelling_speed_numeric_kinetic.eps'), 'Wave speed for the kinetic model');
end

function local_panel(chiN, chiS, S, ttl)
imagesc(chiN, chiS, S.'); axis xy; colorbar;
title(ttl,'Interpreter','latex');
xlabel('$\chi_N$','Interpreter','latex'); ylabel('$\chi_S$','Interpreter','latex');
caxis([0 max(2, max(S(:),[],'omitnan'))]);
end

function local_single(chiN, chiS, S, filename, ttl)
fig = figure('Color','w','Position',[100 100 520 420]);
local_panel(chiN, chiS, S, ttl);
set(gca,'FontSize',15,'LineWidth',1.2);
saveas(fig, filename, 'epsc');
close(fig);
end
