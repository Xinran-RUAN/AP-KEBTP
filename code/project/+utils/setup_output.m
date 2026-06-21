function out = setup_output(prefix)
% src/+io/setup_output.m

stamp = datestr(now, 'yyyymmdd_HHMMSS');
outdir = fullfile(pwd, '../data', sprintf('%s_%s', prefix, stamp));
if ~exist(outdir, 'dir')
    mkdir(outdir);
end

out = struct();
out.dir = outdir;
out.stamp = stamp;

end