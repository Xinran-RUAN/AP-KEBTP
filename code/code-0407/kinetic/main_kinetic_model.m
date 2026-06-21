% Main file for kinetic model
%   Psi_0 = Psi; 
%   Psi_1 = chi_C * Phi * sign(dx_C) + chi_N * Phi * sign(dx_N)

%%
clc; clear;
mypara.chi_c = 1/2; 
mypara.chi_n = 1.1; 
mypara.eps = 1e-2; 
%% functions
% Please check int_v psi(v) dv = 1 and D = int v^2 * psi dv 
% !! Unlike the macro model: D is determined here
% myfunc.psi = @(v) 0.5 * ones(size(v)); 
% sigma0 = 1;
% myfunc.psi = @(v) 1 / sqrt(2*pi) / sigma0 * exp(- v .* v / 2 / sigma0^2); 
myfunc.psi = @(v) ones(size(v)); 
% Please check int_v v * phi(v) dv = chi (given)
sigma = 0.1;
myfunc.phi_c = @(v) mypara.chi_c / sqrt(2 * pi)/sigma^3 * v .* exp(- v .* v/2/sigma^2);
myfunc.phi_n = @(v) mypara.chi_n / sqrt(2 * pi)/sigma^3 * v .* exp(- v .* v/2/sigma^2);

%% Initialization
% Define x
% rho, c, n are defined at half-grid points: 
domain.dx = 1e-1;
domain.x_min = 0 + domain.dx / 2;
domain.x_max = 150 - domain.dx / 2; 
domain.Nx = round((domain.x_max - domain.x_min) / domain.dx) + 1; 
domain.x = linspace(domain.x_min, domain.x_max, domain.Nx);

% Define v
domain.v_max = 1; 
domain.v_min = -1;
domain.dv = 2e-2;
% domain.v_max = 20; 
% domain.v_min = -20;
% domain.dv = 5e-1;
domain.Nv = (domain.v_max - domain.v_min) / domain.dv + 1; 
domain.v = linspace(domain.v_min, domain.v_max,domain.Nv);

% SET_INITIAL_DATA;
x = domain.x; % x(j) = (j - 1/2) * dx
v = domain.v;
Nx = length(x); 
Nv = length(v);
rho = exp(-abs(x));
c = zeros(1, Nx);     
n = 1e3*ones(1, Nx); 
G = zeros(Nv, Nx + 1); % 1/2, ..., N+1/2 
%% Time Evolution 
dt = 1e-2; 
T = 0; 
Tn = 60;
NT = Tn / dt;
T_plot = 1:Tn;
x_mass = zeros(size(T_plot));
mass_index = 1;

for kT = 1:NT
    [rho_temp, c_temp, n_temp, G_temp] = OneStep_KineticModel_IMEX(rho, c, n, G,...
        domain, dt, mypara, myfunc);

    % update rho, s, n, G
    rho = rho_temp;
    c = c_temp;
    n = n_temp;
    G = G_temp;   
    T = T + dt;    
    
    % save data and plot data   
    if min(abs(T - T_plot)) < dt / 2  
        PLOT_DATA;
        % SAVE_DATA;
        x_mass(mass_index) = sum(x .* rho) / sum(rho);
        mass_index = mass_index + 1;
        fprintf("chi_S = %.2f, chi_N = %.2f, T = %.1f \n", mypara.chi_c, mypara.chi_n, T);
    end
    
end
SAVE_DATA;
%% 
travelling_speed = diff(x_mass);
speed_numer_case = mean(travelling_speed(end-5:end));
fprintf("chi_S = %.2f, chi_N = %.2f, speed = %.2f \n", mypara.chi_c, mypara.chi_n, speed_numer_case);
