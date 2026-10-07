function reduce_angle,angle,half=half
;half reduces only to -30..30DEG
if not(keyword_set(half)) then rangle=30-abs(((angle +180) mod 60)-30) else rangle=(((angle) mod 60)) 
return,rangle
end

function module,i,j,a
a1=a*0.5*dcomplex(1.,-3.^0.5)
a2=a*0.5*dcomplex(1.,3.^0.5)
aa=a1*i+a2*j
return,abs(aa)
end

function vector,indexes
a1=0.5*dcomplex(1.,-3.^0.5)
a2=0.5*dcomplex(1.,3.^0.5)
aa=a1*real_part(indexes)+a2*imaginary(indexes)
return,aa
end

function spheres,dim,a,b

if not(keyword_set(a)) then a=2.774 ;Pt
if not(keyword_set(b)) then b=2.46 ;graphene

ix=lindgen((dim)^2)
ii=ix / (dim)
jj=ix mod (dim)
aa=vector(dcomplex(ii,jj))

;plot,real_part(lattice),imaginary(lattice),psym=3,/iso

aaa=abs(aa)
alat=aa(sort(aaa))
alat=abs(alat)
alat=alat(sparse_uniq(alat,tol=0.0005))
return,alat
end


