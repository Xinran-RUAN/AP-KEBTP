function finish_matlab_checks
here=startup_paper;repo=fileparts(here);
assert(isfile(fullfile(here,'config/baseline.mat')));
names={'macro_compare_t_030p000','macro_compare_t_050p000','travelling_speed_analytic','travelling_speed_numeric_macro','travelling_speed_numeric_kinetic','AP_profiles','AP_error_T50','AP_speed_direct','exponential_pulse_evolution','exponential_two_limits'};
rows=struct([]);
for j=1:numel(names)
 old=load(fullfile(here,'templates',[names{j} '.fig']),'-mat','hgS_070000');new=load(fullfile(repo,'paper_figures',[names{j} '.fig']),'-mat','hgS_070000');a=curves(old.hgS_070000);b=curves(new.hgS_070000);assert(numel(a)==numel(b));md=0;
 for k=1:numel(a)
  assert(strcmp(a{k}.type,b{k}.type));pa=a{k}.properties;pb=b{k}.properties;
  fields={'XData','YData'};if contains(a{k}.type,'surface'),fields=[fields {'ZData','CData'}];end
  for field=fields
   x=pa.(field{1});y=pb.(field{1});assert(isequal(size(x),size(y)));d=max(abs(x(:)-y(:)),[],'omitnan');if ~isempty(d),md=max(md,d);end
   assert(isequal(isnan(x),isnan(y))&&all(abs(x(isfinite(x))-y(isfinite(y)))<1e-13));
  end
 end
 row=struct('name',names{j},'object_count',numel(a),'max_data_difference',md);if isempty(rows),rows=row;else,rows(end+1)=row;end
end
cases=jsondecode(fileread(fullfile(here,'config/cases.json')));for c=cases(:)',assert(run_paper_case(c.id));end
f=fopen(fullfile(repo,'analysis/final_package_20261105/curve_equivalence.json'),'w');fprintf(f,'%s',jsonencode(rows,'PrettyPrint',true));fclose(f);fprintf('ALL_CURRENT_TEMPLATE_DATA_MATCH_AND_14_CACHES_ACCEPTED\n');
end
function out=curves(s)
out={};if isstruct(s),for j=1:numel(s),if isfield(s,'type')&&(contains(s(j).type,'surface')||strcmp(s(j).type,'graph2d.lineseries')||strcmp(s(j).type,'line')),out{end+1}=s(j);end;if isfield(s,'children'),out=[out curves(s(j).children)];end,end,end
end
