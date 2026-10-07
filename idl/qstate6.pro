;calculates a cumulative integral of the probability starting from 0

function qstate_gentime0,amp,k,w,nT ;k*(1+amp*sin) modulation (0 to +)
	period=2D0*!PI/w
	intg=dblarr(nT)
	ds=1D-12
	intg[0]=0D
	for i=1,nT-1 do intg[i]=intg[i-1]+k*(1D0+amp*sin(w*i*ds))*ds
	return,intg
end

function qstate_gentime2,amp,r2,t2,w,nT,thr,moc ;r2*(sin) + t2  (+ to ++ OR X1)
	period=2D0*!PI/w
	intg=dblarr(nT)
	ds=1D-12
	intg[0]=0D
	for i=1,nT-1 do intg[i]=intg[i-1]+(t2 + r2*(1D0+amp*sin(w*i*ds)))*ds
	return,intg
end




function qstate_gentime3,amp,r2,r1,w,nT,thr,moc ;r2*(sin>0) + r1 modulation (+ to ++ OR X1)
	period=2D0*!PI/w
	intg=dblarr(nT)
	ds=1D-12
	intg[0]=0D
	for i=1,nT-1 do intg[i]=intg[i-1]+(r2*((  (( sin(w*i*ds) > thr ) - thr)>0. )^moc) + r1)*ds
	return,intg
end

function qstate_gentime4,amp,r1,w,nT,thr,moc ;(++ to X2)
	period=2D0*!PI/w
	intg=dblarr(nT)
	ds=1D-12
	intg[0]=0D
	for i=1,nT-1 do intg[i]=intg[i-1]+r1*(1D0+amp*sin(w*i*ds))*ds
	return,intg
end


function qstate_gentime1,r2,r1,w,nT,thr,moc ;r2*(sin>0) + r1 modulation (+ to ++ OR X1)
	period=2D0*!PI/w
	intg=dblarr(nT)
	ds=1D-12
	intg[0]=0D
	for i=1,nT-1 do intg[i]=intg[i-1]+(r2*((  (( sin(w*i*ds) > thr ) - thr)>0. )^moc) + r1)*ds
	return,intg
end


function getdt,intg,T,pt
	;T - start time in ps, modded by period
	;pt - randomized value
	;s - time interval to reach pt in ps
	;intg - cumulative integral calculated beforehand
	vl=intg(T)+pt
	tt=round(T)
	d=(500000L-tt)/2
	w=tt+d
	d=d/2
	repeat begin
		w1=w-d
		w2=w+d
		if intg(w) gt vl then w=w1 else w=w2
		d=d/2
		end until d lt 2
	return,w-tt ;return time in ps
end


function qstate_model1,n,t1,t2,amp,p2,capt1,capt2,capt3,capt4,thr,moc,k,tmes,plasmon=plasmon
;t1,t2 - X1,X2 lifetimes
;amp - modulation amplitude (relative to threshold)
;p2 - + to ++ h+ injection rate (relative to k, does not scale with amp)
;capt1 - e- capture rate for + to X1 (rel to k)
;capt2 - e- capture rate for ++ to X2 (rel to k)
;capt3 - X2 to X1 e- capture rate (rel to k)
;capt4 - X1 to X2 h+ injection rate (rel to k)

f = 200D6 ;modulation frequency
w=2D*!PI*f 
period=1./f
n=long(n)

tmes0=reform(tmes(0,*))
tmes1=reform(tmes(1,*))
tmes2=reform(tmes(2,*))
tmes3=reform(tmes(3,*))
tmes4=reform(tmes(4,*))

pt=-alog(randomu(seed,n)) ;the unscaled distribution of time intervals

p=randomu(seed,n) ;Monte Carlo of going from + to either ++ or X1 etc.

T=dblarr(n+1) ;array to store event times
E=intarr(n+1) ;array to store states

X03=T ;0 to +, h+ injection
X10=T ;X1 decay
X23=T ;X2 decay
X34=T ;+ to ++, h+ injection
X31=T ;+ to X1, e- capture
X42=T ;++ to X2, e- capture
X12=T ;X1 to X2, h+ injection
X21=T ;X2 to X1, e- capture

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

nne=0L ; total number of h+ injected, corresponding to current

;assuming state zero at the beginning

for i=1L,n do begin
	;ground state
    	if E(i-1) eq 0 then begin
		dt=1D-12*getdt(tmes0,1D12*(T(i-1) mod period),pt(i-1))
		X03(nx03)=T(i-1)+dt	
		nx03+=1
		nne+=1 ;current flow
		if keyword_set(plasmon) then E(i)=1 else E(i)=3
	end
		
	;X1 state
	if E(i-1) eq 1 then begin
		ic4=1./(k*capt4)
		it1=1./t1

		dt=1D-12*getdt(tmes1,1D12*(T(i-1) mod period),pt(i-1))
		isn=(((sin(w*(T(i-1)+dt))>thr)-thr)^moc)*ic4

		if p(i-1) le isn/(isn+it1) then begin;X1 to X2
			x12(nx12)=T(i-1)+dt
			nx12+=1
			nne+=1 ; current flow
			E(i)=2
		end else begin
			x10(nx10)=T(i-1)+dt ;X1 to G0
			nx10+=1
			E(i)=0
		end
	end

	;X2 state
	if E(i-1) eq 2 then begin
		it2=1./t2
		ic3=1./(k*capt3)
		kk=1D/(it2+ic3)
		dt=kk*pt(i-1);1D-12*getdt(tmes2,1D12*(T(i-1) mod period),pt(i-1))
		;jsn=(1D0+amp*sin(w*T(i-1)))*ic3

		if p(i-1) le ic3/(ic3+it2) then begin
			X21(nx21)=T(i-1)+dt;X2 to X1
			nx21+=1
			E(i)=1
		end else begin
			X23(nx23)=T(i-1)+dt; X2 to +
			nx23+=1
			E(i)=3
		end
	end


	;+ state
	if E(i-1) eq 3 then begin
		ic1=1./(k*capt1)
		ip2=1./(k*p2)
		dt=1D-12*getdt(tmes3,1D12*(T(i-1) mod period),pt(i-1))
		isn=(((sin(w*(T(i-1)+dt))>thr)-thr)^moc)*ip2
	;	jsn=(1D0+amp*sin(w*T(i-1)))*ic1

		if p(i-1) le isn/(isn+ic1) then begin;+ to ++
			x34(nx34)=T(i-1)+dt
			nx34+=1
			nne+=1 ;current flow
			E(i)=4
		end else begin
			X31(nx31)=T(i-1)+dt ;+ to X1
			nx31+=1
			E(i)=1
		end
	end

	;++ state
	if E(i-1) eq 4 then begin
		;dt=1D-12*getdt(tmes4,1D12*(T(i-1) mod period),pt(i-1))
		dt=capt2*k*pt(i-1) ;++ to X2
		X42(nx42)=T(i-1)+dt
		nx42+=1
		E(i)=2
	end
	T(i)=T(i-1)+dt
end


return, {T:T,E:E,X03:X03(0:nx03-1),X10:X10(0:nx10-1),X23:X23(0:nx23-1),X21:X21(0:nx21-1),X34:X34(0:nx34-1),X42:X42(0:nx42-1),X31:X31(0:nx31-1),nne:nne}
end


function qstate,nn,n,t1,t2,amp,p2,capt1,capt2,capt3,capt4,thr,moc,k,nb=nb,plt=plt,plasmon=plasmon
if keyword_set(plt) then !P.multi=[0,1,2]

w=2*!PI*200D6

if not(keyword_set(nb)) then nb=64
tmes=dblarr(5,500000L)
print,'generating integrals'
tmes(0,*)=qstate_gentime0(amp,1/k,w,500000L)
tmes(4,*)=qstate_gentime0(amp,1/(k*capt2),w,500000L)
;plot,tmes(0,*)
tmes(2,*)=qstate_gentime2(amp,1./(k*capt3),1./t2,w,500000L)
tmes(3,*)=qstate_gentime3(amp,1./(k*p2),1./(capt1*k),w,500000L,thr,moc)

;plot,tmes(3,*),color=255


tmes(1,*)=qstate_gentime1(1./(capt4*k),1/t1,w,500000L,thr,moc)
print,'..done'

h01t=-1
h02t=-1
h10t=-1
h20t=-1
catt=-1
dcatt=-1

for i=0,nn-1 do begin
	r=qstate_model1(n,t1,t2,amp,p2,capt1,capt2,capt3,capt4,thr,moc,k,tmes,plasmon=plasmon)


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

	plot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[catt,catt],color=170,yst=1
	oplot,findgen(n_elements(h01t)*2.)/n_elements(h01t)*5.,[h01t,h01t]
	oplot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[h10t,h10t],color=255	
	plots,[5.,5.],[min(h10t),max(h10t)]
	plots,[0.,10.],[mean(h10t),mean(h10t)]

;	plot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[dcatt,dcatt],color=170
	

	;plot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[dcatt,dcatt],color=170,yst=1
	;oplot,findgen(n_elements(h02t)*2.)/n_elements(h02t)*5.,[h02t,h02t];,yst=1
	plot,findgen(n_elements(h20t)*2.)/n_elements(h20t)*5.,[h20t,h20t],color=255

	end
;help,i
;help,r
;print,r.T(-1)
Ieff=(double(r.nne)/double(r.T(-1)))/6.22D18
print,'I_eff=',(double(r.nne)/double(r.T(-1)))/6.22D18
end
;	plot,findgen(n_elements(h01t)*2.)/n_elements(h01t)*5.,[h01t,h01t],yst=1
;	oplot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[h10t,h10t],color=255

;	plot,findgen(n_elements(h02t)*2.)/n_elements(h02t)*5.,[h02t,h02t],yst=1
;	oplot,findgen(n_elements(h20t)*2.)/n_elements(h20t)*5.,[h20t,h20t],color=255





t=findgen(n_elements(h10t))/n_elements(h10t)*5.

return, {h01:h01t,h10:h10t,h02:h02t,h20:h20t,catt:catt,dcatt:dcatt,t:t,I:Ieff}
end


pro qstate_find,fset,ampl
;pset - parameters
;fset - indices of parameters to optimize
dark=70.
pts=64

window,0,xs=400,ys=400

!p.multi=[0,1,2]
plot,findgen(10)
plot,findgen(10)



f='PLS-2.dat'
d='/home/martin/sync/data/CuPC/2020-04-06/'

o=loadpicoharp(d+f)
e1=overlay_picoharp(o,2,5.,rep=1)
e2=overlay_picoharp(o,7,5.,rep=1)
help,e1,/st
help,e2,/st


y1=shift(smooth(e1.i-dark,10,/edge),-443)
x1=e1.t
y2=shift(smooth(e2.i-dark,10,/edge),-443)
x2=e2.t


y1=congrid(y1,pts,cubic=-0.5)
y2=congrid(y2,pts,cubic=-0.5)
x1=5.*findgen(pts)/double(pts)
x2=x1
help,x1

;plot,[x1,x1+5.],[y1,y2],yst=1


a=read_file(d+f+".5.fit",/array)

aa=a(-1)
aa=strsplit(aa,/extract)
pset=float(aa(0:11))
cr=float(aa(12))

print,'Initial values'
print,pset
print,"Correlation coeff: ",cr
nf=n_elements(fset)
reuse=0


q=qstate(4,400000L,pset[0],pset[1],pset[2],pset[3],pset[4],pset[5],pset[6],pset[7],pset[8],pset[9],pset[10],nb=pts)
;c=ccor(y1,q.h20)
;w=where(cc eq max(cc))
;w(0)=0 ;override
;help,w(0)
y2s=y2;shift(y2,w(0))
y1s=pset[11]*y1;shift(y1,w(0))

ncr=qstate_corsigs(y1s,y2s,q.h20,q.h10)
print,"Correlation coeff: ",ncr,"  / Best so far: ",cr	

	print,"Effective current: ",q.i
cr=ncr

;plot,[x1,x1+5.],[y2s,y2s],/nodata,yst=1
plot,[x1,x1+5.],[y1s,y1s],yst=1
oplot,[q.t,q.t+5.],double([q.h20,q.h20])/max([q.h20,q.h10])*max([y2s,y1s]),color=255
plot,[x1,x1+5.],[y2s,y2s],yst=1
oplot,[q.t,q.t+5.],double([q.h10,q.h10])/max([q.h20,q.h10])*max([y2s,y1s]),color=255


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
	

	q=qstate(4,400000L,npset[0],npset[1],npset[2],npset[3],npset[4],npset[5],npset[6],npset[7],npset[8],npset[9],npset[10],nb=pts)
;	help,q,/st

	cc=ccor(y1,q.h20)
	w=where(cc eq max(cc))
;	help,w(0)
	w(0)=0
	y2s=y2;shift(y2,w(0))
	y1s=npset[11]*y1;shift(y1,w(0))

	ncr=qstate_corsigs(y1s,y2s,q.h20,q.h10)



	print,"Correlation coeff: ",ncr,"  / Best so far: ",cr	
	if ncr gt cr then begin
		pset=npset
		cr=ncr
		openw,1,d+f+".5.fit",/append,width=1024
		printf,1,[pset,cr,q.i]
		close,1
		print,"IMPROVING! try again.."
		reuse=1

		print,"Effective current: ",q.i
		;plot,[x1,x1+5.],[y2s,y2s],/nodata,yst=1
		plot,[x1,x1+5.],[y1s,y1s],yst=1
		oplot,[q.t,q.t+5.],double([q.h20,q.h20])/max([q.h20,q.h10])*max([y2s,y1s]),color=255

		plot,[x1,x1+5.],[y2s,y2s],yst=1
		oplot,[q.t,q.t+5.],double([q.h10,q.h10])/max([q.h20,q.h10])*max([y2s,y1s]),color=255





	end else begin
		print,"Nope.. try again.."
	end


end until file_test(d+'stop') ne 0

print,'Found stop file, stopping now.'

end

function qstate_corsigs,y1,y2,q1,q2

q1=double(q1)
q2=double(q2)

cc=ccor(y1,y2)

;w=where(cc eq max(cc))

t1=total((y1 - q1/max([q1,q2])*max([y2,y1]) )^2,/double)

t2=total((y2 - q2/max([q1,q2])*max([y2,y1]) )^2,/double)


;plot,[y1,y2]
;plot,[q1,q2]

;cr=correlate([y1,y2,y2],[q1,q2,q2],/double)

return,1./(0.25*t1+1.75*t2)
return,cr

end

