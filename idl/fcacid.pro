function fcacid,pars=pars
p=process_all(dir='.')
pp=p(*,[4,5,8,9],*,*)
ps=52
s=size(pp)

n=dblarr(s(1)/2,s(2)*2,s(3),s(4))

for i=0,s(1)/2-1 do begin
	n(i,[0,1,2,3],*,*)=pp(i*2,*,*,*)
	n(i,[4,5,6,7],*,*)=pp(i*2+1,*,*,*)
end 

n(ps,*,*,*)=(n(ps+1,*,*,*)+n(ps-1,*,*,*))/2.

nz=zoomstack(n,4)
nd=rmshift(nz,base_i=10,chan=0,/stuff)
;nd=rmdelay(nd,2,3) ;there was actually almost no delay
;nd=rmdelay(nd,6,7)

nf=foldstack(nd)

nf=zoomstack(nf,0.5)

nz=nf

nf(*,*,*,*)=nf(*,[0,1,3,2],*,*)
;nf(*,3,*,*)=nf(*,1,*,*)-nf(*,2,*,*)

;background
nf(*,1,*,*)=nf(*,1,*,*)-mmean(nf(-10:-1,1,*,*),/nan)-0.075
nf(*,2,*,*)=nf(*,2,*,*)-mmean(nf(-10:-1,2,*,*),/nan)-0.075

print,'Fitting 1'
prr=[9.8e-10,-1.12e-9,-3e-19]
ft1=stackfitz(reform(nf(*,1,*,*)),f='ljpot',pr=prr,dz=4e-12,d0=3.5e-10,pars=pars1)
print, 'Fitting 2'
ft2=stackfitz(reform(nf(*,2,*,*)),f='ljpot',pr=prr,dz=4e-12,d0=3.5e-10,pars=pars2)
sp=size(pars1)
for i=0,sp(1)-1 do print,median(pars1(i,*,*))

prr=[-1.54e-11,-1.2e-30]
dft1=(shift(ft1,-1,0,0)-ft1)/4e-12
dft1(-1,*,*)=dft1(-2,*,*)
help,ft1-ft2
help,dft1

nf(*,2,*,*)=nf(*,1,*,*)-nf(*,2,*,*)
ft3=stackfitz(reform(nf(*,2,*,*)),f='repp',com=dft1,pr=prr,dz=4e-12,d0=3.5e-10,pars=pars3)
print,median(pars3(0,*,*)),median(pars3(1,*,*))
pars=pars3


;final product
sz=size(nz)
nnn=dblarr(sz(1),9,sz(3),sz(4))
nnn(*,0,*,*)=nz(*,0,*,*);I1
nnn(*,1,*,*)=-nz(*,2,*,*);I2
nnn(*,2,*,*)=nz(*,1,*,*);df1
nnn(*,3,*,*)=nz(*,3,*,*);df2
nnn(*,4,*,*)=ft1;df1 fit
nnn(*,5,*,*)=ft2;df2 fit
nnn(*,6,*,*)=nf(*,2,*,*) ;difference df1 df2
nnn(*,7,*,*)=ft1-ft2 ;difference ft1 ft2
nnn(*,8,*,*)=ft3 ;fitted difference using the jascha method

help,nz
return,nnn
end
