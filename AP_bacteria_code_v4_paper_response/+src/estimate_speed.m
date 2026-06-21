function s = estimate_speed(t, xcm)
t = t(:); xcm = xcm(:);
idx = isfinite(t) & isfinite(xcm);
t = t(idx); xcm = xcm(idx);
if numel(t) < 4
    s = NaN; return;
end
m = max(3, floor(numel(t)/3));
tt = t(end-m+1:end); xx = xcm(end-m+1:end);
p = polyfit(tt,xx,1);
s = p(1);
end
