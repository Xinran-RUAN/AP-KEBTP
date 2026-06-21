function xm = mass_center(x, rho)
% src/+diag/mass_center.m
m = sum(rho);
if m == 0
    xm = NaN;
else
    xm = sum(x .* rho) / m;
end
end