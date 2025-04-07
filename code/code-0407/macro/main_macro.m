%%
clc; clear;
mypara.chi_c = 1/2; 
mypara.chi_n = 1.1; 
% mypara.chi_c = 1; 
% mypara.chi_n = 1; 

%% Initialization
% Define x: [0,100]
% domain.dx = 5e-3;
domain.dx = 1e-1;
domain.x_min = 0 + domain.dx / 2;
domain.x_max = 5e2 - domain.dx / 2; 
domain.Nx = round((domain.x_max - domain.x_min )/ domain.dx) + 1; 
domain.x = linspace(domain.x_min, domain.x_max, domain.Nx);


% SET_INITIAL_DATA;
x = domain.x; 
rho = exp(-abs(x));  % 初值聚集在左侧
c = zeros(size(x));      % IN PAPER OF HAL, PAGE 11
% n = 10000*ones(size(x));
n = 1e3*ones(size(x));

%% Time Evolution 
dt = 1e-2; 
T = 0; Tn = 10;
NT = Tn / dt;
T_plot = 1:Tn;
x_mass = zeros(size(T_plot));
mass_index = 1;

for kT = 1:NT

    [rho_temp, c_temp, n_temp] = OneStep_macro(rho, c, n, ...
        domain, dt, mypara);

    % update rho, s, n
    rho = rho_temp;
    c = c_temp;
    n = n_temp;   
    T = T + dt;    
    
    % save data and plot data   
    if min(abs(T - T_plot)) < dt / 2  
        PLOT_DATA;

        % 计算质心位置
        x_mass(mass_index) = sum(x .* rho) / sum(rho);
        mass_index = mass_index + 1;
    end
end

%% 
dt_step = 1; % 两次计算的时间间隔为1
travelling_speed = diff(x_mass);
speed_numer_case = mean(travelling_speed(end-9:end));
% 计算speed_anal_case
% 确保 Ds = 2; alpha = 0.05;
Ds = 2; alpha = 0.05;
chi_N = mypara.chi_n;
chi_S = mypara.chi_c;
my_equation = @(x) chi_N - x - chi_S * x / sqrt(4 * Ds * alpha + x^2); 
x0 = 1; % 初始猜测值
speed_anal_case = fzero(my_equation, x0);
% 保存数据
file_name = strcat('data_chiN_', num2str(chi_N), '_chiS_', num2str(chi_S),'.mat');
save(file_name);
