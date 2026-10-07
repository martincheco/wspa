function create_mosaic,n,c
f=randomu(seed,n*n)
f=fix(reform(f,n,n)+c)
return,f
end

function neighb,f
ff=shift(f,0,-1)+shift(f,-1,-1)+shift(f,-1,0)+shift(f,0,1)+shift(f,1,0)+shift(f,1,1)
s=size(f)
return,ff
end

function m_neighb,f
ff=neighb(f)*f
i=ff(where(f))

return,mean(i)

end


function n_neighb,f,b
ff=neighb(f)*f
ind=where(ff eq b)
if ind(0) then return,n_elements(ind) else return,0

end


function rnd_swp,ff
f=ff
s=size(f)
a1=fix(randomu(seed)*s(1))
b1=fix(randomu(seed)*s(2))
;print,a1,b1
a2=fix(randomu(seed)*s(1))
b2=fix(randomu(seed)*s(2))
;print,a2,b2


;print,f(a1,b1),f(a2,b2)
s=f(a2,b2)

f(a2,b2)=f(a1,b1)
f(a1,b1)=s
;print,f(a1,b1),f(a2,b2)

return,f
end

function reach_value,f,e,b,n

xd=n_neighb(f,b)
for i=0L,n-1 do begin
    for j=0L,e-1 do ff=rnd_swp(f)
	x=n_neighb(ff,b)
	if x gt xd then begin 
	    f=ff
	    print,x,xd
	    xd=x
	end
end
return,f
end



function b_reach_value,f,e,b,n
s=size(ff)
xd=n_neighb(f,b)
yd=n_neighb(1-f,b)

for i=0L,n-1 do begin
for j=0L,e-1 do ff=rnd_swp(f)
x=n_neighb(ff,b)
y=n_neighb((1-ff),b)
if (float(x+y) gt float(yd+xd))  then begin 
f=ff
print,x,xd,y,yd
xd=x
yd=y
end
end
return,f
end

function cords,f
s=size(f)
a=(3^0.5)/2
n=n_elements(f)
y=(indgen(n) / s(1)) *a
x=(indgen(n) mod s(1)) -y/2
res=fltarr(n,2)
res(0:n-1,0)=x
res(0:n-1,1)=y
res=res(where(f),*)
return,res
end


pro plotmos,ee
y=cords(ee)
plot,y(*,0),y(*,1),psym=2,/iso
end
