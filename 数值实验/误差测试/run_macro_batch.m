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
dt = 1e-3; 
T = 0; Tn = 50;
NT = Tn / dt;
% 初始化质心位置数组
centroid_positions = zeros(1, NT); 

% 目标保存时间
T_target = [1, 5, 10, 50];
save_index = 1;
rho_save = zeros(length(T_target), domain.Nx);

for kT = 1:NT
    [rho_temp, c_temp, n_temp] = OneStep_macro(rho, c, n, ...
        domain, dt, mypara);

    % 更新
    rho = rho_temp;
    c = c_temp;
    n = n_temp;
    T = T + dt;

    % 计算质心位置
    numerator = sum(domain.x .* rho) * domain.dx;  % x * rho(x) 的积分
    denominator = sum(rho) * domain.dx;  % rho(x) 的积分
    centroid_position = numerator / denominator;  % 计算质心位置
    centroid_positions(kT) = centroid_position;

    if save_index <= length(T_target) && abs(T - T_target(save_index)) < dt / 2
        rho_save(save_index, :) = rho;
        save_index = save_index + 1;
    end
end
% 计算travelling speed并输出为csv文件
travel_speed = (centroid_positions(2:end) - centroid_positions(1:end-1)) / dt;
T_values = (2:NT) * dt; % 时间点
speed_with_time = [T_values; travel_speed]'; % 将时间与速度结合
% 保存为带时间戳的 CSV 文件
writematrix(speed_with_time, sprintf('travel_speed_with_time_macro_T_%.0f.csv', Tn));

% 保存最终时刻的所有数据
save(sprintf('rho_macro_T_%.0f_all.mat', Tn), '-v7.3');

% 保存所有 rho 到对应 T 的 .mat 文件中
for j = 1:length(T_target)
    rho = rho_save(j, :);
    save(sprintf('rho_macro_T_%.0f.mat', T_target(j)),'rho', 'domain', '-v7.3');
end
