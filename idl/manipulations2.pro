pro manipulations2
rr=stsloadmap('/home/martin/sync/data/Ag111_adatoms/2014-11-28/PTCDA_Ag(111)006.sxm.map')
m=loadnanonis('/home/martin/sync/data/Ag111_adatoms/2014-11-28/PTCDA_Ag(111)007.sxm')

im=m(0).img

m(0).img=histxpand(ftgauss(lineslope(im),0.8))

wset,0

r=rr(0:500)
stsmapvis,r,m,chan=0,refine=0,offs=[-4,0],vals=vals,nxy=nxy

w=where(bytscl(vals) gt 150)
ww=where(bytscl(vals) lt 150)

help,nxy
oplot,nxy(w,0),nxy(w,1),psym=3

hh1f=sts_2dhist(r(w),1,100,/zcorr)
hh1b=sts_2dhist(r(w),7,100,/zcorr)

hh2f=sts_2dhist(r(ww),1,100,/zcorr)
hh2b=sts_2dhist(r(ww),7,100,/zcorr)


help,hh1f
s=size(hh1f)



wset,1

fw=bytscl(congrid(hh1f,4*s(1),2*100)<10)
bw=bytscl(congrid(hh1b,4*s(1),2*100)<10)

fw2=bytscl(congrid(hh2f,4*s(1),2*100)<10)
bw2=bytscl(congrid(hh2b,4*s(1),2*100)<10)


tv,[[[fw]],[[fw*0]],[[bw]]],true=3
tv,[[[fw2]],[[fw2*0]],[[bw2]]],0,2*100,true=3


;rr=stsmapstruct(r,/zcorr)
;plot,histogram(bytscl(vals),binsize=10)

end
