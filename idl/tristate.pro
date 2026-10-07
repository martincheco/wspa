function tristate_model1,n,t1,t2,p1,p2,amp,current,thr
;n - number of jumps

;k = 1.6D-9 ;mean time/electron at V0

k = (6.22D18*current)^(-1)
help,k
;might be neccessary to divide by two!!
;p1 = 0.1 ;modulation of probability of x1
;p2 = 0.6 ;modulation of probalbilty of x2
;t1 - time decay from x1
;t2 - time decay from x2
f = 200D6 ;modulation frequency
;amp= 0.25; base amplitude of probabilty X1
;thr = 0.1 ;threshold for sine


n=long(n)

kt=-alog(randomu(seed,n))*k ;the distribution of time intervals it takes to excite from S0 state at V0

p=randomu(seed,n) ;Monte Carlo of going to X1 or X2

rt1=randomu(seed,n)
rt2=randomu(seed,n)

pt1=-alog(rt1)*t1
pt2=-alog(rt2)*t2 ;the intervals of decay

T=dblarr(n+1) ;array to store event times
E=intarr(n+1) ;array to store states
X01=T ;arrays storing the events corresponding to excitation
X02=T ;arrays storing the events corresponding to excitation
X10=T ;decay from X1 (measurable as photon)
X20=T ;decay from X2 (measurable as photon)


T(0)=0L
E(0)=0L

nx01=0L ;total number of transitions for each
nx02=0L
nx10=0L
nx20=0L
nne=0L ; total number of excitations (electrons)

;assuming state zero at the beginning

for i=1,n do begin

	dt=0. ;initialize time interval

	;ground state
    	if E(i-1) eq 0 then begin
	       	w=2D*!PI*f
		;time it takes to try excitation starting from S0, modulated by sine
		dt=kt(i-1)
		;isn=(-cos(w*(T(i-1)+dt))+cos(w*T(i-1)))/(w*dt) ;integrated in the interval T_i..T_i-1 and divided by dt
		isn=sin(w*T(i-1)+dt)^1.8
		sn=sin(w*T(i-1)+dt) ;modulation
		;X2 excitation - only possible for sine above zero!
       		pp2=p2*((isn>thr)-thr)
		if p(i-1) le pp2 then begin
			E(i)=2
			X02(nx02)=T(i-1)+dt; moment of excitation
			nx02=nx02+1
		end
	

		;X1 excitation
		pp1=amp+p1*sn
	
		if p(i-1) gt pp2 and p(i-1) le pp1 then begin 
			E(i)=1
			X01(nx01)=T(i-1)+dt; moment of excitation
			nx01=nx01+1
		end

		nne=nne+1

		
	end
		
	;X1 state
	if E(i-1) eq 1 then begin
		dt=pt1(i-1) ;time it takes to decay from X1 to G0
		E(i)=0
		X10(nx10)=T(i-1)+dt; moment of decay from X1
		nx10=nx10+1
	end

	;X2 state
	if E(i-1) eq 2 then begin
		dt=pt2(i-1) ;time it takes to decay from X1 to G0
		E(i)=0
		X20(nx20)=T(i-1)+dt; moment of decay from X2
		nx20+=1
	end


	T(i)=T(i-1)+dt

end


return, {T:T,E:E,X01:X01(0:nx01-1),X02:X02(0:nx02-1),X10:X10(0:nx10-1),X20:X20(0:nx20-1),nne:nne}
end


function tristate,nn,n,t1,t2,p1,p2,amp,current,thr
!P.multi=[0,1,2]

h01t=-1
h02t=-1
h10t=-1
h20t=-1


for i=0,nn-1 do begin
	r=tristate_model1(n,t1,t2,p1,p2,amp,current,thr)

	h10=histogram(r.X10*1D12 mod 5000D,nbins=128,max=5000D)
	h01=histogram(r.X01*1D12 mod 5000D,nbins=128,max=5000D)
	h20=histogram(r.X20*1D12 mod 5000D,nbins=128,max=5000D)
	h02=histogram(r.X02*1D12 mod 5000D,nbins=128,max=5000D)

	if h01t(0) ne -1 then h01t=h01t+h01 else h01t=h01
	if h10t(0) ne -1 then h10t=h10t+h10 else h10t=h10
	if h02t(0) ne -1 then h02t=h02t+h02 else h02t=h02
	if h20t(0) ne -1 then h20t=h20t+h20 else h20t=h20


;	plot,findgen(n_elements(h01)*2.)/n_elements(h01)*5.,[h01,h01],yst=1
;	oplot,findgen(n_elements(h10)*2.)/n_elements(h10)*5.,[h10,h10],color=255

;	plot,findgen(n_elements(h02)*2.)/n_elements(h02)*5.,[h02,h02],yst=1
;	oplot,findgen(n_elements(h20)*2.)/n_elements(h20)*5.,[h20,h20],color=255

	help,h10
	help,h20

	plot,findgen(n_elements(h01t)*2.)/n_elements(h01t)*5.,[h01t,h01t],yst=1
	oplot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[h10t,h10t],color=255

	plot,findgen(n_elements(h02t)*2.)/n_elements(h02t)*5.,[h02t,h02t],yst=1
	oplot,findgen(n_elements(h20t)*2.)/n_elements(h20t)*5.,[h20t,h20t],color=255

help,i
help,r
print,r.T(-1)
print,'I_eff=',(double(r.nne)/double(r.T(-1)))/6.22D18
end
	plot,findgen(n_elements(h01t)*2.)/n_elements(h01t)*5.,[h01t,h01t],yst=1
	oplot,findgen(n_elements(h10t)*2.)/n_elements(h10t)*5.,[h10t,h10t],color=255

	plot,findgen(n_elements(h02t)*2.)/n_elements(h02t)*5.,[h02t,h02t],yst=1
	oplot,findgen(n_elements(h20t)*2.)/n_elements(h20t)*5.,[h20t,h20t],color=255



!P.Multi=0

return, {h01:h01t,h10:h10t,h02:h02t,h20:h20t}
end
