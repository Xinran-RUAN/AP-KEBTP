% 比较解的形状 (数据来自compare_profile.m)
chi_N = 1.1; chi_S = 1/2;
D_rho = 1; 
sigma = 0.7235; % 由myEquation计算而得
lmd_n = (-sigma + chi_S + chi_N) / D_rho;
lmd_p = (-sigma - chi_S + chi_N) / D_rho;
M = sum(rho) * domain.dx;
rho_0 = M / (1/lmd_n + 1/abs(lmd_p));
% 对应时刻最大值点位置大约是66.8818
x_peak = 66.8818; 
rho_approx = rho_0 * exp(...
    lmd_n * min(x-x_peak, 0)...
    +lmd_p * max(x-x_peak, 0));
plot(x,rho, 'LineWidth', 2); hold on;
plot(x,rho_approx, '--', 'LineWidth', 2); hold off;
xlim([55,90])
legend('Numerical', 'Analytical');
set(gca, 'FontSize', 20, 'LineWidth', 2);


