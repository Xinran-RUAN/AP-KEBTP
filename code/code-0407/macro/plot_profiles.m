% plot profiles
load density_T_20.mat;
x1 = domain.x; rho1 = rho;
load density_T_60.mat;
x2 = domain.x; rho2 = rho;
load density_T_100.mat;
x3 = domain.x; rho3 = rho;
figure(1)
plot(x1, rho1, 'k-.', 'LineWidth', 2); hold on;
plot(x2, rho2, 'r--', 'LineWidth', 2); hold on;
plot(x3, rho3, 'b-', 'LineWidth', 2); hold off;
legend('T=20', 'T=60','T=100')
xlabel('$x$', 'Interpreter', 'latex');
ylabel('$\rho$', 'Interpreter', 'latex');
set(gca, 'FontSize', 20, 'LineWidth', 2);
xlim([0, 120])
