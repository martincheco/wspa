
function qstate_inttime,amp,w,T,k


ds=25D-12
intg=0D
s=0D



repeat begin

	intg=intg+(1D0+amp*sin(w*(T+s)))*ds
	s+=ds

end until intg ge k or s gt 25000D-12

;print,k,intg,s

return,s

end


function qstate_gentime,amp,w,nT,nk,kl
	
period=2D0*!PI/w
;print,period
tt=dindgen(nT)/nT*period
dt=dindgen(nk*kl)/nk*period
res=dblarr(nT,nk*kl)

	for i=0,nT-1 do begin
	 	 for j=0,nk*kl-1 do res[i,j]=qstate_inttime(amp,w,tt(i),dt(j))
		;print,i
	end
	
return,res

end


function qstate_inttime2,amp,w,T,k,thr,moc


ds=50D-12
intg=0D
s=0D



repeat begin

	intg=intg+(amp*((  (( sin(w*(T+s)) > thr ) - thr)>0. )^moc) )*ds
	s+=ds

end until intg ge k or s gt 50000D-12

;print,k,intg,s

return,s

end


function qstate_gentime2,amp,w,nT,nk,kl,thr,moc
	
period=2D0*!PI/w
print,period
tt=dindgen(nT)/nT*period
dt=dindgen(nk*kl)/nk*period
res=dblarr(nT,nk*kl)

	for i=0,nT-1 do begin
	 	 for j=0,nk*kl-1 do res[i,j]=qstate_inttime2(amp,w,tt(i),dt(j),thr,moc)
;		print,i
	end
	
return,res

end

function qstate_inttime3,r2,r1,w,T,k,thr,moc


ds=25D-12
intg=0D
s=0D



repeat begin

	intg=intg+(r2*((  (( sin(w*(T+s)) > thr ) - thr)>0. )^moc) + r1)*ds
	s+=ds

end until intg ge k or s gt 50000D-12

;print,k,intg,s

return,s

end


function qstate_gentime3,r2,r1,w,nT,nk,kl,thr,moc
	
period=2D0*!PI/w
;print,period
tt=dindgen(nT)/nT*period
dt=dindgen(nk*kl)/nk*period
res=dblarr(nT,nk*kl)

	for i=0,nT-1 do begin
	 	 for j=0,nk*kl-1 do res[i,j]=qstate_inttime3(r2,r1,w,tt(i),dt(j),thr,moc)
		;print,i
	end
	
return,res

end




function qstate_model1,n,t1,t2,amp,p2,capt1,capt2,thr,moc,k,tmes,tmes3
;n - number of jumps

;k = 1.6D-9 ;mean time/electron at V0
;maxit=10000L

;help,k
;might be neccessary to divide by two!!
;p1 = 0.1 ;modulation of probability of x1
;p2 = 0.6 ;modulation of probalbilty of x2
;t1 - time decay from x1
;t2 - time decay from x2
f = 200D6 ;modulation frequency
;amp= 0.25; voltage mod.
;thr = 0.1 ;threshold for sine

w=2D*!PI*f
period=1./f
;thr=0.45
;moc=1.99
;way=0.5
;capt1=1.5
;capt2=0.5

;p3=0.
;p4=0.

;if(not(keyword_set(nb))) then nb=64

;tmes=qstate_gentime(amp,w,100,100,3)
;tmes=congrid(tmes,5000,15000)

n=long(n)

pt=-alog(randomu(seed,n)) ;the unscaled distribution of time intervals
pt2=-alog(randomu(seed,n)) ;the unscaled distribution of time intervals

p=randomu(seed,n) ;Monte Carlo of going from + to either ++ or X1

T=dblarr(n+1) ;array to store event times
E=intarr(n+1) ;array to store states

X03=T 
X10=T 
X23=T 
X34=T 
X31=T 
X42=T
X12=T
X21=T

T(0)=0D
E(0)=0L

nx03=0L ;total number of transitions for each
nx10=0L
nx23=0L
nx34=0L
nx31=0L
nx42=0L
nx12=0L
nx21=0L
nne=0L ; total number of h+ injected

;assuming state zero at the beginning


for i=1L,n do begin


	;ground state
    	if E(i-1) eq 0 then begin
		if k*pt(i-1) ge 5.*period then dt=k*pt(i-1) else $ 
			dt=tmes((1D12*(T(i-1) mod period))<4999,(k*pt(i-1)*1D12)<24999)
		X03(nx03)=T(i-1)+dt	
		nx03+=1
		nne+=1 ;current flow
		E(i)=3
	end
		
	;X1 state
	if E(i-1) eq 1 then begin
		dt=t1*pt(i-1) ;time it takes to decay from X1 to G0
		X10(nx10)=T(i-1)+dt; moment of decay from X1
		nx10+=1
		E(i)=0
	end

	;X2 state
	if E(i-1) eq 2 then begin
		dt=t2*pt(i-1) ;time it takes to decay from X2 to G0
		X23(nx23)=T(i-1)+dt; moment of decay from X2
		nx23+=1
		E(i)=3
	end


	;+ state
	if E(i-1) eq 3 then begin
		kk=1./(1./(k*p2)+1./(k*capt1))
		dt=tmes3((1D12*(T(i-1) mod period))<4999,(kk*pt(i-1)*1D12)<14999)

		if p(i-1) le capt1/p2*(((sin(w*(T(i-1)+dt))>thr)-thr)^moc) then begin;+ to ++
			x34(nx34)=T(i-1)+dt
			nx34+=1
			nne+=1 ;current flow
			E(i)=4
		end else begin
			X31(nx31)=T(i-1)+dt
			nx31+=1
			E(i)=1
		end
	end

	;++ state
	if E(i-1) eq 4 then begin
		dt=capt2*k*pt(i-1) ;++ to X2
		X42(nx42)=T(i-1)+dt
		nx42+=1
		nne+=1 ;current flow
		E(i)=2
	end


	T(i)=T(i-1)+dt

end


return, {T:T,E:E,X03:X03(0:nx03-1),X10:X10(0:nx10-1),X23:X23(0:nx23-1),X34:X34(0:nx34-1),X42:X42(0:nx42-1),X31:X31(0:nx31-1),nne:nne}
end


function qstate,nn,n,t1,t2,amp,p2,capt1,capt2,thr,moc,irate,nb=nb,plt=plt
!P.multi=[0,1,2]

w=2*!PI*200D6

if not(keyword_set(nb)) then nb=64
tmes=qstate_gentime(amp,w,100,100,5)
;tmes2=qstate_gentime2(amp,w,100,100,5,thr,moc)
tmes3=qstate_gentime3(1./p2,1./capt1,w,100,100,5,thr,moc)
tmes=congrid(tmes,5000,5*5000,cubic=-0.5)
;tmes2=congrid(tmes2,5000,5*5000,cubic=-0.5)
tmes3=congrid(tmes3,5000,5*5000,cubic=-0.5)



;tvscl,[bytscl(congrid(tmes,100,5*100)),bytscl(congrid(tmes3,100,5*100))]

h01t=-1
h02t=-1
h10t=-1
h20t=-1
catt=-1
dcatt=-1

for i=0,nn-1 do begin
	r=qstate_model1(n,t1,t2,amp,p2,capt1,capt2,thr,moc,irate,tmes,tmes3)


	cat=histogram(r.X03*1D12 mod 5000D,nbins=nb,max=5000D)
	dcat=histogram(r.X34*1D12 mod 5000D,nbins=nb,max=5000D)
	h10=histogram(r.X10*1D12 mod 5000D,nbins=nb,max=5000D)
	h01=histogram(r.X31*1D12 mod 5000D,nbins=nb,max=5000D)
	h20=histogram(r.X23*1D12 mod 5000D,nbins=nb,max=5000D)
	h02=histogram(r.X42*1D12 mod 5000D,nbins=nb,max=5000D)

	if h01t(0) ne -1 then h01t=h01t+h01 else h01t=h01
	if h10t(0) ne -1 then h10t=h10t+h10 else h10t=h10
	if h02t(0) ne -1 then h02t=h02t+h02 else h02t=h02
	if h20t(0) ne -1 then h20t=h20t+h20 else h20t=h20
	if catt(0) ne -1 then catt=catt+cat else catt=cat
	if dcatt(0) ne -1 then dcatt=dcatt+dcat else dcatt=dcat


;	plot,findgen(n_elements(h01)*2.)/n_elements(h01)*5.,[h01,h01],yst=1
;	oplot,findgen(n_elements(h10)*2.)/n_elements(h10)*5.,[h10,h10],color=255

;	plot,findgen(n_elements(h02)*2.)/n_elements(h02)*5.,[h02,h02],yst=1
;	oplot,findgen(n_elements(h20)*2.)/n_elements(h20)*5.,[h20,h20],color=255

	;help,h10
	;help,h20
	
	if keyword_set(plt) then begin

	plot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[catt,catt],color=170;,yst=1
	oplot,findgen(n_elements(h01t)*2.)/n_elements(h01t)*5.,[h01t,h01t]
	oplot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[h10t,h10t],color=255	
	plot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[dcatt,dcatt],color=170
	

;	plot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[dcatt,dcatt],color=170,yst=1
	oplot,findgen(n_elements(h02t)*2.)/n_elements(h02t)*5.,[h02t,h02t];,yst=1
	oplot,findgen(n_elements(h20t)*2.)/n_elements(h20t)*5.,[h20t,h20t],color=255

	end
;help,i
;help,r
;print,r.T(-1)
Ieff=(double(r.nne)/double(r.T(-1)))/6.22D18
;print,'I_eff=',(double(r.nne)/double(r.T(-1)))/6.22D18
end
;	plot,findgen(n_elements(h01t)*2.)/n_elements(h01t)*5.,[h01t,h01t],yst=1
;	oplot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[h10t,h10t],color=255

;	plot,findgen(n_elements(h02t)*2.)/n_elements(h02t)*5.,[h02t,h02t],yst=1
;	oplot,findgen(n_elements(h20t)*2.)/n_elements(h20t)*5.,[h20t,h20t],color=255





t=findgen(n_elements(h10t))/n_elements(h10t)*5.

return, {h01:h01t,h10:h10t,h02:h02t,h20:h20t,catt:catt,dcatt:dcatt,t:t,I:Ieff}
end

pro qstate_loop

;window,0,xs=500,ys=500
for amp=0.2,1.0,0.2 do for p2=0.4,2.0,0.2 do for c1=0.2,2.0,0.2 do begin

	 t2=qstate(2,500001L,1000D-12,50D-12,amp,p2,c1,.3,.0,1.8,1000D-12,nb=96,/plt)

a=tvrd(0,true=1)

f=string(amp,format='(F3.1)')+'_'+string(p2,format='(F3.1)')+'_'+string(c1,format='(F3.1)')+'_I'+string(t2.I*1e12,format='(I03)')+'.png'

print,f

write_png,f,a

end


end


pro qstate_find,fset,ampl
;pset - parameters
;fset - indices of parameters to optimize
dark=70.
pts=128

window,0,xs=600,ys=600

!p.multi=[0,1,2]

f='PLS-2.dat'
d='/home/martin/sync/data/CuPC/2020-04-06/'

o=loadpicoharp(d+f)
e1=overlay_picoharp(o,2,5.,rep=1)
e2=overlay_picoharp(o,7,5.,rep=1)
help,e1,/st
help,e2,/st


y1=1.75*shift(smooth(e1.i-dark,10,/edge),-380)
x1=e1.t
y2=shift(smooth(e2.i-dark,10,/edge),-380)
x2=e2.t


y1=congrid(y1,pts,cubic=-0.5)
y2=congrid(y2,pts,cubic=-0.5)
x1=5.*findgen(pts)/double(pts)
x2=x1
help,x1

;plot,[x1,x1+5.],[y1,y2],yst=1


a=read_file(d+f+".fit",/array)

aa=a(-1)
aa=strsplit(aa,/extract)
pset=float(aa(0:8))
cr=float(aa(9))

print,'Initial values'
print,pset
print,"Correlation coeff: ",cr
nf=n_elements(fset)
reuse=0


q=qstate(10,500000L,pset[0],pset[1],pset[2],pset[3],pset[4],pset[5],pset[6],pset[7],pset[8],nb=pts)
cc=ccor(y2,q.h10)
w=where(cc eq max(cc))
;help,w(0)
y2s=shift(y2,w(0))
y1s=shift(y1,w(0))

ncr=qstate_corsigs(y1s,y2s,q.h20,q.h10)
print,"Correlation coeff: ",ncr,"  / Best so far: ",cr	

;plot,[x1,x1+5.],[y2s,y2s],/nodata,yst=1
plot,[x1,x1+5.],[y1s,y1s],yst=1
oplot,[q.t,q.t+5.],double([q.h20,q.h20])/max([q.h20,q.h10])*max(y2s),color=255
plot,[x1,x1+5.],[y2s,y2s],yst=1
oplot,[q.t,q.t+5.],double([q.h10,q.h10])/max([q.h10,q.h10])*max(y2s),color=255


repeat begin
	
	if reuse eq 0 then begin
		r=1.+(randomu(seed,nf)*2.*ampl)-ampl
		print,"Randomizing by coefficients:"

	end else begin

		print,"Reusing coefficients:"
		reuse=0
	end
	npset=pset
	npset(fset)=npset(fset)*r
	print,r
	print,"->"
	print,npset
	

	q=qstate(10,500000L,npset[0],npset[1],npset[2],npset[3],npset[4],npset[5],npset[6],npset[7],npset[8],nb=pts)
;	help,q,/st

	cc=ccor(y2,q.h10)
;	w=where(cc eq max(cc))
	help,w(0)
	y2s=shift(y2,w(0))
	y1s=shift(y1,w(0))

	ncr=qstate_corsigs(y1s,y2s,q.h20,q.h10)



	print,"Correlation coeff: ",ncr,"  / Best so far: ",cr	
	if ncr gt cr then begin
		pset=npset
		cr=ncr
		openw,1,d+f+".fit",/append,width=1024
		printf,1,[pset,cr,q.i]
		close,1
		print,"IMPROVING! try again.."
		reuse=1

		print,"Effective current: ",q.i
		;plot,[x1,x1+5.],[y2s,y2s],/nodata,yst=1
		plot,[x1,x1+5.],[y1s,y1s],yst=1
		oplot,[q.t,q.t+5.],double([q.h20,q.h20])/max([q.h20,q.h10])*max(y2s),color=255

		plot,[x1,x1+5.],[y2s,y2s],yst=1
		oplot,[q.t,q.t+5.],double([q.h10,q.h10])/max([q.h10,q.h10])*max(y2s),color=255





	end else begin
		print,"Nope.. try again.."
	end


end until file_test(d+'stop') ne 0

print,'Found stop file, stopping now.'

end

function qstate_corsigs,y1,y2,q1,q2


cc=ccor(y1,y2)

w=where(cc eq max(cc))




return,correlate([y1,y2,y2],[q1,q2,q2],/double)



end

