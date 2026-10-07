function smodch,tot
;err=dblarr(1000)
err=stddev(tot,dim=2)
return,err
end

pro calc_err
mn=10
mx=980
;calculates std err of these curves
cd,'/home/martin/sync/data/SiC_H_dimers_eval/pfl'

device,decomposed=1
goldpalette,/pure

b=read_profile('pfl8.dat.r')
c=read_profile('pfl9.dat.r')
;d=read_profile('pfl4.dat.r')

e=read_profile('pfl10.dat.r')
help,e.z
;e.z=reverse(e.z,2)

f=read_profile('pfl11.dat.r')
;f.z=reverse(f.z,2)

;g=read_profile('pfl7.dat.r')


help,b,/struct
tot=[[[b.z]],[[c.z]],[[e.z]],[[f.z]]]
nn=4
tot=reform(double(tot),1000,nn)
tot=tot-min(tot(*,0))
toto=tot

p=[0,0,0,0,0]
q=[0,0,0,0,0]
err=smodch(toto)
dterr=total(err(mn:mx))
origerr=smodch(toto)
pd=p
qd=q
cnt=0L
tcnt=0L

window,0,xs=640,ys=480

for n=0,2000000L do begin
    p=pd+(randomu(seed,nn)-0.5)*10000L/n
    q=qd+(randomu(seed,nn)-0.5)*10

for j=1,nn-1 do toto(*,j)=shift(tot(*,j)-p(j-1),q(j-1))
    
    err=smodch(toto)
    cnt=cnt+1
    tcnt=tcnt+1
    terr=total(err(mn:mx))
    if terr lt dterr then begin
	print,p
	print,q
	print,terr,cnt,tcnt
	pd=p
	qd=q
	dterr=terr
	plot,b.r,tot(*,0),color=70
for j=1,nn-1 do	oplot,b.r,tot(*,j),color=70
for j=0,nn-1 do	oplot,b.r,toto(*,j),color=200
	oplot,b.r,err,color=255
	oplot,b.r,origerr,color=128
	oplot,b.r,total(toto,2)/nn,color=170
	oplot,b.r(mn:mx),total(toto(mn:mx,*),2)/nn,color=255

	cnt=0L
    end
end

avg=total(toto,2)/nn

totom=toto
for j=0,nn-1 do totom(*,j)=toto(*,j)-avg

merr=max(abs(totom),dim=2)
help,merr

save_profile,'o_err.dat.r',{r:b.r,z:err}
save_profile,'o_avgstddev.dat.r',{r:b.r,z:total(toto,2)/nn},err=err
save_profile,'o_avgmaxdev.dat.r',{r:b.r,z:total(toto,2)/nn},err=merr
save_profile,'o_maxerr.dat.r',{r:b.r,z:merr}

end