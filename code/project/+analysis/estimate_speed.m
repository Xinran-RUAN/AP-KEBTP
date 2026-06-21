function speed = estimate_speed(t_list, x_mass, opts)

if nargin < 3
    opts.tailN = 6;
end

t = t_list(:);
x = x_mass(:);

idx = isfinite(t) & isfinite(x);
t = t(idx); 
x = x(idx);

if numel(t) < 3
    speed = NaN;
    return;
end

N = numel(t);
tailN = min(opts.tailN, N-1);

dx = diff(x);
dt = diff(t);
v  = dx ./ dt;

speed = mean(v(end-tailN+1:end));

end