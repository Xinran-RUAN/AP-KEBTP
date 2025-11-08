% To compute \int_v F(v) dv
%   F = F(v) with v(1) = min(v) and v(end) = max(v)
function[int_F] = integration_v_meshgrid(F, dv)
%% Trapezoid rule
int_F = sum(F(2:end-1, :), 1) * dv + 0.5 * (F(1, :) + F(end, :)) * dv;
%% Simpson rule
% % F: [Nv × Nx], Nv must be odd
% Nv = size(F,1);
% assert(mod(Nv,2)==1, 'Simpson rule requires odd number of points.');
% 
% w = ones(Nv,1);
% w(2:2:end-1) = 4;   % odd indices
% w(3:2:end-2) = 2;   % even indices
% int_F = (dv/3) * (w' * F);