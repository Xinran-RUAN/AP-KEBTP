function export_figure2_data
% Migration helper: retain the existing, verified legacy scan without rerunning it.
here=startup_paper;repo=fileparts(here);names={'travelling_speed_analytic','travelling_speed_numeric_macro','travelling_speed_numeric_kinetic'};
legacy=struct([]);
for j=1:3
 f=load(fullfile(here,'templates',[names{j} '.fig']),'-mat','hgS_070000');nodes=surface_nodes(f.hgS_070000);assert(numel(nodes)==1);p=nodes{1}.properties;
 legacy(j).name=names{j};legacy(j).x=p.XData;legacy(j).y=p.YData;legacy(j).z=p.ZData;legacy(j).speed=p.CData;
end
metadata=jsondecode(fileread(fullfile(repo,'paper_data/figure2/parameters.json')));
save(fullfile(repo,'paper_data/figure2/legacy_speed_scan.mat'),'legacy','metadata','-v7');
fprintf('LEGACY_FIGURE2_DATA_EXPORTED\n');
end
function out=surface_nodes(s)
out={};if isstruct(s),for j=1:numel(s),if isfield(s,'type')&&contains(s(j).type,'surface'),out{end+1}=s(j);end;if isfield(s,'children'),out=[out surface_nodes(s(j).children)];end,end,end
end
