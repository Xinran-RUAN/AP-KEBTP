% ===================== main_kinetic_bistability_test.m =====================
% Goal: reproduce two admissible wave speeds (slow/fast) as in Fig. 5.1–5.2
% using a discrete 4-velocity set V = {-1, -vmin, vmin, 1} with uniform weights.
%
% Mapping to paper:
%   mypara.chi_c  <-> chi_M
%   mypara.chi_n  <-> chi_N
%   alpha, D_M    <-> reaction-diffusion parameters in signal equation (set inside OneStep or mypara)
%
% IMPORTANT:
%   After discretizing velocities, ALL v-integrals must use domain.w (NOT dv*sum).
%   So please ensure OneStep_KineticModel_IMEX uses domain.w everywhere.

clc; clear;

%% -------------------- parameters (match Fig. 5.1 caption) --------------------
% chi_M, chi_N
mypara.chi_c = 0.48;   % == chi_M in the paper (Fig. 5.1)
mypara.chi_n = 0.44;   % == chi_N in the paper (Fig. 5.1)

mypara.eps   = 1;   % (keep your epsilon; paper uses kinetic scaling, eps affects stiffness)

% If your OneStep uses these for M-equation, set them to match Fig. 5.1:
mypara.alpha = 40;     % == alpha in Fig. 5.1
mypara.DM    = 0.5;    % == D_M in Fig. 5.1
mypara.beta  = 1;
mypara.DN    = 0;
mypara.gamma = 1;

%% -------------------- spatial grid --------------------
domain.dx    = 0.1;           % to capture fast wave better (see Fig. 5.2 right)
domain.x_min = -100 + domain.dx/2;
domain.x_max = 500 - domain.dx/2;
domain.Nx    = round((domain.x_max-domain.x_min)/domain.dx) + 1;
domain.x     = linspace(domain.x_min, domain.x_max, domain.Nx);

%% -------------------- discrete 4-velocity set (match Fig. 5.1 caption) --------------------
vmin      = 0.5;
domain.v  = [-1, -vmin, vmin, 1];
domain.Nv = numel(domain.v);

% Uniform weights (Fig. 5.1: "weights are uniform")
domain.dv  = 1/domain.Nv; % 非步长，而是权重

%% -------------------- velocity kernels psi / phi --------------------
% In the paper for discrete velocities, they use UNIFORM WEIGHTS for V
% That corresponds to choosing psi(v_i) proportional to w_i.
%
% Here we keep function handles for consistency, but in discrete case
% psi/phi are typically evaluated only at v_i and integrated with w_i.

v = domain.v(:);                 % Nv x 1
dv = domain.dv;

Psi  = ones(size(v));            % psi(v_i)=1
D    = sum(dv .* (v.^2) .* Psi);  % = <v^2 psi>

Phi_c = (mypara.chi_c / D) * v;  % ensures <v*Phi_c>=chi_c
Phi_n = (mypara.chi_n / D) * v;  % ensures <v*Phi_n>=chi_n

% 把它们存起来，OneStep 里直接用，不再每次调用函数句柄
myfunc.Psi_vec   = Psi;
myfunc.Phi_c_vec = Phi_c;
myfunc.Phi_n_vec = Phi_n;

%% -------------------- initialization --------------------
x  = domain.x;
Nx = numel(x);
Nv = numel(v);

% Your state variables:
% % Ll = 2;
% Lr = 5;
% % rho = exp((x<0).* x/Ll - (x>0).*x/Lr);         % baseline density profile
% rho = exp(-x/Lr);
% load('data_kinetic/data_kinetic_ChiC_0.48_ChiN_0.44_eps_1e+00_T_1000_dt_1e-02.mat','rho')
my_equation = @(x) mypara.chi_n - x - mypara.chi_c * x / sqrt(4 * mypara.DM * mypara.alpha + x^2); 
x0 = 1; % 初始猜测值
speed_anal = fzero(my_equation, x0);
lmd_n = (-speed_anal + mypara.chi_c + mypara.chi_n) / D;  
lmd_p = (-speed_anal - mypara.chi_c + mypara.chi_n) / D;  
rho = exp((x<20).* (x-20)*lmd_n + (x>20).*(x-20)*lmd_p);


% Csig = zeros(1, Nx);        % your "c" variable is signal concentration; rename locally
Nnut = 10 * ones(1, Nx);   % nutrient
G    = zeros(Nv, Nx+1);     % micro part (as in your code)

% initial value of Csig
% build MD once in main (same as in OneStep)
a0 = 2*ones(1,Nx); a1 = -ones(1,Nx); a_1 = -ones(1,Nx);
MD = 1/domain.dx^2 * spdiags([a_1',a0',a1'],[-1,0,1],Nx,Nx);
MD(1,1) = MD(1,1)/2; MD(end,end) = MD(end,end)/2;

DM = mypara.DM; alpha = mypara.alpha; beta = mypara.beta;
MAT_M0 = DM*MD + alpha*speye(Nx);
rhs_M0 = beta * rho';
Csig = (MAT_M0 \ rhs_M0)';   % c 是 M0

%% -------------------- time stepping --------------------
dt   = 1e-2;
T    = 2e3;
Tend = 1e3;
NT   = round(Tend/dt);

T_plot = T:T+Tend;                 % plot every integer time
x_mass = zeros(size(T_plot));
mass_index = 1;

for kT = 1:NT
    [rho_new, Csig_new, Nnut_new, G_new] = OneStep_KineticModel_IMEX( ...
        rho, Csig, Nnut, G, domain, dt, mypara, myfunc);

    rho  = rho_new;
    Csig = Csig_new;
    Nnut = Nnut_new;
    G    = G_new;

    T = T + dt;

    if min(abs(T - T_plot)) < dt/2
        % ---- optional: your plotting ----
        PLOT_DATA;  % make sure it uses rho, etc.

        % ---- speed diagnostic via center of mass ----
        x_mass(mass_index) = sum(x .* rho) / sum(rho);
        fprintf("chi_M=%.2f, chi_N=%.2f, t=%.1f\n", mypara.chi_c, mypara.chi_n, T);
        rho_mass = sum(rho) * domain.dx;
        fprintf("t=%.1f, mass=%.6e, max(rho)=%.4e\n", ...
            T, rho_mass, max(rho));

        mass_index = mass_index + 1;
    end
end

% ---- estimate speed ----
speed_t = diff(x_mass) / 1.0;          % because x_mass sampled at integer times
S_num   = mean(speed_t(end-5:end));
fprintf("chi_M=%.2f, chi_N=%.2f, vmin=%.2f, speed ~ %.4f\n", ...
    mypara.chi_c, mypara.chi_n, vmin, S_num);