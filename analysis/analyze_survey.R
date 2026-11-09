#!/usr/bin/env Rscript
# Reproduce the survey analysis. R >= 3.6; MASS, psych, jsonlite.
options(stringsAsFactors=FALSE, width=130, mc.cores=1)
RNGkind('Mersenne-Twister','Inversion','Rejection')
args <- commandArgs(trailingOnly=FALSE)
script <- sub('^--file=', '', args[grepl('^--file=',args)])
base <- normalizePath(file.path(dirname(script),'..'))
dir.create(file.path(base,'results'),showWarnings=FALSE)
out <- file.path(base,'results')
d <- read.csv(file.path(base,'data','survey_responses.csv'),na.strings='')
context <- jsonlite::fromJSON(file.path(base,'data','aggregate_context.json'))
stopifnot(nrow(d)==65, !anyNA(d), all(d$gender %in% c('Male','Female','Prefer not to say')),
          all(d$prior_programming %in% 0:1), all(d$recalled_interactive %in% 0:1),
          all(as.matrix(d[paste0('Q',1:9)]) %in% 1:5))
seed <- 20261109L; B <- 10000L; M <- 99999L
set.seed(seed)
qs <- paste0('Q',1:9)
desc <- do.call(rbind,lapply(qs,function(q){
 x<-d[[q]];tab<-tabulate(x,5)
 data.frame(item=q,n=length(x),mean=mean(x),sd=sd(x),median=median(x),q1=unname(quantile(x,.25)),q3=unname(quantile(x,.75)),
            n1=tab[1],n2=tab[2],n3=tab[3],n4=tab[4],n5=tab[5],lower=sum(x<=2),middle=sum(x==3),upper=sum(x>=4))
}))
write.csv(desc,file.path(out,'item_descriptives.csv'),row.names=FALSE)

cliff <- function(x,y) mean(sign(outer(x,y,'-')))
rank_group <- function(var,group,id,yes=1,no=0){
 x<-d[[var]][d[[group]]==yes];y<-d[[var]][d[[group]]==no]
 nx<-length(x);ny<-length(y);r<-rank(c(x,y));u<-sum(r[seq_len(nx)])-nx*(nx+1)/2
 observed<-abs(u-nx*ny/2);set.seed(seed+id)
 sim<-replicate(M,abs(sum(r[sample.int(nx+ny,nx)])-nx*(nx+1)/2-nx*ny/2))
 p<-(sum(sim>=observed-1e-10)+1)/(M+1)
 set.seed(seed+100+id)
 eff<-replicate(B,cliff(sample(x,nx,replace=TRUE),sample(y,ny,replace=TRUE)))
 ci<-quantile(eff,c(.025,.975),na.rm=TRUE)
 data.frame(test=paste(group,var,sep='__'),outcome=var,group=group,n1=nx,n0=ny,
            median1=median(x),median0=median(y),q11=unname(quantile(x,.25)),q31=unname(quantile(x,.75)),q10=unname(quantile(y,.25)),q30=unname(quantile(y,.75)),
            U=u,effect=cliff(x,y),ci_low=ci[1],ci_high=ci[2],p=p,
            asymptotic_p=wilcox.test(x,y,exact=FALSE,correct=TRUE)$p.value,row.names=NULL)
}
groups <- rbind(rank_group('Q5','prior_programming',1),rank_group('Q5','recalled_interactive',2),
                rank_group('Q1','prior_programming',3),rank_group('Q1','recalled_interactive',4))

spearman <- function(a,b,id){
 x<-d[[a]];y<-d[[b]];rx<-rank(x)-mean(rank(x));ry<-rank(y)-mean(rank(y));den<-sqrt(sum(rx^2)*sum(ry^2))
 rho<-sum(rx*ry)/den;set.seed(seed+id)
 sim<-replicate(M,sum(rx*sample(ry))/den)
 p<-(sum(abs(sim)>=abs(rho)-1e-12)+1)/(M+1)
 set.seed(seed+100+id)
 bs<-replicate(B,{ii<-sample.int(nrow(d),nrow(d),replace=TRUE);cor(x[ii],y[ii],method='spearman')})
 ci<-quantile(bs,c(.025,.975),na.rm=TRUE)
 data.frame(test=paste(a,b,sep='__'),a=a,b=b,n=nrow(d),rho=rho,ci_low=ci[1],ci_high=ci[2],p=p,row.names=NULL)
}
corr <- rbind(spearman('Q5','Q6',5),spearman('Q7','Q8',6))
dif <- d$Q7-d$Q5
pos<-sum(dif>0);neg<-sum(dif<0);ties<-sum(dif==0)
bt<-binom.test(pos,pos+neg,p=.5,alternative='two.sided')
sign_test<-list(n=65,positive=pos,equal=ties,negative=neg,non_tied=pos+neg,probability=pos/(pos+neg),ci=unname(bt$conf.int),p=bt$p.value,
 all_n_positive=pos/65,all_n_equal=ties/65,all_n_negative=neg/65)
allp<-c(sign_test$p,groups$p,corr$p);adj<-p.adjust(allp,'holm')
sign_test$p_holm<-adj[1];groups$p_holm<-adj[2:5];corr$p_holm<-adj[6:7]
write.csv(groups,file.path(out,'main_group_comparisons.csv'),row.names=FALSE)
write.csv(corr,file.path(out,'main_correlations.csv'),row.names=FALSE)
pairtab<-table(factor(d$Q5,levels=1:5),factor(d$Q7,levels=1:5))
write.csv(unclass(pairtab),file.path(out,'paired_Q5_Q7.csv'))

gender <- rbind(rank_group('Q5','gender',7,'Female','Male'),rank_group('Q7','gender',8,'Female','Male'))
gender$p_holm<-p.adjust(gender$p,'holm')
write.csv(gender,file.path(out,'secondary_gender.csv'),row.names=FALSE)

# Conditional ordinal model: fit before deciding whether it is adequately supported.
ord<-MASS::polr(ordered(Q5)~prior_programming+recalled_interactive,data=d,Hess=TRUE,method='logistic')
se<-sqrt(diag(vcov(ord)))[names(coef(ord))]
model_table<-data.frame(predictor=names(coef(ord)),beta=as.numeric(coef(ord)),se=se,
 OR=exp(coef(ord)),ci_low=exp(coef(ord)-1.96*se),ci_high=exp(coef(ord)+1.96*se),row.names=NULL)
thresholds<-lapply(1:4,function(k){
 dd<-d;dd$above<-as.integer(dd$Q5>k)
 fit<-glm(above~prior_programming+recalled_interactive,data=dd,family=binomial())
 s<-summary(fit)$coefficients
 list(cutoff=k,events=sum(dd$above),coefficients=s,converged=fit$converged,
      unstable=any(!is.finite(s))||any(abs(s[,1])>10)||any(s[,2]>10),fit=fit)
})
threshold_table<-do.call(rbind,lapply(thresholds,function(x)data.frame(cutoff=x$cutoff,term=rownames(x$coefficients),beta=x$coefficients[,1],se=x$coefficients[,2],events=x$events,row.names=NULL)))
write.csv(model_table,file.path(out,'ordinal_model_diagnostic_estimates.csv'),row.names=FALSE)
write.csv(threshold_table,file.path(out,'ordinal_threshold_diagnostics.csv'),row.names=FALSE)
model_reason<-if(any(vapply(thresholds,function(x)x$unstable,logical(1))))
 'Not retained as an interpretable adjusted model: threshold-specific logistic fits are unstable/separated, so the proportional-odds assumption cannot be adequately assessed in these sparse data.' else 'Threshold fits finite; inspect proportional-odds evidence before interpretation.'
model <- list(convergence=ord$convergence,loglik=as.numeric(logLik(ord)),AIC=AIC(ord),hessian_min_eigen=min(eigen(ord$Hessian,symmetric=TRUE)$values),
 estimates=model_table,thresholds=threshold_table,retained=FALSE,decision=model_reason,
 gender_model_decision='Not fitted: female Q5 cells include zeros in categories 3 and 5 and only one response in category 4; no stable adjusted gender model is asserted.')

# Measurement diagnostics are supplementary; no composite replaces item-level outcomes.
alpha_fun <- function(x){k<-ncol(x);k/(k-1)*(1-sum(apply(x,2,var))/var(rowSums(x)))}
reliability <- do.call(rbind,lapply(seq_along(list(c(1,2,3,4,9),c(5,6),c(7,8))),function(j){
 ix<-list(c(1,2,3,4,9),c(5,6),c(7,8))[[j]];x<-as.matrix(d[paste0('Q',ix)]);set.seed(seed+200+j)
 bs<-replicate(B,alpha_fun(x[sample.int(nrow(x),nrow(x),TRUE),,drop=FALSE]));ci<-quantile(bs,c(.025,.975),na.rm=TRUE)
 r<-if(ncol(x)==2)cor(x[,1],x[,2]) else NA_real_
 data.frame(scale=c('General evaluation (Q1-Q4,Q9)','Sharing and perceived benefit (Q5,Q6)','Reviewing and perceived benefit (Q7,Q8)')[j],k=ncol(x),alpha=alpha_fun(x),ci_low=ci[1],ci_high=ci[2],pearson_r=r,spearman_brown=if(is.finite(r))2*r/(1+r)else NA_real_)
}))
write.csv(reliability,file.path(out,'supplementary_reliability.csv'),row.names=FALSE)
items<-as.matrix(d[qs]);R<-cor(items)
set.seed(seed+300)
pa<-psych::fa.parallel(items,fm='minres',fa='both',n.iter=1000,sim=FALSE,plot=FALSE,quant=.95)
pa_result<-list(nfact=pa$nfact,ncomp=pa$ncomp,fa_observed=pa$fa.values,fa_reference_mean=pa$fa.simr,
 fa_reference_95=apply(pa$values[,10:18],2,quantile,.95),pc_observed=pa$pc.values,
 pc_reference_mean=pa$pc.simr,pc_reference_95=apply(pa$values[,1:9],2,quantile,.95))
saveRDS(pa,file.path(out,'parallel_analysis.rds'))
kmo<-psych::KMO(R);bartlett<-psych::cortest.bartlett(R,n=nrow(d))
fa_list<-lapply(unique(c(pa$nfact,1,3)),function(k){
 if(k<1)return(NULL)
 fit<-psych::fa(R,nfactors=k,n.obs=nrow(d),fm='minres',rotate='none',warnings=FALSE)
 L<-unclass(fit$loadings);Phi<-diag(k)
 if(k>1){rot<-stats::promax(L);L<-unclass(rot$loadings);Phi<-solve(rot$rotmat)%*%t(solve(rot$rotmat))}
 write.csv(data.frame(item=rownames(L),L,communality=fit$communality,uniqueness=fit$uniquenesses),file.path(out,paste0('minres_',k,'factor_loadings.csv')),row.names=FALSE)
 list(k=k,loadings=L,Phi=Phi,communality=fit$communality,uniqueness=fit$uniquenesses,rms=fit$rms,fit_off=fit$fit.off,heywood=any(fit$uniquenesses<=0))
})
poly_warn<-character(0)
poly <- tryCatch(withCallingHandlers(psych::polychoric(items,smooth=FALSE,global=FALSE,correct=.5,progress=FALSE),warning=function(w){poly_warn<<-c(poly_warn,conditionMessage(w));invokeRestart('muffleWarning')}),error=function(e)e)
empty_cells<-sapply(combn(1:9,2,simplify=FALSE),function(ix)sum(table(factor(items[,ix[1]],levels=1:5),factor(items[,ix[2]],levels=1:5))==0))
poly_result<-list(warnings=unique(poly_warn),empty_cells_min=min(empty_cells),empty_cells_max=max(empty_cells),empty_cells_median=median(empty_cells))
if(inherits(poly,'error')){poly_result$error<-conditionMessage(poly)}else{
 poly_result$min_eigen<-min(eigen(poly$rho,symmetric=TRUE)$values);poly_result$rho<-poly$rho
 write.csv(poly$rho,file.path(out,'polychoric_correlations_diagnostic.csv'))
}
poly_result$retained<-FALSE
poly_result$decision<-'Not used for main inference: sparse bivariate category tables and small sample; Pearson common-factor diagnostics are exploratory only.'
one5<-psych::fa(cor(d[c('Q1','Q2','Q3','Q4','Q9')]),nfactors=1,n.obs=nrow(d),fm='minres',rotate='none',warnings=FALSE)
l5<-as.numeric(one5$loadings)
omega5<-sum(l5)^2/(sum(l5)^2+sum(one5$uniquenesses))
measurement<-list(reliability=reliability,omega_general_onefactor=omega5,KMO=kmo$MSA,item_KMO=kmo$MSAi,bartlett=bartlett,
 parallel=pa_result,common_factors=fa_list,polychoric=poly_result,
 composite_decision='No two-item role composite is interpreted because its items mix participation and perceived benefit. No legacy Welch-composite tests are used as inferential evidence.')
write.csv(R,file.path(out,'pearson_item_correlations.csv'))

# Individual ages, first-enrollment status, and detailed language histories are not public.
# Their descriptive summaries are read from aggregate inputs, not inferred from respondents.
demographics <- context$demographics
stopifnot(demographics$n == nrow(d))
for (key in c('gender','prior_programming','recalled_interactive')) {
 observed <- as.list(table(d[[key]]))
 stopifnot(all(unlist(observed) == unlist(demographics[[key]])[names(observed)]))
 demographics[[key]] <- observed
}
source_counts <- context$experience_sources
write.csv(source_counts,file.path(out,'experience_source_counts.csv'),row.names=FALSE)
results<-list(settings=list(seed=seed,bootstrap=B,permutations=M,R=R.version.string,RNG='Mersenne-Twister / Inversion / Rejection',parallel_analysis_cores=1,main_adjustment='Holm, 7 tests',gender_adjustment='Holm, 2 tests'),
 demographics=demographics,descriptives=desc,sign=sign_test,groups=groups,correlations=corr,gender=gender,model=model,measurement=measurement,experience_sources=source_counts,
 sensitivity=list(wilcoxon_status='Not interpreted: interval-scale score differences and a symmetric numeric difference distribution are not assumed. The sign test compares direction only on the shared agreement scale.',welch_status=measurement$composite_decision))
jsonlite::write_json(results,file.path(out,'results.json'),pretty=TRUE,auto_unbox=TRUE,na='null',digits=12)
saveRDS(list(data=d,results=results,pairtab=pairtab,parallel=pa),file.path(out,'analysis_bundle.rds'))
capture.output(sessionInfo(),file=file.path(out,'sessionInfo.txt'))
cat('\nMAIN GROUP COMPARISONS\n');print(groups)
cat('\nMAIN CORRELATIONS\n');print(corr)
cat('\nPAIRED SIGN TEST (COMMON AGREEMENT SCALE)\n');print(sign_test)
cat('\nSECONDARY GENDER\n');print(gender)
cat('\nMODEL DECISION\n');print(model_reason);print(model_table)
cat('\nMEASUREMENT\n');print(reliability);print(c(KMO=kmo$MSA,nfact=pa$nfact,ncomp=pa$ncomp,omega5=omega5));print(poly_result$min_eigen)
cat('\nDEMOGRAPHICS\n');print(demographics)
