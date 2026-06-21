function [rho_an, info] = analytic_profile_macro(grid, rho_ref, p, x_peak, normalization)
%ANALYTIC_PROFILE_MACRO Analytical travelling-pulse density for the macro limit.
%
% Travelling coordinate: z = x - x_peak.
%
%   rho(z) = rho0 * exp(lambda_left*z),   z <= 0,
%   rho(z) = rho0 * exp(lambda_right*z),  z >= 0,
%
% with lambda_left > 0 and lambda_right < 0.  Since z<0 on the left, this
% decays to the left.  This is the sign convention that produces the fitted
% pulse in the manuscript figure.
%
% The analytical formula assumes the normalized sign response, i.e.
% uS=chiS_eff*sign(S_x), uN=chiN_eff*sign(N_x).  The effective chi values are
% computed from the actual velocity quadrature and phi normalization.

if nargin < 4 || isempty(x_peak)
    [~, ip] = max(rho_ref);
    x_peak = grid.x(ip);
end
if nargin < 5 || isempty(normalization)
    normalization = 'mass';
end

D = utils.vint(grid.v.^2, grid.w) / grid.V;
[chiS_eff, chiN_eff, chi_info] = src.effective_chi_macro(p, grid);
sigma = src.analytic_speed_macro(chiS_eff, chiN_eff, p.DS, p.alpha);

lambda_left  = (chiS_eff + chiN_eff - sigma) / D;
lambda_right = (chiN_eff - chiS_eff - sigma) / D;

if ~isfinite(sigma) || ~isfinite(lambda_left) || ~isfinite(lambda_right) || ...
        lambda_left <= 0 || lambda_right >= 0
    rho_an = nan(size(grid.x));
    info = struct('valid', false, 'reason', 'No admissible analytical pulse.', ...
        'D', D, 'sigma', sigma, 'lambda_left', lambda_left, ...
        'lambda_right', lambda_right, 'x_peak', x_peak, ...
        'normalization', normalization, 'amplitude', NaN, ...
        'mass_reference', NaN, 'mass_analytical', NaN, ...
        'chiS_eff', chiS_eff, 'chiN_eff', chiN_eff, ...
        'chi_info', chi_info);
    return;
end

z = grid.x - x_peak;
shape = exp(lambda_left*min(z,0) + lambda_right*max(z,0));

switch lower(normalization)
    case 'peak'
        amplitude = max(rho_ref);
    otherwise
        normalization = 'mass';
        mass_ref = grid.dx * sum(rho_ref);
        shape_mass = grid.dx * sum(shape);
        amplitude = mass_ref / max(shape_mass, eps);
end

rho_an = amplitude * shape;

info = struct();
info.valid = true;
info.reason = '';
info.D = D;
info.sigma = sigma;
info.lambda_left = lambda_left;
info.lambda_right = lambda_right;
info.x_peak = x_peak;
info.normalization = normalization;
info.amplitude = amplitude;
info.mass_reference = grid.dx * sum(rho_ref);
info.mass_analytical = grid.dx * sum(rho_an);
info.peak_reference = max(rho_ref);
info.peak_analytical = max(rho_an);
info.chiS_eff = chiS_eff;
info.chiN_eff = chiN_eff;
info.chi_info = chi_info;
end
