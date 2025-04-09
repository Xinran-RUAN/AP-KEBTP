function G_Flux_res = Compute_G_Flux_res(G, v, Psi, dx, dv)
% Compute_G_Flux_res
% ----------------------------
% Inputs:
%   G    - [Nv × Nx+1] matrix, kinetic variable
%   v    - [Nv × 1] or row vector, velocity grid (assumed constant over x)
%   Psi  - [Nv × 1] or row vector, basis function Psi(v)
%   dx   - spatial step size
%   dv   - velocity step size
%
% Output:
%   G_Flux_res - [Nv × Nx+1] matrix, (I - Pi)(∂x(vG))

%% Step 1: conservative centered difference on v * G
% vG = v(:) .* G;                         % ensure column v, shape: [Nv × Nx+1]
% vG_ex = [vG(:,2), vG, vG(:,end-1)];       % Neumann extension: [Nv × Nx+3]
% G1_Flux = (vG_ex(:,3:end) - vG_ex(:,1:end-2)) / (2 * dx);  % [Nv × Nx+1]

%% Step 1 (Alternative)
G_ex = [G(:,2), G, G(:, end-1)];
dG_dx_ex = (G_ex(:, 2:end) - G_ex(:, 1:end-1)) / dx;   % 0,1,...,N+1
G1_Flux = dG_dx_ex(:, 1:end-1) .* max(v', 0) ...
        + dG_dx_ex(:, 2:end) .* min(v', 0); % 1/2,...,N+1/2

%% Step 2: project G1_Flux onto span{Psi}
% 归一化：保证关于v的积分相同
coeff = integration_v_meshgrid(G1_Flux, dv);   % [1 × Nx+1]
G_Flux_proj = Psi * coeff / integration_v_meshgrid(Psi, dv);            % [Nv × Nx+1]

%% Step 3: compute residual
G_Flux_res = G1_Flux - G_Flux_proj;
end
