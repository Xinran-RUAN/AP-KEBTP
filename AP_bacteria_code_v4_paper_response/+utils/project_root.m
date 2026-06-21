function root_dir = project_root()
%PROJECT_ROOT Return the absolute root folder of this MATLAB project.
% The project root is the parent folder that contains +model, +src, +utils,
% +post, runs, and startup_AP_bacteria.m. This function does not depend on
% the current MATLAB folder.
this_file = mfilename('fullpath');
utils_dir = fileparts(this_file);
root_dir = fileparts(utils_dir);
end
