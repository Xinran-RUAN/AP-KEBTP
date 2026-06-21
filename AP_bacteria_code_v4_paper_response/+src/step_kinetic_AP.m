function Unew = step_kinetic_AP(U, grid, p)
%STEP_KINETIC_AP One step of the decoupled AP micro-macro scheme with exact decomposition of T=1+eps*psi.
rho = U.rho; S = U.S; N = U.N; g = U.g;
dt = p.dt; epsv = p.eps;

R = model.compute_response(rho, S, N, grid, p);
Mres = model.upwind_g_transport(g, grid);
nonlin = model.project_zero_mean(R.psi .* g, grid);
Kold = model.K_equilibrium(rho, R, grid);
lam = dt/(epsv^2 + dt);

gtilde = (epsv^2*g - epsv*dt*Mres + dt*Kold - epsv*dt*nonlin)/(epsv^2 + dt);

D = utils.vint(grid.v.^2, grid.w)/grid.V;
bS = R.BS/grid.V;
bN = R.BN/grid.V;
a = lam*D;
cS = lam*bS; cN = lam*bN;
% no-flux boundaries
cS([1,end]) = 0; cN([1,end]) = 0;

A = model.build_rho_matrix(grid, dt, a, cS, cN, R.uS, R.uN);
% known RHS
v_dgtilde = utils.vint(grid.v .* ((gtilde(:,2:end)-gtilde(:,1:end-1))/grid.dx), grid.w);
Fdiff_old = a * utils.grad_cell_to_edge(rho, grid.dx);
rhoS_old = model.upwind_rho_edges(rho, R.uS);
rhoN_old = model.upwind_rho_edges(rho, R.uN);
FoldS = cS .* rhoS_old; FoldN = cN .* rhoN_old;
rhs = rho(:)/dt - v_dgtilde(:) ...
    - model.div_flux_center(Fdiff_old, grid).' ...
    - model.div_flux_center(FoldS, grid).' ...
    - model.div_flux_center(FoldN, grid).';

rho_new = (A\rhs).';
Knew = model.K_equilibrium(rho_new, R, grid);
g_new = gtilde + lam*(Knew-Kold);

if p.use_limiter
    [rho_new, g_new] = model.positivity_limiter(rho_new, g_new, grid, p);
end

% Update chemicals. Use rho_new by default. This is slightly more stable for long runs.
rho_for_chem = rho;
if p.update_chem_with_new_rho
    rho_for_chem = rho_new;
end
[S_new,N_new] = src.step_chemicals(S, N, rho_for_chem, grid, p);

Unew = struct('rho',rho_new,'S',S_new,'N',N_new,'g',g_new,'t',U.t+dt);
end
