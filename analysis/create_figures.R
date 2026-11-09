#!/usr/bin/env Rscript
args<-commandArgs(trailingOnly=FALSE);script<-sub('^--file=','',args[grepl('^--file=',args)])
base<-normalizePath(file.path(dirname(script),'..'))
dir.create(file.path(base,'figures'),showWarnings=FALSE)
a<-readRDS(file.path(base,'results','analysis_bundle.rds'));d<-a$data;r<-a$results
blue<-'#245A78';ink<-'#253340';muted<-'#667684'
openpdf<-function(name,h){pdf(file.path(base,'figures',name),width=6.3,height=h,family='Times',pointsize=10,useDingbats=FALSE);par(fg=ink,col=ink,col.axis=ink,col.lab=ink,lwd=.75)}

openpdf('figure1_workflow.pdf',1.70)
par(mar=c(.3,.2,.3,.2));plot.new();plot.window(xlim=c(0,10),ylim=c(0,2.0),xaxs='i',yaxs='i')
labs<-c('Materials shared\n2 days in advance','Individual\npreparation','Voluntary\ncode sharing','Peer review\nand discussion','Assistant\nclarification')
for(i in 1:5){x<-(i-1)*2;rect(x+.07,.65,x+1.83,1.70,col='#F4F6F8',border='#BBC7CE',lwd=.75);text(x+.95,1.17,labs[i],cex=.95);if(i<5)arrows(x+1.84,1.17,x+2.04,1.17,length=.055,col=blue,lwd=.75)}
text(5,.26,'Live Share workspace and assistant guidance support the in-session activities.',cex=.86,col=muted)
dev.off()
if('--workflow-only'%in%commandArgs(trailingOnly=TRUE))quit(save='no',status=0)

openpdf('figure2_item_distributions.pdf',3.6)
par(mar=c(3.2,2.0,.3,.6),xpd=NA)
counts<-as.matrix(r$descriptives[,paste0('n',1:5)])
pct<-100*counts/65;cols<-c('#9D4B43','#D5AAA3','#E5E7EB','#8BB6CA',blue)
labels<-c('Q1  Laboratory satisfaction','Q2  Increased course interest','Q3  Usefulness of tools','Q4  Advance material sharing','Q5  Shared own code','Q6  Benefit of being reviewed','Q7  Reviewed peers\' code','Q8  Perceived thinking improvement','Q9  Recommend continuation')
plot.new();plot.window(xlim=c(-52,100),ylim=c(.1,10.0),xaxs='i',yaxs='i')
for(t in seq(0,100,25)){segments(t,.6,t,9.5,col='#D8DFE4',lwd=.5);text(t,.18,paste0(t,'%'),cex=.85,adj=if(t==0)0 else if(t==100)1 else .5)}
for(i in 1:9){y<-10-i;start<-0
 for(j in 1:5){rect(start,y-.27,start+pct[i,j],y+.27,col=cols[j],border='white',lwd=.5);if(pct[i,j]>=10)text(start+pct[i,j]/2,y,counts[i,j],cex=.83,col=if(j%in%c(1,5))'white'else ink);start<-start+pct[i,j]}
 text(-2,y,labels[i],adj=1,cex=.91)
}
legend(-47,-.55,legend=paste('Score',1:5),fill=cols,border=NA,horiz=TRUE,bty='n',cex=.88,x.intersp=.6,y.intersp=.9)
dev.off()

openpdf('figure3_paired_participation.pdf',4.5)
par(mar=c(3.9,4.1,2.3,1.3))
z<-unclass(a$pairtab);pal<-colorRampPalette(c('#F5F8FA','#A8C9D8',blue))(101)
plot.new();plot.window(xlim=c(.5,5.5),ylim=c(.5,5.5),asp=1,xaxs='i',yaxs='i')
for(x in 1:5)for(y in 1:5){v<-z[x,y];rect(x-.5,y-.5,x+.5,y+.5,col=pal[1+round(v/max(z)*100)],border='white',lwd=.75)}
for(x in 1:5)rect(x-.5,x-.5,x+.5,x+.5,border='#7E8E98',lwd=.75)
for(x in 1:5)for(y in 1:5){v<-z[x,y];text(x,y,v,cex=1.1,col=if(v>max(z)*.55)'white'else ink)}
axis(1,at=1:5,tick=FALSE);axis(2,at=1:5,las=1,tick=FALSE)
mtext('Shared own code (Q5)',side=1,line=2.0,cex=1)
mtext('Reviewed peers\' code (Q7)',side=2,line=2.2,cex=1)
mtext(sprintf('Q7 > Q5: %d    |    Q7 = Q5: %d    |    Q7 < Q5: %d',r$sign$positive,r$sign$equal,r$sign$negative),side=3,line=.7,cex=.94)
dev.off()
cat('Created three vector PDF figures in',file.path(base,'figures'),'\n')
