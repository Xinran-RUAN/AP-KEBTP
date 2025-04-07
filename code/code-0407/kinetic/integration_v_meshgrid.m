% To compute \int_v F(v) dv
%   F = F(v) with v(1) = min(v) and v(end) = max(v)
function[int_F] = integration_v_meshgrid(F, dv)
int_F = sum(F(2:end-1, :), 1) * dv + 0.5 * (F(1, :) + F(end, :)) * dv;