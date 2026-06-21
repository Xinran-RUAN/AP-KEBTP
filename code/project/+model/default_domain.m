function dom = default_domain()
% src/+cfg/default_domain.m

dom = struct();

% ---- x grid (half points) ----
dom.dx    = 1e-1;
dom.x_min = 0   + dom.dx/2;
dom.x_max = 150 - dom.dx/2;
dom.Nx    = round((dom.x_max - dom.x_min)/dom.dx) + 1;
dom.x     = linspace(dom.x_min, dom.x_max, dom.Nx);

% ---- v grid ----
dom.v_min = -1;
dom.v_max =  1;
dom.dv    = 2e-2;
dom.Nv    = round((dom.v_max - dom.v_min)/dom.dv) + 1;
dom.v     = linspace(dom.v_min, dom.v_max, dom.Nv);

end