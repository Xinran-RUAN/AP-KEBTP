% startup_AP_bacteria.m
% Add folders for the AP bacteria travelling pulse code.
root = fileparts(mfilename('fullpath'));
addpath(root);
addpath(fullfile(root, 'runs'));
fprintf('AP bacteria code path added: %s\n', root);
