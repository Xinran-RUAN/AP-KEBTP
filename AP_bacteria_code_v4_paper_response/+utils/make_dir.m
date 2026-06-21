function make_dir(d)
%MAKE_DIR Create a directory if it does not already exist.
% Relative paths are interpreted relative to the project root so that output
% folders are not accidentally created inside runs/ when a run script is
% launched from that folder.
if nargin < 1 || isempty(d)
    return;
end

if isstring(d)
    if ~isscalar(d)
        error('utils:make_dir:InvalidPath', ...
            'Directory path must be a scalar string or char vector.');
    end
    d = char(d);
end

if ~ischar(d)
    error('utils:make_dir:InvalidPath', ...
        'Directory path must be a scalar string or char vector.');
end

if isempty(strtrim(d))
    return;
end

d = utils.resolve_project_path(d);

if exist(d, 'dir')
    return;
end

[ok, msg, msgid] = mkdir(d);
if ~ok && ~exist(d, 'dir')
    if isempty(msgid)
        msgid = 'utils:make_dir:mkdirFailed';
    end
    error(msgid, 'Cannot create directory:\n%s\n%s', d, msg);
end
end
