function func = default_functions(para)
% src/+cfg/default_functions.m

func = struct();

% ---- psi(v) ----
% 这里只定义"形状"，归一化放到 validate_all 里做
func.psi = @(v) ones(size(v));

% ---- phi_c, phi_n ----
sigma = 0.1;
func.sigma_phi = sigma; % 记录一下，方便复现
func.phi_c = @(v) para.chi_c / sqrt(2*pi) / sigma^3 .* v .* exp(-v.*v/(2*sigma^2));
func.phi_n = @(v) para.chi_n / sqrt(2*pi) / sigma^3 .* v .* exp(-v.*v/(2*sigma^2));

end
