function walk,n,t
vals=lonarr(n)

for j=0L,n-1 do begin
    wlk=0L
    for i=1L,t do wlk=(wlk+(round(2*randomu(seed,1)-1.0)))>0
    ;print,wlk
    vals(j)=wlk
end

return,vals
end

function walk2,n,t
vals=lonarr(n)

for j=0L,n-1 do begin
    wlk=0L
    wlk=total(round(2*randomu(seed,t)-1))
    vals(j)=wlk
end
print,"Finished"
return,vals
end


function walk3,n,t,init
vals=lonarr(n)

for j=0L,n-1 do begin
    wlk=init
    for i=1,t do wlk=(wlk+sgn(2*randomu(seed,1)-1.0)) >2
    vals(j)=wlk
end
print,"Finished"
return,vals
end

function walk4,n,t
vals=lonarr(n)

for j=0L,n-1 do begin
    wlk=2
    tt=0.
    while tt lt t do begin
	wlk=(wlk+sgn(2*randomu(seed,1)-1.0)) >2
	tt=tt+randomu(seed,1,/gamma)
    end
    vals(j)=wlk
end
print,"Finished"
return,vals
end

function genh,lo,hi,step
hist=dblarr(100,float(hi-lo)/step+1.)
j=0

for i=lo,hi,step do begin
    print,"Interval #",i
    ht=walk4(99999,i)
    hist(*,j)=histogram(ht,min=0,binsize=1.,max=99)
;    help,hist(*,j)
;    help,histogram(ht,min=0,binsize=1.,max=99)
    
    if i eq lo then plot,hist(*,j)/total(hist(*,j)) else oplot,hist(*,j)/total(hist(*,j))
    j=j+1
end

return,hist
end

function optimize,hr,ht,alo,ahi,suma=suma
;help,hr
;help,ht


while 1 do begin
    

    sum=dblarr(10)
    a=findgen(10)*(ahi-alo)/10.+alo
;    help,a
;    print,a
    
    for i=0,9 do begin
	sum(i)=total((a(i)*ht-hr)^2)
    end
    
    w=where(sum eq min(sum))
    if abs(alo-ahi) lt 1E-5 then break
    
    
    alo=a((w(0)-1)>0)
    ahi=a((w(0)+1)<9)

end
suma=total(((alo+ahi)/2.*ht-hr)^2)
return,(alo+ahi)/2.
end

function getmin,hr,htarr
n=n_elements(hr)
s=size(htarr)
sm=dblarr(s(2))
opt=sm
for i=0,s(2)-1 do begin
    opt(i)=optimize(hr,htarr(0:n-1,i),0,100,suma=suma)
    sm(i)=suma
    print,opt(i),sm(i)
end


w=where(sm eq min(sm))
print,"best match:"
print,w(0),opt(w(0)),sm(w(0))
return,opt(w(0))*htarr(0:n-1,w(0))
end






function walkdemo,t,seed
wlk=intarr(10*t)
tt=fltarr(10*t)
wlk(0)=2
tt(0)=0.
i=1
    while tt(i-1) lt t do begin
	wlk(i)=(wlk(i-1)+sgn(2*randomu(seed,1)-1.0)) >2
	tt(i)=tt(i-1)+randomu(seed,1,/gamma)
	print,i
	i=i+1
    end
return,[[tt(0:i-1)],[wlk(0:i-1)]]
end
