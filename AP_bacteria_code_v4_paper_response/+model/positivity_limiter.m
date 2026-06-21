function [rho_new, g_edge_new] = positivity_limiter(rho, g_edge, grid, p)
%POSITIVITY_LIMITER Zhang--Shu style limiter for f = rho/|V| + eps*g.
V = grid.V; w = grid.w; epsv = p.eps;
Nx = grid.Nx;
mass0 = sum(rho)*grid.dx;
gc = 0.5*(g_edge(:,1:end-1) + g_edge(:,2:end));
F = ones(grid.Nv,1)*(rho/V) + epsv*gc;
Fstar = F;
for j = 1:Nx
    rhoj = utils.vint(F(:,j), w);
    feq = rhoj/V;
    mj = min(F(:,j));
    if rhoj > 0 && mj < 0
        theta = min(1, feq/(feq - mj));
        Fstar(:,j) = feq + theta*(F(:,j)-feq);
        Fstar(:,j) = max(Fstar(:,j),0);
    elseif rhoj <= 0
        Fstar(:,j) = 0;
    end
end
rho_star = utils.vint(Fstar, w);
mass_star = sum(rho_star)*grid.dx;
if mass_star > 0
    Fstar = (mass0/mass_star)*Fstar;
end
rho_new = utils.vint(Fstar, w);
gc_new = (Fstar - ones(grid.Nv,1)*(rho_new/V))/epsv;
gc_ex = [gc_new(:,1), gc_new, gc_new(:,end)];
g_edge_new = 0.5*(gc_ex(:,1:end-1) + gc_ex(:,2:end));
% remove tiny residual velocity mean on interfaces
mean_g = utils.vint(g_edge_new, w)/V;
g_edge_new = g_edge_new - ones(grid.Nv,1)*mean_g;
end
