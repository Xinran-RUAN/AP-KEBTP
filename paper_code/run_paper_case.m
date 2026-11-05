function ok=run_paper_case(case_id,data_root)
here=fileparts(mfilename('fullpath'));repo=fileparts(here);code=here;addpath(code,'-begin');
if nargin<2,data_root=fullfile(repo,'paper_data');end
for folder={'cases','logs','failures'},if ~isfolder(fullfile(data_root,folder{1})),mkdir(fullfile(data_root,folder{1}));end,end
assert(strcmp(which('src.step_kinetic_AP'),fullfile(code,'+src/step_kinetic_AP.m'))&&strcmp(which('model.positivity_limiter'),fullfile(code,'+model/positivity_limiter.m')));
cases=jsondecode(fileread(fullfile(here,'config/cases.json')));c=cases(strcmp({cases.id},case_id));assert(numel(c)==1);
ref=load(fullfile(here,'config/baseline.mat'));p=ref.p;p.Tfinal=50;p.output_times=0:.1:50;p.verbose=false;p.report_dt=1;p.save_snapshots_to_disk=false;p.use_limiter=true;
p.phi_type='sign';if c.a>0,p.phi_type='exp_sign';p.phi_alpha=c.a;end
p.response_eps=c.epsilon;if strcmp(c.kind,'kinetic'),p.eps=c.epsilon;end
grid=model.make_grid(p);assert(isequal(grid,ref.g));provenance=fileread(fullfile(here,'config/source_manifest.json'));
settings=struct('case',c,'p',p,'version',version,'computer',computer,'Nx',grid.Nx,'Nv',grid.Nv);
finalfile=fullfile(data_root,'cases',[case_id '.mat']);checkpoint=fullfile(data_root,'cases',[case_id '_checkpoint.mat']);
if isfile(finalfile)
 z=read_completed_case(finalfile);assert(isequal(z.settings.p,p)&&isequal(z.out.grid,grid)&&abs(z.out.U.t-50)<1e-7);ok=true;fprintf('COMPLETE_ALREADY %s\n',case_id);return;
end
U=model.initial_data(grid,p);if strcmp(c.kind,'macro'),U.g=[];end;M0=sum(U.rho)*grid.dx;
stats=struct('mass_initial',M0,'mass_final',M0,'max_relative_mass_drift',0,'min_rho',min(U.rho),'min_final_f',min(U.rho)/grid.V,'min_scaled_final_f',1, ...
 'max_boundary_flux',0,'max_raw_Jtilde_boundary',0,'max_zero_mean',0,'max_scaled_zero_mean',0,'max_mass_residual',0,'max_limiter_mass_change',0,'max_used_boundary_flux',0, ...
 'early_return_steps',0,'correction_steps',0,'theta_steps',0,'theta_cells',0,'theta_min',1,'eta_steps',0,'eta_edges',0,'eta_min',1,'negative_density_cells',0,'seconds',0);
snap=struct('t',0,'rho',U.rho,'S',U.S,'N',U.N,'mass',M0);micro=struct('t',{},'g',{});if ~isempty(U.g),micro(1)=struct('t',0,'g',U.g);end
history=zeros(501,13);history(1,:)=[0 M0 M0 M0 0 0 0 0 0 0 0 0 1];events=zeros(50000,11);nevents=0;n0=0;elapsed_prior=0;
if isfile(checkpoint)
 z=load(checkpoint);assert(isequal(z.settings,settings)&&strcmp(z.provenance,provenance));U=z.U;stats=z.stats;snap=z.snap;micro=z.micro;history=z.history;events=z.events;nevents=z.nevents;n0=z.n0;elapsed_prior=z.elapsed_prior;
 fprintf('RESUME %s t=%g\n',case_id,U.t);
end
timer=tic;fprintf('FORMAL_START %s Nx=%d Nv=%d dx=%.8g dt=%.8g MATLAB=%s\n',case_id,grid.Nx,grid.Nv,p.dx,p.dt,version);ok=false;
try
 for n=n0+1:round(p.Tfinal/p.dt)
  U_before=U;
  if strcmp(c.kind,'kinetic')
   [candidate,d]=src.step_kinetic_AP(U,grid,p);
   F=candidate.rho/grid.V+.5*p.eps*(candidate.g(:,1:end-1)+candidate.g(:,2:end));
   scale=abs(candidate.rho/grid.V)+.5*p.eps*(abs(candidate.g(:,1:end-1))+abs(candidate.g(:,2:end)));
   scaled=min(F./max(scale,realmin),[],'all');assert(all(isfinite(F(:)))&&scaled>=-512*eps,'Final reconstructed distribution failed positivity.');
   means=utils.vint(candidate.g,grid.w);mscale=utils.vint(abs(candidate.g),grid.w);rscale=max([candidate.rho(1),candidate.rho],[candidate.rho,candidate.rho(end)])/p.eps;
   scaledmean=max(abs(means)./max(mscale+rscale,realmin));assert(scaledmean<=512*eps,'Zero velocity mean failed.');
   J=utils.vint(grid.v.*candidate.g,grid.w);z=d.limiter;
   stats.min_final_f=min(stats.min_final_f,min(F,[],'all'));stats.min_scaled_final_f=min(stats.min_scaled_final_f,scaled);
   stats.max_zero_mean=max(stats.max_zero_mean,max(abs(means)));stats.max_scaled_zero_mean=max(stats.max_scaled_zero_mean,scaledmean);
   stats.max_boundary_flux=max(stats.max_boundary_flux,max(abs(J([1 end]))));stats.max_raw_Jtilde_boundary=max(stats.max_raw_Jtilde_boundary,max(abs(d.Jtilde_raw_boundary)));
   stats.max_used_boundary_flux=max(stats.max_used_boundary_flux,max(abs(d.Jused_boundary)));stats.max_limiter_mass_change=max(stats.max_limiter_mass_change,abs(d.limiter_mass_change));
   stats.early_return_steps=stats.early_return_steps+z.early_return;stats.correction_steps=stats.correction_steps+z.correction_applied;
   stats.theta_steps=stats.theta_steps+(z.theta_cells>0);stats.theta_cells=stats.theta_cells+z.theta_cells;stats.theta_min=min(stats.theta_min,z.theta_min);
   stats.eta_steps=stats.eta_steps+z.eta_triggered;stats.eta_edges=stats.eta_edges+z.eta_edges;stats.eta_min=min(stats.eta_min,z.eta_min);stats.negative_density_cells=stats.negative_density_cells+z.negative_density_cells;
   if z.correction_applied
    nevents=nevents+1;events(nevents,:)=[n*p.dt z.min_f_before_eta min(candidate.rho) z.theta_cells z.theta_min z.mass_scale z.eta_triggered z.eta_edges z.eta_min d.limiter_mass_change scaled];
   end
  else
   candidate=src.step_macro(U,grid,p);d=struct('mass_before',sum(U.rho)*grid.dx,'mass_after_density',sum(candidate.rho)*grid.dx,'mass_residual',sum(candidate.rho-U.rho)*grid.dx,'limiter_mass_change',0,'Jtilde_raw_boundary',[0 0]);
  end
  assert(all(isfinite(candidate.rho))&&all(candidate.rho>=0),'Final density failed positivity.');
  U=candidate;M=sum(U.rho)*grid.dx;stats.min_rho=min(stats.min_rho,min(U.rho));stats.max_relative_mass_drift=max(stats.max_relative_mass_drift,abs(M-M0)/M0);stats.max_mass_residual=max(stats.max_mass_residual,abs(d.mass_residual));
  assert(stats.max_relative_mass_drift<1e-9,'Mass drift threshold exceeded.');
  if mod(n,100)==0
   k=n/100+1;snap(k)=struct('t',n*p.dt,'rho',U.rho,'S',U.S,'N',U.N,'mass',M);
   history(k,:)=[n*p.dt d.mass_before d.mass_after_density M d.mass_residual d.limiter_mass_change max(abs(d.Jtilde_raw_boundary)) stats.max_boundary_flux stats.max_zero_mean stats.early_return_steps stats.correction_steps stats.eta_steps stats.eta_min];
  end
  if any(n==[1000 10000 20000 30000 40000 50000])&&~isempty(U.g),micro(end+1)=struct('t',n*p.dt,'g',U.g);end
  if mod(n,1000)==0
   elapsed=elapsed_prior+toc(timer);write_status(data_root,case_id,'running',n*p.dt,elapsed,stats);
   fprintf('PROGRESS %s t=%g seconds=%.1f drift=%.3g bypass=%d correction=%d minF=%.3g\n',case_id,n*p.dt,elapsed,stats.max_relative_mass_drift,stats.early_return_steps,stats.correction_steps,stats.min_final_f);
  end
  if mod(n,5000)==0
   n0=n;oldelapsed=elapsed_prior;elapsed_prior=elapsed_prior+toc(timer);save(checkpoint,'U','stats','snap','micro','history','events','nevents','n0','elapsed_prior','settings','provenance','-v7.3');elapsed_prior=oldelapsed;
  end
 end
 stats.mass_final=sum(U.rho)*grid.dx;stats.seconds=elapsed_prior+toc(timer);if strcmp(c.kind,'macro'),stats.min_final_f=NaN;stats.min_scaled_final_f=NaN;end
 out=struct('grid',grid,'U',U,'snap',snap,'cm_t',[snap.t],'cm_x',arrayfun(@(s)sum(grid.x.*s.rho)/sum(s.rho),snap),'params',p,'kind',c.kind);
 events=events(1:nevents,:);save(finalfile,'out','stats','settings','provenance','micro','history','events','-v7.3');
 writematrix(history,fullfile(data_root,'cases',[case_id '_history.csv']));writematrix(events,fullfile(data_root,'cases',[case_id '_correction_times.csv']));
 write_status(data_root,case_id,'complete',50,stats.seconds,stats);fprintf('FORMAL_COMPLETE %s seconds=%.3f mass=%.16g drift=%.3g\n',case_id,stats.seconds,stats.mass_final,stats.max_relative_mass_drift);ok=true;
catch err
 failure=struct('case_id',case_id,'step',n,'message',err.message,'identifier',err.identifier,'stack',err.stack,'report',getReport(err,'extended')); %#ok<NASGU>
 save(fullfile(data_root,'failures',[case_id '.mat']),'U_before','candidate','stats','settings','provenance','failure','-v7.3');
 write_status(data_root,case_id,'failed',(n-1)*p.dt,elapsed_prior+toc(timer),stats);fprintf('FORMAL_FAILED %s\n%s\n',case_id,getReport(err,'extended'));
end
end
function write_status(data_root,id,state,t,elapsed,stats)
p=fullfile(data_root,'logs',[id '_status.json']);tmp=[p '.tmp'];f=fopen(tmp,'w');fprintf(f,'%s',jsonencode(struct('case_id',id,'state',state,'t',t,'elapsed',elapsed,'stats',stats)));fclose(f);movefile(tmp,p,'f');
end
