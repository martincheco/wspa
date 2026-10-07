function mol_distrib,origvect,it,r,a
;plot,origvect
vect=origvect
n=n_elements(vect)
help,vect
t=0L
dt=0L
while t lt it do begin
vect=specialconvol3(vect,r)
t=t+1L
    ;if dt lt 100 then dt=dt+1 else begin
;	dt=0
;	print,t
;    end
end

return,vect
end


function specialconvol,vect,r,c
newvect=vect
n=n_elements(vect)
;if vect(0) ne 0 then 
newvect(0)=r*vect(1)-r*vect(0)+vect(0)+r*c

;else newvect(0)=r*vect(1)+vect(0)

for i=1,n-2 do begin
    ;if vect(i) ne 0 then 
    newvect(i)=vect(i)+r*vect(i-1)+r*vect(i+1)-2*r*vect(i) 
    ;else newvect(i)=r*vect(i-1)+r*vect(i+1)+vect(i)
end

;if vect(n-1) ne 0 then 
newvect(n-1)=r*vect(n-2)-r*vect(n-1)+vect(n-1) 
;else newvect(n-1)=r*vect(n-2)+vect(n-1) 

return,newvect
end

function specialconvol2,vect,r
newvect=vect
n=n_elements(vect)
sum=total(vect(1:*))
newvect(0)=vect(0) + 2*r*(-sum*vect(0) + sum - vect(0)) ;the pool
;newvect(1)=vect(1) + 2*r*(vect(0)*vect(0)+vect(2)-vect(1))
for i=1,n-2 do begin
    newvect(i)=vect(i) + 2*r*(vect(0)*vect(i-1) + vect(i+1) - vect(i))
end

norm=total(newvect*(indgen(n)+1))
print,norm
newvect=newvect/norm ; renorm

return,newvect
end


function specialconvol3,vect,r
newvect=vect
n=n_elements(vect)
sum=total(vect(1:*))
;newvect(1)=vect(1) + 2*r*(vect(0)*vect(0)+vect(2)-vect(1))
for i=1,n-2 do begin
    newvect(i)=vect(i) + 2*r*(vect(0)*vect(i-1) + vect(i+1) - vect(i))
end

norm=total(newvect(1:*)*(findgen(n-1)+2))

newvect(0)=(1.-norm)

print,norm
;newvect=newvect/norm ; renorm

return,newvect
end