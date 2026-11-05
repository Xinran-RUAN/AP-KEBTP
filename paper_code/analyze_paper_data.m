function analyze_paper_data(data_root)
here=fileparts(mfilename('fullpath'));repo=fileparts(here);addpath(here,'-begin');
if nargin<1,data_root=fullfile(repo,'paper_data');end
for folder={'derived','diagnostics'},if ~isfolder(fullfile(data_root,folder{1})),mkdir(fullfile(data_root,folder{1}));end,end
cases=jsondecode(fileread(fullfile(here,'config/cases.json')));times=[1 10 20 30 40 50];items=struct([]);rows=struct([]);refgrid=[];reference_params=[];initial=[];
for j=1:numel(cases)
 c=cases(j);file=fullfile(data_root,'cases',[c.id '.mat']);assert(isfile(file),['Incomplete case: ' c.id]);d=read_completed_case(file);o=d.out;
 assert(abs(o.U.t-50)<1e-7&&numel(o.snap)==501&&o.params.dx==.025&&o.params.dt==.001&&o.params.dv==.02);

 for snapshot=o.snap
  assert(all(isfinite([snapshot.rho snapshot.S snapshot.N])),'A saved density or chemical field is nonfinite.');
 end
 if isempty(refgrid),refgrid=o.grid;else,assert(isequal(refgrid,o.grid));end
 if isempty(reference_params),reference_params=o.params;initial=o.snap(1);end
 for key={'L','dx','dt','dv','DS','DN','alpha','beta','gamma','chiS','chiN','rho0_amp','rho0_lambda','S0','N0','normalize_phi_amplitude','phi_scale','use_limiter','update_chem_with_new_rho'}
  assert(isequal(o.params.(key{1}),reference_params.(key{1})),['Mixed physical setting: ' key{1}]);
 end
 assert(isequal(o.snap(1),initial)&&max(abs([o.snap.t]-(0:.1:50)))<1e-10&&o.params.response_eps==c.epsilon);
 if c.a>0,assert(strcmp(o.params.phi_type,'exp_sign')&&o.params.phi_alpha==c.a);else,assert(strcmp(o.params.phi_type,'sign'));end
 if strcmp(c.kind,'kinetic')
  assert(o.params.eps==c.epsilon&&d.stats.early_return_steps+d.stats.correction_steps==50000&&size(d.events,1)==d.stats.correction_steps);
  assert(isequal([d.micro.t],[0 1 10 20 30 40 50])&&isequal(d.micro(end).g,o.U.g));
  for state=d.micro,assert(isequal(size(state.g),[refgrid.Nv refgrid.Nx+1])&&all(isfinite(state.g),'all'));end
 end
 rhos=zeros(6,o.grid.Nx);for k=1:6,rhos(k,:)=o.snap(round(times(k)*10)+1).rho;end
 v=zeros(1,3);limits=[30 40;40 50;30 50];fitres=zeros(1,3);
 for k=1:3,m=o.cm_t>=limits(k,1)-1e-8&o.cm_t<=limits(k,2)+1e-8;q=polyfit(o.cm_t(m),o.cm_x(m),1);v(k)=q(1);fitres(k)=max(abs(o.cm_x(m)-polyval(q,o.cm_t(m))));end
 shape=shape_change(o.grid.x,rhos(4:6,:),o.grid.dx);
 it=struct('id',c.id,'kind',c.kind,'epsilon',c.epsilon,'a',c.a,'rho',rhos,'cm_t',o.cm_t,'cm_x',o.cm_x, ...
  'mass',arrayfun(@(s)sum(s.rho)*o.grid.dx,o.snap),'speed_curve',speed_curve(o),'speed_windows',v,'shape_relative_L2',shape,'stats',d.stats);
 items=append(items,it);row=d.stats;row.id=c.id;row.kind=c.kind;row.a=c.a;row.epsilon=c.epsilon;row.speed_30_40=v(1);row.speed_40_50=v(2);row.speed_30_50=v(3);row.speed_window_relative_difference=abs(v(1)-v(2))/max(abs(v(3)),realmin);row.fit_max_residual=fitres(3);row.shape_L2_30_50=shape(1);row.shape_L2_40_50=shape(2);rows=append(rows,row);
end
signmacro=items(strcmp({items.id},'sign_macro'));exmacro=items(strcmp({items.id},'exp_a0p001_macro'));epsv=sort([cases([cases.a]==0&strcmp({cases.kind},'kinetic')).epsilon],'descend');errors=zeros(size(epsv));
for j=1:numel(items)
 macro=signmacro;
 if items(j).a>0
  if items(j).a==.001,macro=exmacro;else,rows(j).L2_to_corresponding_macro=NaN;continue;end
 end
 rows(j).L2_to_corresponding_macro=sqrt(refgrid.dx*sum((items(j).rho(end,:)-macro.rho(end,:)).^2));
 if items(j).a==0&&strcmp(items(j).kind,'kinetic'),errors(epsv==items(j).epsilon)=rows(j).L2_to_corresponding_macro;end
end
sign01=items([items.a]==0&[items.epsilon]==.01);av=[.001 .0005 .0001 0];waves=struct([]);
for j=1:4
 z=items([items.a]==av(j)&[items.epsilon]==.01);err=sqrt(refgrid.dx*sum((z.rho(end,:)-sign01.rho(end,:)).^2));
 waves=append(waves,struct('a',av(j),'speed',z.speed_windows(3),'speed_30_40',z.speed_windows(1),'speed_40_50',z.speed_windows(2),'L2_to_sign',err,'shape_L2_30_50',z.shape_relative_L2(1),'shape_L2_40_50',z.shape_relative_L2(2)));
end
ap=zeros(1,3);for j=1:3,e=[.1 .05 .01];z=items([items.a]==.001&[items.epsilon]==e(j));ap(j)=sqrt(refgrid.dx*sum((z.rho(end,:)-exmacro.rho(end,:)).^2));end
% Independent cross-figure check against the unchanged Figure1 raw snapshots.
cross=struct([]);
for t=[30 50]
 old=load(fullfile(repo,'paper_data/figure1',sprintf('macro_t_%03dp000.mat',t)));new=signmacro.rho(times==t,:);
 assert(isequal(old.x(:),refgrid.x(:)));delta=new(:)-old.rho(:);
 cross=append(cross,struct('time',t,'density_bitwise_equal',isequal(new(:),old.rho(:)),'max_density_difference',norm(delta,Inf),'L2_density_difference',sqrt(refgrid.dx*sum(delta.^2)), ...
  'new_peak',max(new),'old_peak',max(old.rho),'new_mass',sum(new)*refgrid.dx,'old_mass',sum(old.rho)*old.grid.dx));
end
summary=struct('rows',rows,'sign_epsilon',epsv,'sign_L2',errors,'sign_error_monotone',all(diff(errors)<=0),'exponential_AP_epsilon',[.1 .05 .01],'exponential_AP_L2',ap,'exponential_AP_monotone',all(diff(ap)<=0), ...
 'wave_rows',waves,'a_density_error_monotone',all(diff([waves.L2_to_sign])<=0),'a_speed_monotone',all(diff(abs([waves.speed]-waves(end).speed))<=0),'Figure1_crosscheck',cross,'sigma_pred',src.analytic_speed_macro(.5,1.1,2,.05));
displayed=zeros(6,3);for j=1:3,e=[.1 .05 .01];z=items([items.a]==0&[items.epsilon]==e(j));displayed(:,j)=sqrt(refgrid.dx*sum((z.rho-signmacro.rho).^2,2));end
summary.Figure3_L2_by_time=displayed;summary.Figure3_errors_monotone=all(diff(displayed,1,2)<=0,'all');
save(fullfile(data_root,'derived/plot_data.mat'),'items','times','refgrid','summary','-v7.3');writejson(fullfile(data_root,'derived/summary.json'),summary);writetable(struct2table(rows),fullfile(data_root,'diagnostics/case_diagnostics.csv'));
f=fopen(fullfile(data_root,'derived/wave_speed_full_precision.csv'),'w');fprintf(f,'a,numerical_propagation_speed,L2_density_to_sign\n');for j=1:4,fprintf(f,'%.17g,%.17g,%.17g\n',waves(j).a,waves(j).speed,waves(j).L2_to_sign);end;fclose(f);
fprintf('ALL_NEW_DATA_ANALYZED sign_monotone=%d exp_AP_monotone=%d a_monotone=%d\n',summary.sign_error_monotone,summary.exponential_AP_monotone,summary.a_density_error_monotone);
end
function s=speed_curve(o)
t=o.cm_t(:);x=o.cm_x(:);[t,ia]=unique(t,'stable');x=x(ia);tp=(0:.1:50).';xp=interp1(t,x,tp,'pchip',NaN);s=nan(size(tp));
for k=1:numel(tp),m=abs(tp-tp(k))<=.5&isfinite(xp);if sum(m)>=2,q=polyfit(tp(m),xp(m),1);s(k)=q(1);end,end
end
function shape=shape_change(x,rho,dx)
cm=sum(rho.*x,2)./sum(rho,2);origin=x(1)-cm(3);lo=floor((min(x(1)-dx-cm)-origin)/dx);hi=ceil((max(x(end)+dx-cm)-origin)/dx);z=origin+(lo:hi)*dx;rr=zeros(3,numel(z));
for j=1:3,rr(j,:)=interp1([x(1)-dx x x(end)+dx]-cm(j),[0 rho(j,:) 0],z,'linear',0);end
rr(3,:)=0;rr(3,1-lo:(1-lo)+numel(x)-1)=rho(3,:);shape=sqrt(sum((rr-rr(3,:)).^2,2)/sum(rr(3,:).^2)).';
end
function a=append(a,r),if isempty(a),a=r;else,a(end+1)=r;end,end
function writejson(p,v),f=fopen(p,'w');fprintf(f,'%s',jsonencode(v,'PrettyPrint',true));fclose(f);end
