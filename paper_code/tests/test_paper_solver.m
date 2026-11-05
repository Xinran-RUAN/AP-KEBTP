function test_paper_solver
here=fileparts(fileparts(mfilename('fullpath')));repo=fileparts(here);code=here;startup_paper;
assert(strcmp(which('model.positivity_limiter'),fullfile(code,'+model/positivity_limiter.m')));
p=model.default_params();p.dx=.025;p.dt=.001;p.dv=.02;p.eps=.01;p.response_eps=.01;p.L=8*p.dx;p.verbose=false;g=model.make_grid(p);
amp=10*sin(2*pi*(0:8)/8);amp([1 end])=0;gg=model.project_zero_mean(g.v*amp,g);rho=ones(1,8);
cases=struct('name',{'positive_nonconstant','zero_density','positive_old_transfer_counterexample','negative_f','negative_density'}, ...
 'rho',{rho,[1 0 0 1], [1 .01 .01 1],rho,[1 -.02 .01 1]},'g',{gg,zeros(g.Nv,5),[],20*gg,[]},'grid',{g,[],[],g,[]});
p4=p;p4.L=4*p.dx;g4=model.make_grid(p4);gcounter=model.project_zero_mean(g4.v*([0 .98 -.98 .98 0]/p.eps),g4);
for j=[2 3 5],cases(j).grid=g4;end;cases(3).g=gcounter;cases(5).g=gcounter;
rows=struct([]);
for j=1:numel(cases)
 c=cases(j);[r,h,z]=model.positivity_limiter(c.rho,c.g,c.grid,p);F=r/c.grid.V+.5*p.eps*(h(:,1:end-1)+h(:,2:end));
 if j<=3,assert(z.early_return&&~z.correction_applied&&isequal(r,c.rho)&&isequal(h,c.g));else
  assert(z.correction_applied&&~z.early_return);
 end
 scale=max(1,max(abs(F),[],'all'));assert(min(F,[],'all')>=-128*eps*scale);
 J=utils.vint(c.grid.v.*h,c.grid.w);M=sum(r)*c.grid.dx;M0=sum(c.rho)*c.grid.dx;means=utils.vint(h,c.grid.w);
 assert(abs(M-M0)<128*eps*max(1,M0));assert(max(abs(means))<512*eps*max(1,max(abs(h),[],'all')));assert(max(abs(J([1 end])))<128*eps);
 row=struct('name',c.name,'early_return',z.early_return,'correction_applied',z.correction_applied,'rho_bitwise_equal',isequal(r,c.rho),'g_bitwise_equal',isequal(h,c.g), ...
  'theta_cells',z.theta_cells,'theta_min',z.theta_min,'mass_scale',z.mass_scale,'eta_edges',z.eta_edges,'eta_min',z.eta_min,'min_f',min(F,[],'all'),'mass_difference',M-M0,'max_mean_g',max(abs(means)),'boundary_flux',max(abs(J([1 end]))));rows=append(rows,row);
end
abnormal_rejected=true;
for j=1:4
 rr=rho;hh=gg;if j==1,rr(2)=NaN;elseif j==2,rr(2)=Inf;elseif j==3,hh(2,2)=NaN;else,hh(2,2)=Inf;end
 caught=false;try,model.positivity_limiter(rr,hh,g,p);catch,caught=true;end;abnormal_rejected=abnormal_rejected&&caught;
end
assert(abnormal_rejected);
U=struct('rho',rho,'g',gg,'S',zeros(1,8),'N',1000*ones(1,8),'t',0);on=U;off=U;po=p;po.use_limiter=false;two=struct([]);
for n=1:2
 [on,d]=src.step_kinetic_AP(on,g,p);off=src.step_kinetic_AP(off,g,po);assert(d.limiter.early_return&&isequal(on,off));
 two=append(two,struct('step',n,'rho_difference',norm(on.rho-off.rho,Inf),'g_difference',max(abs(on.g-off.g),[],'all'),'full_state_bitwise_equal',isequal(on,off)));
end
fine=load(fullfile(here,'config/baseline.mat'));pf=fine.p;pf.eps=.1;pf.response_eps=.1;pf.use_limiter=true;short=struct([]);
for ee=[.1 .05 .02 .01 0]
 pp=pf;pp.eps=max(ee,.01);pp.response_eps=ee;U=model.initial_data(fine.g,pp);if ee==0,U.g=[];end
 timer=tic;nr=0;early=0;minf=Inf;
 for n=1:20
  if ee==0,U=src.step_macro(U,fine.g,pp);else
   [U,d]=src.step_kinetic_AP(U,fine.g,pp);early=early+d.limiter.early_return;nr=nr+d.limiter.correction_applied;
   F=U.rho/fine.g.V+.5*ee*(U.g(:,1:end-1)+U.g(:,2:end));minf=min(minf,min(F,[],'all'));assert(all(isfinite(F(:))));
  end
  assert(all(isfinite(U.rho))&&all(U.rho>=0));
 end
 short=append(short,struct('epsilon',ee,'steps',20,'elapsed',toc(timer),'early_steps',early,'correction_steps',nr,'min_f',minf));
end

writejson(fullfile(repo,'paper_data/diagnostics/package_validation.json'),struct('passed',true,'MATLAB',version,'cases',rows,'two_steps',two,'abnormal_rejected',abnormal_rejected,'finegrid_shortchecks',short));
disp(struct2table(rows));disp(struct2table(short));fprintf('TRIGGER_VALIDATION_PASSED\n');
end
function a=append(a,r),if isempty(a),a=r;else,a(end+1)=r;end,end
function writejson(p,v),f=fopen(p,'w');fprintf(f,'%s',jsonencode(v,'PrettyPrint',true));fclose(f);end
