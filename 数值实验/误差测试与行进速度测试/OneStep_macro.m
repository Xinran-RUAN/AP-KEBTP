% Index jj (starting from 1) ~ position in x
%       x(kk) = x_min + kk * dx, 
%             x_min = x(0) = x_1, (index 1)
%             x_max = x(N) = x_{N+1}. (index N+1)
%   Unknowns: rho, c, n:  x(0), x(1), ..., x(N); 

% Neumann boundary: 
%   rho(-1) = rho(1), rho(N-1) = rho(N+1)


function[rho_n, C_CurrentStep, N_CurrentStep] = OneStep_macro(rho, c, n, domain, dt, mypara)
Nx = domain.Nx; 
dx = domain.dx;
x = domain.x;
chi_c = mypara.chi_c; 
chi_n = mypara.chi_n;
%% update rho - implicit
D_rho = 1;
Matrix_div_urho;    % get Mc, Mn
% construct matrix MD
a0 =  2 * ones(size(x)); 
a1 = -ones(size(x));
a_1 = -ones(size(x));
MD = 1 / dx^2 * spdiags([a_1', a0', a1'], [-1,0,1], Nx, Nx);
% Neumann BC
MD(1, 1) = MD(1, 1) / 2;
MD(end, end) = MD(end,end) / 2;
MAT_rho = speye(Nx) / dt + D_rho * MD + Mc + Mn;
rho_n = (MAT_rho \ (rho'/dt))';

%% update c
% zeta * \p_t c = Dc * \Delta c + beta * rho - alpha * c
% zeta is small since the chemoattractant diffuses faster...
% zeta_c = 1; alpha = 0.4; beta = 4*10^-7; Dc = 2;
zeta_c = 1; alpha = 0.05; beta = 1; Dc = 2;
% construct matrix
MAT_C = zeta_c * speye(Nx) / dt + Dc * MD + alpha * speye(Nx);
% update c
rhs_c = zeta_c * c' / dt + beta * rho'; 
C_CurrentStep = (MAT_C \ rhs_c)';

%% update n
% zeta * \p_t n = Dn * \Delta n - gamma * rho * n
% zeta is small since the nutrient diffuses faster...
% zeta_n = 1; gamma = 4*10^-7; Dn = 2;
zeta_n = 1; gamma = 1; Dn = 0;
% construct matrix
MAT_N = zeta_n * speye(Nx) / dt + Dn * MD + gamma * spdiags(rho', 0, Nx, Nx); % spdiags(B,d,m,n)中B应为列向量
% update n
rhs_n = zeta_n * n' / dt;
N_CurrentStep = (MAT_N \ rhs_n)';


