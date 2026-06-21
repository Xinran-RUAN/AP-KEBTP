function mk = moment_v(v, f, k)
% src/+utils/moment_v.m
% mk = ∫ v^k f(v) dv  (trapz)
v = v(:);
if isrow(f), f = f(:); end
mk = trapz(v, (v.^k) .* f);
end