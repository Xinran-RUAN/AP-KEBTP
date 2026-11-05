function root=startup_paper
%STARTUP_PAPER Select the single production solver used by the latest paper.
root=fileparts(mfilename('fullpath'));addpath(root,'-begin');addpath(fullfile(root,'tests'));
assert(strcmp(which('model.positivity_limiter'),fullfile(root,'+model/positivity_limiter.m')),'Another package shadows the paper solver.');
end
