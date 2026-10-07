pro manipulations1
r=stsloadmap('/home/martin/sync/data/Ag111_adatoms/2014-11-20/PTCDA_Ag(111)051.sxm.map')
m=loadnanonis('/home/martin/sync/data/Ag111_adatoms/2014-11-20/PTCDA_Ag(111)052.sxm')

;window,0,xs=400,ys=400
;wset,0

stsmapvis,r,m,chan=0,refine=5,offs=[1,0],vals=vals,nxy=nxy

;window,1,ys=200,xs=300
;wset,1

;plot,histogram(bytscl(vals),binsize=10)


nrm=where(bytscl(vals) lt 150 and bytscl(vals) gt 80)

;forward normal atom
hh1f=sts_2dhist(r(nrm),1,100)

s=size(hh1f)

;window,2,xs=2*s(1),ys=2*100

fw=bytscl(congrid(hh1f,4*s(1),2*100)<20)

tvscl,fw

hig=where(bytscl(vals) lt 70)

;forward high atom
hh1f=sts_2dhist(r(hig),1,100)

s=size(hh1f)

;window,2,xs=2*s(1),ys=2*100

fw=bytscl(congrid(hh1f,4*s(1),2*100)<5)

tv,fw,4*s(1),0


end
