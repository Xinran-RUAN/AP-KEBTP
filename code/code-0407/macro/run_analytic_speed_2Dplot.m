% 计算speed_anal_case
Ds = 2; alpha = 0.05;
chi_N = 0:0.02:2;
chi_S = 0:0.02:2;
[Chi_N, Chi_S] = meshgrid(chi_N, chi_S);

Nn = length(chi_N);
Ns = length(chi_S);
speed_anal = zeros(size(Chi_N));

for jj = 1:Nn
    for kk = 1:Ns
        c_n = chi_N(jj);
        c_s = chi_S(kk);
        my_equation = @(x) c_n - x - c_s * x / sqrt(4 * Ds * alpha + x^2); 
        x0 = 1; % 初始猜测值
        speed_anal(kk,jj) = fzero(my_equation, x0);
    end
end
%% plot
% imagesc(chi_N, chi_S, speed_anal);
pcolor(chi_N, chi_S, speed_anal);
shading interp;      % 插值使图像更平滑
colormap(jet);      % 更换颜色方案
colorbar;            % 加颜色条
xlabel('$\chi_N$', 'Interpreter', 'latex', 'FontSize', 20); 
ylabel('$\chi_S$', 'Interpreter', 'latex', 'FontSize', 20); 
title('Travelling speed $\sigma$', 'Interpreter', 'latex', 'FontSize', 20);
set(gca, 'FontSize', 20);
% domain_bound = 5;
% xlim([-domain_bound, domain_bound]);
% ylim([-domain_bound, domain_bound]);
clim([0, 2]) 
