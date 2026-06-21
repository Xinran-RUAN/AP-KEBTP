function tag = num_to_tag(a)
%NUM_TO_TAG Convert a number into a filename-safe short tag.
% Examples: 0.25 -> 0p25, 1e-3 -> 1em03, -2 -> m2.
if ~isscalar(a) || ~isnumeric(a) || ~isfinite(a)
    error('utils:num_to_tag:InvalidNumber', 'Input must be one finite numeric scalar.');
end

if a == 0
    tag = '0';
    return;
end

absa = abs(a);
if absa >= 1e-3 && absa < 1e4
    tag = sprintf('%.12g', a);
else
    tag = sprintf('%.6e', a);
end

tag = strrep(tag, '+', '');
tag = strrep(tag, '-', 'm');
tag = strrep(tag, '.', 'p');
tag = strrep(tag, 'e', 'e');
end
