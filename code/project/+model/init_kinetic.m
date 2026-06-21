function state = init_kinetic(dom, para, func)
% src/+init/init_kinetic.m

x  = dom.x;
Nx = dom.Nx;
Nv = dom.Nv;

state = struct();
state.t   = 0;

state.rho = exp(-abs(x));
state.c   = zeros(1, Nx);
state.n   = 1e3 * ones(1, Nx);

% 你原来是 Nv x (Nx+1)
state.G   = zeros(Nv, Nx+1);

end
