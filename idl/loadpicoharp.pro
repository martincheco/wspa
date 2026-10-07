
function overlay_picoharp,r,chan,period,rep=rep
;period in nanoseconds

x=reform(r.x(chan,0:-2))
dt=double(r.dt(chan))*1000

help,dt
li=lindgen(n_elements(x))

xx=(li*dt) mod (long(period*1000));working in picoseconds
s=sort(xx)
xx=xx(s)

yy=reform(r.data(chan,0:-2))
yy=yy(s)


u=uniq(long(xx))
help,u
n=n_elements(u)

ynew=dblarr(n)
xnew=dblarr(n)
;average and remove multiplicate points
for i=0,n-2 do begin
	xnew(i)=xx(u(i))
	ynew(i)=mean(yy(u(i):u(i+1)-1),/double)
end

ynew(n-1)=mean(yy(u(n-1):-1))
xnew(n-1)=xx(-1)
xnew=xnew/1000.

if keyword_set(rep) then begin
	nn=n_elements(xnew)

	xnewr=xnew
	ynewr=ynew

	for j=1,rep-1 do begin
		xnewr=[xnewr,xnew+j*period]
		ynewr=[ynewr,ynew]
	end
	xnew=xnewr
	ynew=ynewr
end

return,{t:xnew,i:ynew,period:period}
end


function selchan_picoharp,r,chan

i=r.data(chan,*)
t=r.x(chan,*)

w=where(i ne 0)

i=i(0:max(w)-1)
t=t(0:max(w)-1)

return,{t:t,i:i}
end

pro sinewave_picoharp,x,a,f
common share1,T

sn=sin(2*!PI/T*(x-a(1)))
f=a(0)*sn
print,a
end

pro X1wave_picoharp,x,a,f
common share1,T

sn=sin(2*!PI/T*(x-2.95))
sn=((sn>0.)-0.)^1.5
e=exp(-x/0.08)
e=e/max(e)
sn2=real_part(conv(sn,e))

e=exp(-x/0.7)
e=e/max(e)
sn2=real_part(conv(sn2,e))
sn2=sn2/max(sn2)

f=a(0)*sn2+a(1)
print,a
end




pro sinewave_picoharp_pol,x,a,f
common share1,T
;built for 200MHz
sn=sin(2*!PI/T*(x-a(1)))
f=a(0)*sn+a(2)*sn^2+a(3)*sn^3+a(4)*sn^4+a(5)
;f=a(0)*(sn+1)^a(2) + a(3)      ;a(2)*sn^a(3)*sn^3+a(4)*sn^4+a(5)
print,a
end


pro qstate_picoharp,x,a,f
common share2, T,tt,ii
print,a
q=qstate(10,1000000L,500D-12, 50D-12,a(2),a(3),200D-12, nb=n_elements(x)/2,phase=a(1))

f=a(0)*[q.h10,q.h10]

;help,tt
;help,x

plot,x,ii
oplot,x,f,color=200

end


pro anticorrwave_picoharp,x,a,f
common share1,T

;a(0)=(a(0)>0.1)<1.0
;a(1)=(a(1)>2000.)<50000.
;a(4)=(a(4)>0)<0.8

;carrier 
sn=sin(2*!PI/T*(x-3.0));a(2)))


;X1 absorption
f1=(1.-a(0))*sn
;X2 absorption
sn2=((sn>(0.))-0.)^1.5

;sn2=0.15*sn2^2+0.5*sn2


f2=a(0)*(sn2);+2*sn2^2)

e=exp(-x/a(3))
e=e/max(e)

;f=a(1)*real_part(conv(f1-f2,e))+a(5)
rc=real_part(conv(f1-f2,e));/max(abs(conv(f1,e)))
rc=rc/max(abs(rc))
;f=a(1)*(f1-f2)+a(2)

e=exp(-x/.85)
e=e/max(e)


rc=real_part(conv(rc,e));/max(abs(conv(f1,e)))
rc=rc/max(abs(rc))

f=a(1)*(real_part(rc))+a(2)
;oplot,x,f,color=200
print,a
end

function fit2_picoharp,d,period
;period is the sine period
;tries to fit the special anticorrelated type function
common share1,T
T=period
	c=[0.5,500.,50.,.2];,mean(d.i)]
	;0 - probability of X2
	;1 - overall amplitude
       	;2 - offset 	
	;3 - X2 threshold (percent of sine amplitude)
	;4 - X1 lifetime

plot,d.t,d.i-mean(d.i),yst=1,xst=1

	yfit=curvefit(d.t,d.i-mean(d.i),undef,c,function_name='anticorrwave_picoharp',/noderivative,/double,status=status,chisq=chisq,itmax=10000)
	;print,status

	
if status ne 0 then print, "FIT NOT SUCCESFUL!!!!!!!"
anticorrwave_picoharp,d.t,c,bla
common share1, T
oplot,d.t,bla,color=200,thick=4
;c0=c
;c0(0)=.0
;c0(3)=.00001
;anticorrwave_picoharp,d.t,c0,bla2

;plot,d.t,bla2,color=120,thick=2,yst=1,xst=1

;oplot,d.t,d.i-mean(d.i)
;oplot,d.t,bla,color=200,thick=4

return,{t:d.t,i:d.i,ifit:bla,par:c}
end

function fit3_picoharp,d,period,nx
;period is the sine period
;tries to fit the special anticorrelated type function
common share2,T,tt,ii
T=period
	c=[0.003,12.,0.2,0.2];,mean(d.i)]



tt=congrid(d.t,nx)
ii=congrid(d.i,nx)



	yfit=curvefit(tt,ii,undef,c,function_name='qstate_picoharp',/noderivative,/double,status=status,chisq=chisq,itmax=10000)
	;print,status

	
if status ne 0 then print, "FIT NOT SUCCESFUL!!!!!!!"
qstate_picoharp,tt,c,bla
;common share1, T
plot,tt,ii
oplot,tt,bla,color=200
;c0=c
;c0(0)=.0
;c0(3)=.00001
;anticorrwave_picoharp,d.t,c0,bla2

;plot,d.t,bla2,color=120,thick=2,yst=1,xst=1

;oplot,d.t,d.i-mean(d.i)
;oplot,d.t,bla,color=200,thick=4

return,{t:d.t,i:d.i,ifit:bla,par:c}
end


function fitX1_picoharp,d,period
;period is the sine period
;tries to fit the special anticorrelated type function
common share1,T
T=period
	c=[250.,83.];,mean(d.i)]

plot,d.t,d.i,yst=1,xst=1

	yfit=curvefit(d.t,d.i,undef,c,function_name='X1wave_picoharp',/noderivative,/double,status=status,chisq=chisq,itmax=10000)
	;print,status

if status ne 0 then print, "FIT NOT SUCCESFUL!!!!!!!"
X1wave_picoharp,d.t,c,bla
common share1, T
oplot,d.t,bla,color=200,thick=4

return,{t:d.t,i:d.i,ifit:bla,par:c}
end

function delay_picoharp,d,neg=neg
;neg is for negative voltage
period=d.period
sn=sin(2*!PI/period*d.t)
if keyword_set(neg) then fact=-1. else fact=1.

c=ccor(sn,fact*d.i)

mx=where(c eq max(c))
print,mx

del=d.t(mx(0)) mod period

sn=sin(2*!PI/period*(d.t-del))

in=fact*(d.i-mean(d.i))/(max(d.i-mean(d.i)))
in=in/variance(in)/2./(2.^0.5)

return,{delay:del,t:d.t,i:d.i,c:c,cn:c/max(c),in:in,period:period,sn:sn}
end


function fit_picoharp,d,period,pol=pol
;period is the sine period
;poly switches on polynomial fit
common share1,T
T=period
if keyword_set(pol) then begin
	c=[100.,0.,0.,0.,0.,0.]
	yfit=curvefit(d.t,d.i-mean(d.i,/double),undef,c,function_name='sinewave_picoharp_pol',/noderivative,/double,status=status,chisq=chisq,itmax=10000)
	;print,status
end else begin
	c=[100.,0.]
	yfit=curvefit(d.t,d.i-mean(d.i,/double),undef,c,function_name='sinewave_picoharp',/noderivative,/double,status=status,chisq=chisq,itmax=10000)
	;print,status

end
	
	
plot,d.t,d.i-mean(d.i,/double),yst=1,xst=1
if status ne 0 then print, "FIT NOT SUCCESFUL!!!!!!!"
if not(keyword_set(pol)) then sinewave_picoharp,d.t,c,bla else sinewave_picoharp_pol,d.t,c,bla
common share1, T
oplot,d.t,bla,color=255
;if (c(1) mod T) gt T/2 then c(1)=c(1)-T/2
;print,c(1), (c(1) mod T)



;if c(0) lt 0 then begin 
;	c(0)=-c(0) 
;	c(1)=c(1)+T/2
;end

;c(1)=c(1) mod T
;if c(1) lt 0 then c(1)=c(1)+T
;c(1)=c(1) mod T
;print,c
sinewave_picoharp,d.t,c,bla
;oplot,d.t,bla,color=128


return,{t:d.t,i:d.i,tau:c(1),amp:c(0),chisq:chisq}
end

pro export_picoharp,t,period=period,chan=chan,pol=pol

if not(keyword_set(chan)) then chan=indgen(n_elements(t.dt))
if n_elements(period) eq 1 then period=dblarr(n_elements(chan))+period
if not(keyword_set(period)) then period=dblarr(n_elements(chan))+5.


openw,2,t.f+'.fit',width=1024
tab=String(9B)
printf,2,"Tau",tab,"Amp",tab,"ChiSq",tab,"Period",tab,"Freq"


for i=0,n_elements(chan)-1 do begin
	d=selchan_picoharp(t,chan(i))
	df=fit_picoharp(d,period(i),pol=pol)

	openw,1,t.f+'.'+strtrim(string(chan(i)),2)+'_'+string(df.tau*1000.,format='(F5.0)')+'_'+string(df.chisq,format='(F5.0)'),width=1024
	

	print,"Delay:",df.tau,"     Amp:",df.amp,"     Chisq:",df.chisq,"    Period:",period(i)
	printf,2,df.tau,df.amp,df.chisq,period(i),1D9/period(i)

	avg=mean(df.i,/double)
	for j=0,n_elements(d.i)-1 do begin 
		printf,1,d.t(j),d.i(j),df.i(j)-avg,df.i(j)
	end
	close,1
end

close,2

end



function loadpicoharp,f
if not(keyword_set(f)) then f=dialog_pickfile()


openr,1,f

a=""
hdr=""
dt=""
len=""
readf,1,hdr
print,hdr
readf,1,a
readf,1,len
len=long(len)
help,len
readf,1,a
readf,1,a
readf,1,a
readf,1,a
readf,1,a

readf,1,dt

print,dt
dt=strsplit(dt,/extract)
help,dt
print,dt

readf,1,a

data=intarr(n_elements(dt)+1,len)

readf,1,data

close,1

data=data(0:-2,*)

w=where(total(data,1) gt 0)

help,total(data,1)

help,w

if w(0) ne -1 then data=data(*,0:max(w)) else data=data


x=double(data)
for i=0,n_elements(dt)-1 do begin
	x(i,*)=dindgen(max(w)+1)*dt(i)
end

return,{f:f,data:data,x:x,dt:dt,hdr:hdr}
end


pro write_picoharp,d,f

help,d

n=n_elements(d.t)

openw,2,f,width=2096


for i=0,n-1 do begin

	printf,2,d.t(i),d.i(i),d.in(i),d.sn(i),real_part(d.c(i)),real_part(d.cn(i))

end

close,2



openw,2,f+'.par'


;printf,2,'path:',d.f
printf,2,'period:',d.period
printf,2,'delay:',d.delay
printf,2,'period:',d.period
printf,2,'total:',total(d.i)




close,2




end
