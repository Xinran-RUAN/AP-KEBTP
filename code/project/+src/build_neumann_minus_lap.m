function MD = build_neumann_minus_lap(Nx, dx)
a0 =  2 * ones(Nx,1);
a1 = -1 * ones(Nx,1);
MD = (1/dx^2) * spdiags([a1, a0, a1], [-1,0,1], Nx, Nx);
MD(1,1)     = MD(1,1)/2;
MD(end,end) = MD(end,end)/2;
end