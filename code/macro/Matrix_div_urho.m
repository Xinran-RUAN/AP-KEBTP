% 已知：
%   行向量rho,c,n: x = (x_min+h/2, x_min+3h/2, ..., x_max-h/2)
%   Neumann边界条件
%   参数：chi_c， chi_n, dx, Nx = N 
% 目的：
%   寻找矩阵Mc, Mn 使得
%       dx(rho * u_c) = Mc * rho
%       dx(rho * u_n) = Mn * rho
%   在半点处成立
%   其中 
%       dx(rho * u_c)在x(j)=xmin+j*h/2处计算公式为
%           (u_{c,j+1/2} * rho_{c,j+1/2} - u_{c,j-1/2} * rho_{c,j-1/2}) / dx；
%           其中
%               rho_{c,j+1/2} = rho_j if u_{c,j+1/2} > 0
%               rho_{c,j+1/2} = rho_{j+1} if u_{c,j+1/2} < 0
%       dx(rho * u_n)在x(j)处计算方法类似
% 注：独立运行时需给出如下变量：
%   1. 行向量rho,c,n: 例如 rho = rand(1, 10)
%   2. 指定参数值chi_c， chi_n, dx，Nx = length(rho)
% 例：
% rho = rand(1, 10); c = rand(1, 10); n = rand(1, 10);
% chi_c = 1/2; chi_n = 0.1; dx = 0.1; Nx = 10;

%% Neumann边界条件下扩充
rho_ex = [rho(1), rho, rho(end)];
c_ex = [c(1), c, c(end)];
n_ex = [n(1), n, n(end)];
%% 计算uc,un
dcdx = diff(c_ex) / dx; % -1/2, 1/2, ..., N+1/2
uc = chi_c * sign(dcdx);
dndx = diff(n_ex) / dx;
un = chi_n * sign(dndx);
%% 构造矩阵Mc
uc_p = max(uc, 0);
uc_n = -min(uc, 0);
c0 = uc_n(1:end-1) + uc_p(2:end);
c1 = [0, -uc_n(2:end-1)];
c_1 = [-uc_p(2:end-1), 0];
Mc = 1/dx*spdiags([c_1', c0', c1'], [-1, 0, 1], Nx, Nx);
% Neumann边界：uc(1) = uc(end) = 0 故自动满足

%% 构造矩阵Mn
un_p = max(un, 0);
un_n = -min(un, 0);
n0 = un_n(1:end-1) + un_p(2:end);
n1 = [0, -un_n(2:end-1)];
n_1 = [-un_p(2:end-1), 0];
Mn = 1/dx*spdiags([n_1', n0', n1'], [-1, 0, 1], Nx, Nx);
% Neumann边界：un(1) = un(end) = 0 故自动满足

%% check Mc
% PHI_c_t = Mc * rho';
% u = chi_c * sign(dcdx);
% u_p = max(u, 0); u_n = -min(u, 0);
% rho_l = [rho(1), rho(1:end-1)];
% rho_r = [rho(2:end), rho(end)];
% PHI_c_test = (...
%     u_p(2:end) .* rho ...
%     -u_n(2:end) .* rho_r ...
%     +u_n(1:end-1) .* rho ...
%     -u_p(1:end-1) .* rho_l ...
%     ) / dx;
% err1 = max(abs(PHI_c_t' - PHI_c_test));
%% check Mn
% PHI_n_t = Mn * rho';
% u = chi_n * sign(dndx);
% u_p = max(u, 0); u_n = -min(u, 0);
% rho_l = [rho(1), rho(1:end-1)];
% rho_r = [rho(2:end), rho(end)];
% PHI_n_test = (...
%     u_p(2:end) .* rho ...
%     -u_n(2:end) .* rho_r ...
%     +u_n(1:end-1) .* rho ...
%     -u_p(1:end-1) .* rho_l ...
%     ) / dx;
% err2 = max(abs(PHI_n_t' - PHI_n_test));
