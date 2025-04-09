clc; clear;

% eps_list = [1, 1e-1, 1e-2, 1e-3];
eps_list = 5e-2;
T_list = [1, 5, 10:10:50];

for i = 1:length(eps_list)
    eps_val = eps_list(i);

    % 设置参数
    mypara.chi_c = 1/2; 
    mypara.chi_n = 1.1; 
    mypara.eps = eps_val;

    % 函数设置
    myfunc.psi = @(v) 1 / sqrt(2 * pi) * exp(-v .* v / 2); 
    myfunc.phi_c = @(v) mypara.chi_c / sqrt(2 * pi) * v .* exp(-v .* v / 2);
    myfunc.phi_n = @(v) mypara.chi_n / sqrt(2 * pi) * v .* exp(-v .* v / 2);

    % 空间离散
    domain.dx = 1e-1;
    domain.x_min = 0 + domain.dx / 2;
    domain.x_max = 1e2 - domain.dx / 2; 
    domain.Nx = (domain.x_max - domain.x_min) / domain.dx + 1; 
    domain.x = linspace(domain.x_min, domain.x_max, domain.Nx);

    % 速度离散
    domain.v_max = 50; 
    domain.v_min = -50;
    domain.dv = 1;
    domain.Nv = (domain.v_max - domain.v_min) / domain.dv + 1; 
    domain.v = linspace(domain.v_min, domain.v_max,domain.Nv);

    % 初始数据
    x = domain.x;
    v = domain.v;
    Nx = length(x); 
    Nv = length(v);
    rho = exp(-abs(x));
    c = zeros(1, Nx);     
    n = 1e3*ones(1, Nx); 
    G = zeros(Nv, Nx + 1); 

    % 时间推进设置
    dt = 1e-3; 
    T = 0; 
    Tn = 50;
    NT = Tn / dt;

    % 初始化质心位置数组
    centroid_positions = zeros(1, NT); 

    % 保存这些时间点的解
    T_target = T_list; 
    rho_save = zeros(length(T_target), Nx);
    save_index = 1;

    for kT = 1:NT
        [rho_temp, c_temp, n_temp, G_temp] = OneStep_KineticModel_IMEX(rho, c, n, G,...
            domain, dt, mypara, myfunc);

        rho = rho_temp;
        c = c_temp;
        n = n_temp;
        G = G_temp;
        T = T + dt;

        % 计算质心位置
        numerator = sum(domain.x .* rho) * domain.dx;  % x * rho(x) 的积分
        denominator = sum(rho) * domain.dx;  % rho(x) 的积分
        centroid_position = numerator / denominator;  % 计算质心位置
        centroid_positions(kT) = centroid_position;

        % 保存目标时间点
        if save_index <= length(T_target) && abs(T - T_target(save_index)) < dt / 2
            fprintf('Complete: eps = %.0e, T = %.0f\n', eps_val, T_target(save_index));
            rho_save(save_index, :) = rho;
            save_index = save_index + 1;
        end
    end
    % 计算travelling speed并输出为csv文件
    travel_speed = (centroid_positions(2:end) - centroid_positions(1:end-1)) / dt;
    T_values = (2:NT) * dt; % 时间点
    speed_with_time = [T_values; travel_speed]'; % 将时间与速度结合
    % 保存为带时间戳的 CSV 文件
    writematrix(speed_with_time, sprintf('travel_speed_with_time_eps_%.0e_T_%.0f.csv', eps_val, Tn));

    % 保存最终时刻的所有数据
    save(sprintf('rho_eps_%.0e_T_%.0f_all.mat', eps_val, Tn), '-v7.3');

    % 保存数据
    for j = 1:length(T_target)
        rho = rho_save(j, :); % 需要先赋值再保存
        save(sprintf('rho_eps_%.0e_T_%.0f.mat', eps_val, T_target(j)), 'rho', 'domain', '-v7.3');
    end
end
