function plot_paper_figures(data_root,output_dir)
%PLOT_PAPER_FIGURES Regenerate Figures 1--7 from saved data, never solve PDEs.
here=startup_paper;repo=fileparts(here);
if nargin<1,data_root=fullfile(repo,'paper_data');end
if nargin<2,output_dir=fullfile(repo,'paper_figures');end
if ~isfolder(output_dir),mkdir(output_dir);end
s=load(fullfile(data_root,'derived/plot_data.mat'));items=s.items;grid=s.refgrid;summary=s.summary;
mapping=jsondecode(fileread(fullfile(here,'config/curve_mapping.json')));
legacy=load(fullfile(repo,'paper_data/figure2/legacy_speed_scan.mat'));
names={'macro_compare_t_030p000','macro_compare_t_050p000','travelling_speed_analytic','travelling_speed_numeric_macro','travelling_speed_numeric_kinetic','AP_profiles','AP_error_T50','AP_speed_direct','exponential_pulse_evolution','exponential_two_limits'};
records=struct([]);
for fi=1:numel(names)
 name=names{fi};f=openfig(fullfile(here,'templates',[name '.fig']),'new','invisible');drawnow;
 before=style_signature(f);aa=ordered_axes(f);
 if fi<=2
  t=[30 50];v=pick(items,0,0);rho=v.rho(s.times==t(fi),:);
  [cs,cn]=src.effective_chi_macro(model_parameters(here),grid);sigma=src.analytic_speed_macro(cs,cn,2,.05);
  D=utils.vint(grid.v.^2,grid.w)/grid.V;[~,ip]=max(rho);z=grid.x-grid.x(ip);
  unit=exp((cs+cn-sigma)/D*min(z,0)+(cn-cs-sigma)/D*max(z,0));analytical=unit*sum(rho)/sum(unit);
  ll=findall(aa,'Type','line');assert(numel(ll)==2);
  for k=1:numel(ll)
   yy=rho;if strcmp(ll(k).DisplayName,'Analytical'),yy=analytical;else,assert(strcmp(ll(k).DisplayName,'Numerical'));end
   ll(k).XData=grid.x;ll(k).YData=yy;
  end
 elseif fi<=5
  sf=findall(f,'Type','surface');assert(numel(sf)==1);r=legacy.legacy(fi-2);
  sf.XData=r.x;sf.YData=r.y;sf.ZData=r.z;sf.CData=r.speed;
 else
  record=mapping(strcmp({mapping.name},name));assert(numel(record)==1);
  for m=record.mapping(:)'
   ll=findall(aa(m.panel),'Type','line');h=ll(m.line);assert(strcmp(h.DisplayName,m.display_name));
   if fi==7
    xx=h.XData;yy=arrayfun(@(e)summary.sign_L2(summary.sign_epsilon==e),xx);
    if ~strcmp(h.DisplayName,'numerical error')
     power=1;if contains(h.DisplayName,'^2'),power=2;end
     yy=summary.sign_L2(summary.sign_epsilon==max(xx))*(xx/max(xx)).^power;
    end
   elseif fi==8&&strcmp(m.case_id,'unchanged_analytical_prediction')
    continue;
   else
    v=items(strcmp({items.id},m.case_id));assert(numel(v)==1);
    if fi==8,xx=v.cm_t;yy=v.speed_curve;else,xx=grid.x;yy=v.rho(s.times==m.time,:);end
   end
   h.XData=xx;h.YData=yy;
  end
 end
 assert(same_style(before,style_signature(f)),'Template styling changed.');
 expected=curve_signature(f);base=fullfile(output_dir,name);
 f.PaperPositionMode='auto';print(f,[base '.eps'],'-depsc','-painters','-loose');
 print(f,[base '.png'],'-dpng','-r150');f.Visible='on';savefig(f,[base '.fig']);close(f);
 old=get(groot,'defaultFigureVisible');set(groot,'defaultFigureVisible','on');v=openfig([base '.fig'],'new');
 assert(strcmp(v.Visible,'on')&&same_style(before,style_signature(v))&&isequaln(expected,curve_signature(v)),'Native FIG verification failed.');
 if fi>5,assert(isempty(findall(v,'Type','image')));end
 record=struct('name',name,'native_visible_editable_fig',true,'exact_saved_curve_data',true,'style_preserved',true,'axes_count',numel(ordered_axes(v)),'line_count',numel(findall(v,'Type','line')),'surface_count',numel(findall(v,'Type','surface')));
 if isempty(records),records=record;else,records(end+1)=record;end
 close(v);set(groot,'defaultFigureVisible',old);
end
fid=fopen(fullfile(output_dir,'verification.json'),'w');fprintf(fid,'%s',jsonencode(records,'PrettyPrint',true));fclose(fid);
fprintf('ALL_TEN_PAPER_FIGURE_FILES_REGENERATED_AND_REOPENED\n');
end
function p=model_parameters(here)
s=load(fullfile(here,'config/baseline.mat'),'p');p=s.p;
end
function z=pick(items,a,e)
z=items([items.a]==a&[items.epsilon]==e);assert(numel(z)==1);
end
function aa=ordered_axes(f)
aa=findall(f,'Type','axes');[~,ii]=sort(arrayfun(@(a)a.Position(1),aa));aa=aa(ii);
end
function s=curve_signature(f)
s={};aa=ordered_axes(f);
for a=aa(:)',for h=findall(a,'Type','line')',s{end+1}=get(h,{'DisplayName','XData','YData'});end,end
for h=findall(f,'Type','surface')',s{end+1}=get(h,{'XData','YData','ZData','CData'});end
end
function ok=same_style(a,b)
for j=1:numel(a.legends)
 if max(abs(a.legends{j}{2}-b.legends{j}{2}))>1e-7,ok=false;return;end
 b.legends{j}{2}=a.legends{j}{2};
end
ok=isequaln(a,b);
end
function sig=style_signature(f)
ap={'Units','Position','FontName','FontSize','FontWeight','FontAngle','LineWidth','XLim','YLim','XTick','YTick','XTickLabel','YTickLabel','XScale','YScale','TickLabelInterpreter','XGrid','YGrid','GridColor','GridAlpha','GridLineStyle','Box'};
lp={'DisplayName','Tag','Color','LineStyle','LineWidth','Marker','MarkerSize','MarkerEdgeColor','MarkerFaceColor','HandleVisibility'};
tp={'String','Position','Units','FontName','FontSize','FontWeight','FontAngle','Color','Interpreter','BackgroundColor','EdgeColor','Margin','HorizontalAlignment','VerticalAlignment','Rotation'};
sig=struct('size',f.Position,'axes',{{}},'legends',{{}},'annotations',{{}});aa=ordered_axes(f);
for j=1:numel(aa),ll=findall(aa(j),'Type','line');tt=findall(aa(j),'Type','text');sig.axes{j}=struct('properties',{get(aa(j),ap)},'lines',{get(ll,lp)},'texts',{get(tt,tp)});end
lg=findall(f,'Type','legend');for j=1:numel(lg),sig.legends{j}=get(lg(j),{'String','Position','FontName','FontSize','Interpreter','Orientation','NumColumns','Box','Location'});end
for j=1:2,t=findall(f,'Tag',sprintf('panel_label_%d',j));if ~isempty(t),sig.annotations{j}=get(t,{'String','Position','FontSize','FontWeight','Interpreter'});end,end
end
