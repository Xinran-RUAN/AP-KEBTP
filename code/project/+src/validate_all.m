function [para, func] = validate_all(para, dom, func)
% src/+cfg/validate_all.m

v  = dom.v(:);
dv = dom.dv;

% ---- normalize psi: ∫ psi dv = 1 ----
psi_v = func.psi(v);
I0 = trapz(v, psi_v);
if I0 <= 0
    error('psi integral is non-positive.');
end
func.psi = @(vv) func.psi(vv) / I0;  % 归一化后的 psi
psi_v = psi_v / I0;

% ---- compute D = ∫ v^2 psi dv ----
para.D = trapz(v, (v.^2) .* psi_v);

% ---- check phi moment: ∫ v phi(v) dv ≈ chi ----
Ic = trapz(v, v .* func.phi_c(v));
In = trapz(v, v .* func.phi_n(v));

fprintf('[validate] int psi dv = %.6g (should be 1)\n', trapz(v, func.psi(v)));
fprintf('[validate] D = int v^2 psi dv = %.6g\n', para.D);
fprintf('[validate] int v phi_c dv = %.6g (target chi_c=%.6g)\n', Ic, para.chi_c);
fprintf('[validate] int v phi_n dv = %.6g (target chi_n=%.6g)\n', In, para.chi_n);

% 可选：误差过大直接报错
tol = 5e-3;
if abs(Ic-para.chi_c) > tol*max(1,abs(para.chi_c))
    warning('phi_c moment mismatch is relatively large.');
end
if abs(In-para.chi_n) > tol*max(1,abs(para.chi_n))
    warning('phi_n moment mismatch is relatively large.');
end

end