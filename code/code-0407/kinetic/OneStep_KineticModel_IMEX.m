% Index j (starting from 1) ~ position in x
%       where x(j) = (j-1/2) * dx, j = 1, ..., N = length(x)
%             x(N) = x_max - 1/2 * dx
%   rho, c, n are defined at  
%       x(1), ..., x(N): 
%       1,2,...,N
%   G is defined at 
%       x(1/2)=0, x(3/2), ..., x(N-1/2), x(N+1/2)=x_max:
%       1/2,3/2,...,N-1/2,N+1/2
%   so G(:,1) is defined at x = 0
%   
%   Neumann boundary condition:
%       rho_ex = [rho(1), rho, rho(end)]: 0,1,...,N,N+1
%       G_ex = [G(:,2), G, G(:, end-1)]: -1/2,1/2, ..., N+1/2, N+3/2
function[Rho_CurrentStep, C_CurrentStep, N_CurrentStep, G_CurrentStep] = OneStep_KineticModel_IMEX(rho, c, n, G, domain, dt, mypara, myfunc)
Nx = domain.Nx;
x = domain.x;
dx = domain.dx;
v = domain.v;
dv = domain.dv;
eps = mypara.eps;
% compute phi and psi
Psi = myfunc.psi(v');
Phi_c = myfunc.phi_c(v');
Phi_n = myfunc.phi_n(v');

% Neumann extension
rho_ex = [rho(1), rho, rho(end)];   % 0,1,...,N+1
c_ex = [c(1), c, c(end)]; % 0,1,...,N+1
n_ex = [n(1), n, n(end)]; % 0,1,...,N+1

% first derivative
drho_dx = diff(rho_ex) / dx; % 1/2, 3/2,...,N+1/2       
dc_dx = diff(c_ex) / dx; % 1/2, 3/2,...,N+1/2
uc = sign(dc_dx); % 1/2, 3/2,...,N+1/2
uc_p = max(uc, 0); uc_n = -min(uc, 0);

dn_dx = diff(n_ex) / dx; % 1/2, 3/2,...,N+1/2
un = sign(dn_dx); % 1/2, 3/2,...,N+1/2
un_p = max(un, 0); un_n = -min(un, 0);
% ======================================================
% % To construct matrix for $div(rho * u)$
% %     where uc = sign(dc/dx), un = sign(dn/dx)
% ======================================================
% % ======================================================
% % To Construct Mc such that 
% %       Mc * rho = div(rho * uc)
% % ======================================================
c0 = uc_n(1:end-1) + uc_p(2:end); 
c1 = [0, -uc_n(2:end-1)];
c_1 = [-uc_p(2:end-1), 0];
Mc = 1 / dx * spdiags([c_1', c0', c1'], [-1, 0, 1], Nx, Nx);
% Neumann BC is automatically satisfied since uc(1) = uc(end) = 0 

% % ======================================================
% % To Construct Mn such that
% %      Mn * rho = div(rho * un)
% % ======================================================
n0 = un_n(1:end-1) + un_p(2:end);
n1 = [0, -un_n(2:end-1)];
n_1 = [-un_p(2:end-1), 0];
Mn = 1 / dx * spdiags([n_1', n0', n1'], [-1, 0, 1], Nx, Nx);
% Neumann BC is automatically satisfied since un(1) = un(end) = 0 

% compute rho * U_c and rho * U_n at x(1-1/2), ..., x(N+1/2) 
%   up-wind form depending on sign of U_c and U_n
%   Here U_c = sign(dc_dx), U_n = sign(dn_dx)
% Due to Neumann BC, we only need to compute at x(1+1/2), ..., x(N-1/2)
%   and do zero extension (because dc_dx = dn_dx = 0)
rho_l = rho(1:end-1); % 1,2,...,N-1
rho_r = rho(2:end); % 2,3,...,N

rhoUc_in = uc_p(2:end-1) .* rho_l ...
         - uc_n(2:end-1) .* rho_r; % 3/2,...,N-1/2
rhoUc = [0, rhoUc_in, 0]; % 1/2, 3/2, ..., N-1/2,N+1/2

rhoUn_in = un_p(2:end-1) .* rho_l ...
         - un_n(2:end-1) .* rho_r; % 3/2,...,N-1/2
rhoUn = [0, rhoUn_in, 0]; % 1/2, 3/2, ..., N-1/2,N+1/2

% compute $G1_flux = v * \p_x(g)$ 
G_Flux_res = Compute_G_Flux_res(G, v, Psi, dx, dv); % 1/2,...,N+1/2

%% update tilde{G}
% compute tilde{S} without the term g/eps^2 
tS_remained = - v' .* Psi .* drho_dx ...
    + Phi_c .* rhoUc ...
    + Phi_n .* rhoUn; % 1/2, 3/2,...,N+1/2
% update g
tG = (dt * (-G_Flux_res * eps + tS_remained) + G * eps ^ 2) ./ (eps ^ 2 + dt ); % 1/2, ..., N+1/2

%% update rho - implicit
% Unlike the macro model, D_rho is determine by Psi in the main procedure
a = dt / (eps^2 + dt);
D = integration_v_meshgrid((v.^2)' .* Psi, dv);
chi_c = integration_v_meshgrid(v' .* Phi_c, dv);
chi_n = integration_v_meshgrid(v' .* Phi_n, dv);
% ======================================================
% To construct matrix for $- Delta rho$
% ======================================================
a0 =  2 * ones(size(x)); 
a1 = -ones(size(x));
a_1 = -ones(size(x));
MD = 1 / dx^2 * spdiags([a_1', a0', a1'], [-1,0,1], Nx, Nx);
% Neumann BC: rho(0) = rho(1), rho(N) = rho(N+1)
MD(1, 1) = MD(1, 1) / 2;
MD(end, end) = MD(end,end) / 2;

% To construct matrix MAT_Rho
MAT_Rho = speye(Nx) / dt ...
    + a * D * MD ...
    + a * chi_c * Mc...
    + a * chi_n * Mn;
% ======================================================
% To compute residuals 
% ======================================================
% To compute integral(v*diff(g), dv)  
% dGdx = (G(:, 2:end) - G(:, 1:end-1)) / dx;  % 1,...,N
dGdx = (tG(:, 2:end) - tG(:, 1:end-1)) / dx;  % 1,...,N
int_vdGdx_dv = integration_v_meshgrid(v' .* dGdx, dv); % 1,...,N
% To compute $- Delta rho$
Lap_rho_eps = MD * rho';  
% To compute $div(rho * uc)$
div_uc_rho_eps = Mc * rho'; 
div_un_rho_eps = Mn * rho'; 
% compute r
rhs = rho' / dt - int_vdGdx_dv' ...
    + a * D * Lap_rho_eps ...
    + a * chi_c * div_uc_rho_eps ...
    + a * chi_n * div_un_rho_eps;    % 1, ..., N
% update rho
Rho_CurrentStep = (MAT_Rho \ rhs)'; % 1, ..., N

if min(rhs)<-0.1
    pause(0.1);
    % figure(2); plot(integration_v_meshgrid(G_CurrentStep, dv));
end

%% update G
Rho_ex = [Rho_CurrentStep(1), Rho_CurrentStep, Rho_CurrentStep(end)];  % 0,1, 2, ..., N, N+1
dRho_dx = diff(Rho_ex) / dx;         % 1/2, ..., N+1/2

rho_c = rho_ex(1:end-1) .* (uc > 0) ...
      + rho_ex(2:end) .* (uc <= 0);  % 1/2, ..., N+1/2
rho_n = rho_ex(1:end-1) .* (un > 0) ...
      + rho_ex(2:end) .* (un <= 0);  % 1/2, ..., N+1/2
Rho_c = Rho_ex(1:end-1) .* (uc > 0) ...
      + Rho_ex(2:end) .* (uc <= 0);  % 1/2, ..., N+1/2
Rho_n = Rho_ex(1:end-1) .* (un > 0) ...
      + Rho_ex(2:end) .* (un <= 0);  % 1/2, ..., N+1/2

G_CurrentStep = tG + a * ( ...
    + Phi_c .* uc .* (Rho_c - rho_c) ...
    + Phi_n .* un .* (Rho_n - rho_n) ...
    - v' .* Psi .* (dRho_dx - drho_dx)); % 1/2, ..., N+1/2


%% 测试
if max(Rho_CurrentStep)>1.2
    figure(1); plot(Rho_CurrentStep);
    % figure(2); plot(integration_v_meshgrid(G_CurrentStep, dv));
end

%% 后处理
F = max(Psi * Rho_CurrentStep + eps * 0.5 * (G_CurrentStep(:,1:end-1) + G_CurrentStep(:,2:end)), 0);
Rho_CurrentStep = integration_v_meshgrid(F, dv);
G_CurrentStep_h = (F - Psi * Rho_CurrentStep) / eps;
G_CurrentStep_h_ex = [G_CurrentStep_h(:,1), G_CurrentStep_h, G_CurrentStep_h(:,end)];
G_CurrentStep = 0.5 * (G_CurrentStep_h_ex(:,1:end-1) + G_CurrentStep_h_ex(:,2:end));

%% update c
% zeta * \p_t c = Dc * \Delta c + beta * rho - alpha * c
% zeta is small since the chemoattractant diffuses faster...
% zeta_c = 1; alpha = 0.4; beta = 4*10^-7; Dc = 2;
zeta_c = 1; alpha = 0.05; beta = 1; Dc = 2;
MAT_C = zeta_c * speye(Nx) / dt + Dc * MD + alpha * speye(Nx);
% update c
rhs_c = zeta_c * c' / dt + beta * rho'; 
C_CurrentStep = (MAT_C \ rhs_c)'; % 1,...,N

%% update n
% zeta \p_t n = Dn * \Delta n - gamma * rho * n
% zeta is small since the chemoattractant diffuses faster...
% zeta_n = 1; gamma = 4*10^-7; Dn = 2;
zeta_n = 1; gamma = 1; Dn = 0;
MAT_N = zeta_n * speye(Nx) / dt + Dn * MD + gamma * spdiags(rho', 0, Nx, Nx); 
% update n
rhs_n = zeta_n * n' / dt;
N_CurrentStep = (MAT_N \ rhs_n)'; % 1, ..., N
