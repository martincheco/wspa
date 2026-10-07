
function dzfilt,t,w=w,s=s
;filters the curve by savitzky-golay, rough resampling and spline interpolation
;w is filter width, s number of splines for resampling
i=sort(t.x)
x=t.x(i)
y=t.y(i)
y=dezofilter(x,y,width=w,splines=s)
return,{x:x,y:y}
end

function df2f_alt_3d,dfo,k=k,dz=dz,n=n,fres=fres
if not(keyword_set(fres)) then fres=1e6 ;resonance freq in Hz
if not(keyword_set(n)) then n=4; amplitude in dz 
if not(keyword_set(k)) then k=5E5; stiffness 
if not(keyword_set(dz)) then dz=5e-12; [m]

s=size(dfo)

a=dz*n; conversion to m

;x in meters
;y in Hz
nn=s(1)

;subtraction and normalization
df=(dfo-total(dfo(nn-1,*,*),/double)/s(2)/s(3))/fres
x=dindgen(nn)*dz
help,df
;differentiation
y=shift(df,-1,0,0)
dy=(y-df)/dz
dy=dy(0:nn-2,*,*)
x=x(0:nn-2)

;integration
summ=0D
force=dy*0D
for i=0,nn-2 do begin
    for j=i+1,nn-2 do begin
	summ = summ + (1. + (a / (!PI*(x(j)-x(i))))^0.5/8.)*y(j,*,*) - (a^1.5)/((2*(x(j)-x(i)))^0.5)*dy(j,*,*)
    end
	print,i,'/',nn-2
    force(i,*,*)=dz*2*k*summ ;calibration by k and step width
    ;reset the sum
    summ=0D
end

return,force
end



function df2f_alt_inner,dfo,k=k,dz=dz,n=n,fres=fres
if not(keyword_set(fres)) then fres=1e6 ;resonance freq in Hz
if not(keyword_set(n)) then n=4; amplitude in dz 
if not(keyword_set(k)) then k=5E5; stiffness 
if not(keyword_set(dz)) then dz=5e-12; [m]
print,'f0',fres
print,'a',n*dz
print,'dz',dz
print,'k',k
print,'n',n
s=size(dfo)

a=dz*n; conversion to m

;x in meters
;y in Hz
nn=n_elements(dfo)

;subtraction and normalization
df=(dfo-dfo(nn-1))/fres
x=dindgen(nn)*dz

;differentiation
y=shift(df,1)
dy=(y-df)
dy=dy(1:nn-1)
x=x(1:nn-1)
y=y(1:nn-1)

;integration
force=x*0D
for i=0,nn-2 do begin
	;reset the sum
	summ=0D
	for j=i+1,nn-2 do begin
		summ = summ + dz*y(j)*(1D + (a / 8D / (!PI*(x(j)-x(i)))^0.5)) - (a^1.5)/((2.*(x(j)-x(i)))^0.5)*dy(j)
    	end
	force(i)=2*k*summ ;calibration by k and step width
end

return,force
end

function df2f_alt,df,k=k,dz=dz,n=n,f0=f0
;works for arrays also, supposes z is the first index
s=size(df)
if s(0) eq 1 then nf=df2f_alt_inner(df,k=k,dz=dz,n=n,fres=fres)
if s(0) eq 2 then begin
	nf=df(0:-1,*)*(-0./0.)
	for i=0,s(2)-1 do nf(*,i)=df2f_alt_inner(reform(df(*,i)),k=k,dz=dz,n=n,fres=fres)
end
if s(0) eq 3 then begin
	nf=df(0:-2,*,*)*(-0./0.)
	nf=df2f_alt_3d(df,k=k,dz=dz,n=n,fres=fres)
end
return,nf
end
