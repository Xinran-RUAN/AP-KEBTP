clc; clear;

eps_list = [1, 1e-1, 1e-2, 1e-3];
T_list = [1, 5, 10, 50];

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

        % 保存目标时间点
        if save_index <= length(T_target) && abs(T - T_target(save_index)) < dt / 2
            rho_save(save_index, :) = rho;
            save_index = save_index + 1;
        end
    end

    % 保存数据
    for j = 1:length(T_target)
        rho = rho_save(j, :); % 需要先赋值再保存
        save(sprintf('rho_eps_%.0e_T_%.0f.mat', eps_val, T_target(j)), '-v7.3');
    end
end
