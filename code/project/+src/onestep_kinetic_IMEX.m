function state = onestep_kinetic_IMEX(state, dom, dt, para, func, cache)
% onestep_kinetic_IMEX
% One-step IMEX update for kinetic model
%
% state: struct with fields
%   t, rho(1×Nx), c(1×Nx), n(1×Nx), G(Nv×(Nx+1))
% dom: struct with fields Nx,Nv,dx,dv,x,v
% para: struct with fields eps, D, chi_c, chi_n
%       optional: use_limiter (bool)
%       optional M/N params: DM,alpha,beta, DN,gamma
% func: struct with function handles psi, phi_c, phi_n  (psi already normalized is OK)
% cache: struct with field MD (Nx×Nx) approximating (-dxx) with Neumann BC

%% ---------- unpack ----------
rho = state.rho;    % 1×Nx
c   = state.c;      % 1×Nx
n   = state.n;      % 1×Nx
G   = state.G;      % Nv×(Nx+1)

Nx = dom.Nx;
dx = dom.dx;
Nv = dom.Nv;
v  = dom.v(:);      % Nv×1
dv = dom.dv;

eps = para.eps;

% cached MD
if nargin >= 6 && isfield(cache,'MD') && ~isempty(cache.MD)
    MD = cache.MD;
else
    MD = build_neumann_minus_lap(Nx, dx);
end

%% ---------- build v-dependent vectors ----------
Psi   = func.psi(v);    Psi   = Psi(:);
Phi_c = func.phi_c(v);  Phi_c = Phi_c(:);
Phi_n = func.phi_n(v);  Phi_n = Phi_n(:);

% moments
if isfield(para,'D'),     D = para.D;     else, D = integration_v_meshgrid((v.^2).*Psi, dv); end
if isfield(para,'chi_c'), chi_c = para.chi_c; else, chi_c = integration_v_meshgrid(v.*Phi_c, dv); end
if isfield(para,'chi_n'), chi_n = para.chi_n; else, chi_n = integration_v_meshgrid(v.*Phi_n, dv); end

%% ---------- Neumann extension of rho,c,n ----------
rho_ex = [rho(1), rho, rho(end)];
c_ex   = [c(1),   c,   c(end)];
n_ex   = [n(1),   n,   n(end)];

%% ---------- half-grid derivatives ----------
drho_dx = diff(rho_ex) / dx;   % 1×(Nx+1)
dc_dx   = diff(c_ex)   / dx;
dn_dx   = diff(n_ex)   / dx;

uc = sign(dc_dx);   % 1×(Nx+1)
un = sign(dn_dx);

%% ---------- build upwind div matrices ----------
Mc = build_upwind_div_matrix(uc, dx);
Mn = build_upwind_div_matrix(un, dx);

%% ---------- compute rhoU on half grid ----------
rhoUc = compute_rhoU_half(rho, uc); % 1×(Nx+1)
rhoUn = compute_rhoU_half(rho, un);

%% ---------- compute G flux residual ----------
G_Flux_res = compute_Gflux_res(G, v, Psi, dx, dv);   % Nv×(Nx+1)

%% ===================== update tilde G =====================
a = dt / (eps^2 + dt);

drho_dx_row = reshape(drho_dx, 1, []);  % 1×(Nx+1)

tS_remained = -(v.*Psi) .* drho_dx_row ...
            + Phi_c .* rhoUc ...
            + Phi_n .* rhoUn;          % Nv×(Nx+1)

tG = (dt * (-G_Flux_res * eps + tS_remained) + G * eps^2) ./ (eps^2 + dt);

%% ===================== update rho (implicit) =====================
dGdx = (tG(:,2:end) - tG(:,1:end-1)) / dx;        % Nv×Nx
int_vdGdx = integration_v_meshgrid(v .* dGdx, dv);% 1×Nx

Lap_rho = MD * rho(:);
div_c   = Mc * rho(:);
div_n   = Mn * rho(:);

MAT_Rho = speye(Nx)/dt ...
        + a * D     * MD ...
        + a * chi_c * Mc ...
        + a * chi_n * Mn;

rhs = rho(:)/dt - int_vdGdx(:) ...
    + a * D     * Lap_rho ...
    + a * chi_c * div_c ...
    + a * chi_n * div_n;

Rho_new = (MAT_Rho \ rhs).';

%% ===================== update G (half grid) =====================
Rho_ex2  = [Rho_new(1), Rho_new, Rho_new(end)];
dRho_dx2 = diff(Rho_ex2) / dx;

rho_c = pick_upwind_half(rho_ex,  uc);
rho_n = pick_upwind_half(rho_ex,  un);
Rho_c = pick_upwind_half(Rho_ex2, uc);
Rho_n = pick_upwind_half(Rho_ex2, un);

G_new = tG + a * ( ...
    + Phi_c .* uc .* (Rho_c - rho_c) ...
    + Phi_n .* un .* (Rho_n - rho_n) ...
    - (v.*Psi) .* (dRho_dx2 - drho_dx_row) );

%% ===================== optional positivity limiter =====================
use_limiter = isfield(para,'use_limiter') && para.use_limiter;
if use_limiter
    [Rho_new, G_new] = apply_pos_limiter_f(Rho_new, G_new, Psi, eps, dv, dx);
end

%% ===================== update c (M) and n (N) if parameters exist =====================
C_new = c;
N_new = n;

do_M = isfield(para,'DM') && isfield(para,'alpha') && isfield(para,'beta');
if do_M
    DM    = para.DM;
    alpha = para.alpha;
    beta  = para.beta;

    MAT_M = speye(Nx)/dt + DM*MD + alpha*speye(Nx);
    rhs_M = c(:)/dt + beta * Rho_new(:);
    C_new = (MAT_M \ rhs_M).';
end

do_N = isfield(para,'DN') && isfield(para,'gamma');
if do_N
    DN    = para.DN;
    gamma = para.gamma;

    MAT_N = speye(Nx)/dt + DN*MD + gamma * spdiags(Rho_new(:), 0, Nx, Nx);
    rhs_N = n(:)/dt;
    N_new = (MAT_N \ rhs_N).';
end

%% ---------- pack back ----------
state.rho = Rho_new;
state.c   = C_new;
state.n   = N_new;
state.G   = G_new;

end

%% =======================================================================
%% ----------------------------- subfunctions ----------------------------
%% =======================================================================

function G_Flux_res = compute_Gflux_res(G, v, Psi, dx, dv)
% compute_Gflux_res
% Inputs:
%   G   : Nv×(Nx+1) on half grid
%   v   : Nv×1
%   Psi : Nv×1
% Output:
%   G_Flux_res : Nv×(Nx+1), (I - Pi)(v * d_x G) in your upwind form

v   = v(:);
Psi = Psi(:);

% ---- Step 1: upwind derivative in x for each v ----
% Neumann extension in x for G:
G_ex = [G(:,2), G, G(:, end-1)];  % Nv×(Nx+3)

% forward diff on extended grid: gives Nv×(Nx+2)
dG_dx_ex = (G_ex(:,2:end) - G_ex(:,1:end-1)) / dx;

% pick left/right slope depending on sign(v)
vp = max(v, 0);   % Nv×1
vn = min(v, 0);   % Nv×1 (<=0)

% dG_dx_ex(:,1:end-1) and (:,2:end) are Nv×(Nx+1)
G1_Flux = dG_dx_ex(:,1:end-1) .* vp + dG_dx_ex(:,2:end) .* vn;  % Nv×(Nx+1)

% ---- Step 2: projection onto span{Psi} ----
coeff = integration_v_meshgrid(G1_Flux, dv);        % 1×(Nx+1)
denom = integration_v_meshgrid(Psi, dv);            % scalar (since Psi is Nv×1)
G_Flux_proj = Psi * (coeff / denom);                % Nv×(Nx+1)

% ---- Step 3: residual ----
G_Flux_res = G1_Flux - G_Flux_proj;
end

function MD = build_neumann_minus_lap(Nx, dx)
e = ones(Nx,1);
MD = (1/dx^2) * spdiags([-e, 2*e, -e], [-1,0,1], Nx, Nx);
MD(1,1)     = MD(1,1)/2;
MD(end,end) = MD(end,end)/2;
end

function M = build_upwind_div_matrix(u_sign, dx)
Nx = numel(u_sign) - 1;
u_p = max(u_sign, 0);
u_n = -min(u_sign, 0);

c0  = u_n(1:end-1) + u_p(2:end);
c1  = [0, -u_n(2:end-1)];
c_1 = [-u_p(2:end-1), 0];

M = (1/dx) * spdiags([c_1(:), c0(:), c1(:)], [-1,0,1], Nx, Nx);
end

function rhoU = compute_rhoU_half(rho_center, u_sign)
u_p = max(u_sign, 0);
u_n = -min(u_sign, 0);

rho_l = rho_center(1:end-1);
rho_r = rho_center(2:end);

rhoU_in = u_p(2:end-1).*rho_l - u_n(2:end-1).*rho_r;
rhoU = [0, rhoU_in, 0];
end

function val_half = pick_upwind_half(q_ex, u_sign)
val_half = q_ex(1:end-1).*(u_sign>0) + q_ex(2:end).*(u_sign<=0);
end

function [Rho_new, G_half_new] = apply_pos_limiter_f(Rho, G_half, Psi, eps, dv, dx)
% Positivity limiter on F = Psi*rho + eps*g(center) and reconstruct.
Nx = numel(Rho);

mass_original = sum(Rho) * dx;

% half -> center
G_center = 0.5*(G_half(:,1:end-1) + G_half(:,2:end)); % Nv×Nx

% provisional F
F_tilde = Psi * Rho + eps * G_center;                 % Nv×Nx
rho_bar = integration_v_meshgrid(F_tilde, dv);        % 1×Nx

F_star = F_tilde;

for j = 1:Nx
    rhoj = rho_bar(j);
    if rhoj <= 0
        F_star(:,j) = 0;
        continue;
    end

    Fj   = F_tilde(:,j);
    F_eq = rhoj * Psi;      % Nv×1
    m_j  = min(Fj);

    if m_j < 0
        denom = min(F_eq) - m_j;
        if denom <= 0
            theta = 0;
        else
            theta = min(1.0, min(F_eq) / (denom + 1e-14));
        end
        F_star(:,j) = F_eq + theta*(Fj - F_eq);
        F_star(:,j) = max(F_star(:,j), 0);
    end
end

% global mass rescale
rho_star  = integration_v_meshgrid(F_star, dv);
mass_star = sum(rho_star) * dx;
alpha = (mass_star > 0) * (mass_original/mass_star) + (mass_star <= 0) * 1.0;

F_new = alpha * F_star;

% recover rho and g(center)
Rho_new = integration_v_meshgrid(F_new, dv);
G_center_new = (F_new - Psi * Rho_new) / eps;

% center -> half with Neumann extension
G_ext = [G_center_new(:,1), G_center_new, G_center_new(:,end)]; % Nv×(Nx+2)
G_half_new = 0.5*(G_ext(:,1:end-1) + G_ext(:,2:end));          % Nv×(Nx+1)
end

function int_F = integration_v_meshgrid(F, dv)

% 确保第一维是 Nv
if size(F,1) < size(F,2) && isvector(F)
    F = F(:);
end

int_F = dv * ( ...
      0.5 * (F(1,:) + F(end,:)) ...
    + sum(F(2:end-1,:), 1) );

end