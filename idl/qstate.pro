function qstate_model1,n,t1,t2,amp,p2,irate,phase=phase
;n - number of jumps

;k = 1.6D-9 ;mean time/electron at V0

k = irate
help,k
;might be neccessary to divide by two!!
;p1 = 0.1 ;modulation of probability of x1
;p2 = 0.6 ;modulation of probalbilty of x2
;t1 - time decay from x1
;t2 - time decay from x2
f = 200D6 ;modulation frequency
;amp= 0.25; voltage mod.
;thr = 0.1 ;threshold for sine

if keyword_set(phase) then ph=phase else ph=0

n=long(n)

pt=-alog(randomu(seed,n)) ;the unscaled distribution of time intervals

p=randomu(seed,n) ;Monte Carlo of going from + to either ++ or X1

T=dblarr(n+1) ;array to store event times
E=intarr(n+1) ;array to store states

X03=T 
X10=T 
X23=T 
X34=T 
X31=T 
X42=T

T(0)=0D
E(0)=0L

nx03=0L ;total number of transitions for each
nx10=0L
nx23=0L
nx34=0L
nx31=0L
nx42=0L
nne=0L ; total number of excitations (electrons)

;assuming state zero at the beginning

w=2D*!PI*f

for i=1L,n do begin

;	dt=0. ;initialize time interval

	;ground state
    	if E(i-1) eq 0 then begin
		sn=sin(w*(T(i-1))) ;modulation
		dt=k*pt(i-1)/(1.+amp*sn);0 to +
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
		dt=t2*pt(i-1) ;X2 to +
		X23(nx23)=T(i-1)+dt; moment of decay from X2
		nx23+=1
		E(i)=3
	end

	;+ state
	if E(i-1) eq 3 then begin
		sn=sin(w*(T(i-1)))
		if p(i-1) le p2*((((sn)>0.4)-0.4)^1.5) then begin;+ to ++
			dt=k*pt(i-1)/(1.+amp*sn)
			x34(nx34)=T(i-1)+dt
			nx34+=1
			nne+=1 ;current flow
			E(i)=4
		end else begin
			dt=k*pt(i-1) ;+ to X1
			X31(nx31)=T(i-1)+dt
			nx31+=1
			E(i)=1
		end
	end

	;++ state
	if E(i-1) eq 4 then begin
		dt=k*pt(i-1) ;++ to X2
		X42(nx42)=T(i-1)+dt
		nx42+=1
		nne+=1 ;current flow
		E(i)=2
	end


	T(i)=T(i-1)+dt

end


return, {T:T,E:E,X03:X03(0:nx03-1),X10:X10(0:nx10-1),X23:X23(0:nx23-1),X34:X34(0:nx34-1),X42:X42(0:nx42-1),X31:X31(0:nx31-1),nne:nne}
end


function qstate,nn,n,t1,t2,amp,p2,current,nb=nb,plt=plt
!P.multi=[0,1,2]

if(not(keyword_set(nb))) then nb=64

h01t=-1
h02t=-1
h10t=-1
h20t=-1
catt=-1
dcatt=-1

for i=0,nn-1 do begin
	r=qstate_model1(n,t1,t2,amp,p2,current)


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

	help,h10
	help,h20
	
	if keyword_set(plt) then begin

	plot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[catt,catt],color=170,yst=1
	oplot,findgen(n_elements(h01t)*2.)/n_elements(h01t)*5.,[h01t,h01t]
	oplot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[h10t,h10t],color=255
;	oplot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[dcatt,dcatt],color=170
	

	plot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[dcatt,dcatt],color=170,yst=1
	oplot,findgen(n_elements(h02t)*2.)/n_elements(h02t)*5.,[h02t,h02t];,yst=1
	oplot,findgen(n_elements(h20t)*2.)/n_elements(h20t)*5.,[h20t,h20t],color=255

	end
help,i
help,r
print,r.T(-1)
print,'I_eff=',(double(r.nne)/double(r.T(-1)))/6.22D18
end
;	plot,findgen(n_elements(h01t)*2.)/n_elements(h01t)*5.,[h01t,h01t],yst=1
;	oplot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[h10t,h10t],color=255

;	plot,findgen(n_elements(h02t)*2.)/n_elements(h02t)*5.,[h02t,h02t],yst=1
;	oplot,findgen(n_elements(h20t)*2.)/n_elements(h20t)*5.,[h20t,h20t],color=255



!P.Multi=0

t=findgen(n_elements(h10t))/n_elements(h10t)*5.

return, {h01:h01t,h10:h10t,h02:h02t,h20:h20t,catt:catt,dcatt:dcatt,t:t}
end
