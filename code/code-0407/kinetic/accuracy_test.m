load data_chiN_1.1_chiS_0.5_eps_1e-3_0_10dt.mat;
x1 = domain.x; rho1 = rho;
load data_chiN_1.1_chiS_0.5_eps_1e-4_0_10dt.mat;
x2 = domain.x; rho2 = rho;
load data_chiN_1.1_chiS_0.5_eps_1e-5_0_10dt.mat;
x3 = domain.x; rho3 = rho;
% load data_chiN_1.1_chiS_0.5_T_50.mat;
load data_chiN_1.1_chiS_0.5_eps_0_10dt.mat;
x0 = domain.x; rho_macro = rho;
% figure(1)
% plot(x1, rho1, 'p-.', 'LineWidth', 2); hold on;
% plot(x2, rho2, 'r--', 'LineWidth', 2); hold on;
% plot(x3, rho3, 'b.', 'LineWidth', 2); hold on;
% plot(x0, rho_macro, 'k-', 'LineWidth', 2); hold off;
% legend('$\varepsilon=\varepsilon_0$', '$\varepsilon=\varepsilon_0/2$','$\varepsilon=\varepsilon_0/4$', 'macro',...
%     'Interpreter', 'latex')
% xlabel('$x$', 'Interpreter', 'latex');
% ylabel('$\rho$', 'Interpreter', 'latex');
% set(gca, 'FontSize', 20, 'LineWidth', 2);
% xlim([0, 80])
% 
% figure(2)
% plot(x1, rho1 - rho_macro(1:1000), 'p-.', 'LineWidth', 2); hold on;
% plot(x2, rho2 - rho_macro(1:1000), 'r--', 'LineWidth', 2); hold on;
% plot(x3, rho3 - rho_macro(1:1000), 'b-', 'LineWidth', 2); hold off;
% legend('$\varepsilon=\varepsilon_0$', '$\varepsilon=\varepsilon_0/2$','$\varepsilon=\varepsilon_0/4$',...
%     'Interpreter', 'latex')
% xlabel('$x$', 'Interpreter', 'latex');
% ylabel('$\rho$', 'Interpreter', 'latex');
% set(gca, 'FontSize', 20, 'LineWidth', 2);
% xlim([0, 80])

% 计算差别
l2_err = zeros(3,1);
l2_err(1) = sqrt(domain.dx * sum((rho1 - rho).^2));
l2_err(2) = sqrt(domain.dx * sum((rho2 - rho).^2));
l2_err(3) = sqrt(domain.dx * sum((rho3 - rho).^2));

linf_err = zeros(3,1);
linf_err(1) = max(abs(rho1 - rho));
linf_err(2) = max(abs(rho2 - rho));
linf_err(3) = max(abs(rho3 - rho));
