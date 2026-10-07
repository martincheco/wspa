
function dzfilt,t,w=w,s=s
;filters the curve by savitzky-golay, rough resampling and spline interpolation
;w is filter width, s number of splines for resampling
i=sort(t.x)
x=t.x(i)
y=t.y(i)
y=dezofilter(x,y,width=w,splines=s)
return,{x:x,y:y}
end


function df2f,t,k=k,a=a,fres=fres
if not(keyword_set(fres)) then fres=20000 ;resonance freq in Hz
if not(keyword_set(a)) then a=15; amplitude in nm 
if not(keyword_set(k)) then k=1000; stiffness 

print,"stiffness",k
print,"amplitude [m]",a
print,"f_resonance",fres

a=a*1E-9; conversion to m

;x in meters
;y in Hz
x=t.x
y=t.y
n=n_elements(x)
i=sort(x) ;need to sort in order to have the last element the smallest
x=x(i)
y=y(i)


;subtraction and normalization
y=(y-y(n-1))/fres


;differentiation
dy=(shift(y,-1)-y)/(x(1)-x(0))
dy=dy(0:n-2)
x=x(0:n-2)
y=shift(y,-1)

;integration
summ=0D
force=x*0D
for i=0,n-2 do begin
    for j=i+1,n-2 do begin
	summ = summ + (1 + (a / (!PI*(x(j)-x(i))))^0.5/8.)*y(j) - (a^1.5)/((2*(x(j)-x(i)))^0.5)*dy(j)
    end

    force(i)=(x(1)-x(0))*2*k*summ ;calibration by k and step width
    ;reset the sum
    summ=0D
end

;help,t,/st
;return,force
return,{x:x,y:force}
end

