function path_out = resolve_project_path(path_in)
%RESOLVE_PROJECT_PATH Convert a project-relative path to an absolute path.
% Absolute paths are returned unchanged. Relative paths are interpreted
% relative to the project root, not relative to the current MATLAB folder.
if nargin < 1 || isempty(path_in)
    path_out = path_in;
    return;
end

if isstring(path_in)
    if ~isscalar(path_in)
        error('utils:resolve_project_path:InvalidPath', ...
            'Path must be a scalar string or char vector.');
    end
    path_in = char(path_in);
end

if ~ischar(path_in)
    error('utils:resolve_project_path:InvalidPath', ...
        'Path must be a scalar string or char vector.');
end

if is_absolute_path(path_in)
    path_out = path_in;
else
    path_out = fullfile(utils.project_root(), path_in);
end
end

function tf = is_absolute_path(p)
%IS_ABSOLUTE_PATH True for Unix, Windows drive, UNC, and home paths.
if isempty(p)
    tf = false;
    return;
end

% Treat a leading ~ as absolute-like. MATLAB file operations can expand it
% on supported platforms; in any case we should not prepend the project root.
if p(1) == '~'
    tf = true;
    return;
end

if ispc
    has_drive = numel(p) >= 3 && isletter(p(1)) && p(2) == ':' && ...
        (p(3) == '/' || p(3) == char(92));
    has_unc = numel(p) >= 2 && ...
        ((p(1) == char(92) && p(2) == char(92)) || (p(1) == '/' && p(2) == '/'));
    tf = has_drive || has_unc;
else
    tf = p(1) == '/';
end
end
