clc; clear;

% 参数设置
mypara.chi_c = 1/2; 
mypara.chi_n = 1.1;

% 空间离散
domain.dx = 1e-1;
domain.x_min = 0 + domain.dx / 2;
domain.x_max = 1e2 - domain.dx / 2; 
domain.Nx = round((domain.x_max - domain.x_min )/ domain.dx) + 1; 
domain.x = linspace(domain.x_min, domain.x_max, domain.Nx);

x = domain.x; 
rho = exp(-abs(x));  % 初始 rho
c = zeros(size(x)); 
n = 1e3 * ones(size(x)); 

% 时间参数
dt = 1e-2; 
T = 0; Tn = 50;
NT = Tn / dt;

% 目标保存时间
T_target = [1, 5, 10, 50];
save_index = 1;
rho_save = zeros(length(T_target), domain.Nx);

for kT = 1:NT
    [rho_temp, c_temp, n_temp] = OneStep_macro(rho, c, n, ...
        domain, dt, mypara);

    rho = rho_temp;
    c = c_temp;
    n = n_temp;
    T = T + dt;

    if save_index <= length(T_target) && abs(T - T_target(save_index)) < dt / 2
        rho_save(save_index, :) = rho;
        save_index = save_index + 1;
    end
end

% 保存所有 rho 到对应 T 的 .mat 文件中
for j = 1:length(T_target)
    rho = rho_save(j, :);
    save(sprintf('rho_macro_T_%.0f.mat', T_target(j)), '-v7.3');
end
