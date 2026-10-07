pro manipulations2b
rr=stsloadmap('/home/martin/sync/data/Ag111_adatoms/2014-11-28/PTCDA_Ag(111)006.sxm.map')
m=loadnanonis('/home/martin/sync/data/Ag111_adatoms/2014-11-28/PTCDA_Ag(111)007.sxm')

im=m(0).img

m(0).img=histxpand(ftgauss(lineslope(im),0.8))

wset,0

r=rr(*)
stsmapvis,r,m,chan=0,refine=0,offs=[-4,0],vals=vals,nxy=nxy


n=n_elements(r)
events=dblarr(n)
for i=0,n-1 do begin
	events(i)=(total((*r(i)).data(7,*)-(*r(i)).data(1,*)))
end

print,min(events),max(events),FORMAT='(E20.10),(E20.10)'
events=events-min(events)

wset,1
plot,histogram(bytscl(events))

btev=bytscl(events)
wset,0
w0=where(btev lt 40)
oplot,nxy(w0,0),nxy(w0,1),psym=2,color=255


wset,1



;rr=stsmapstruct(r,/zcorr)
;plot,histogram(bytscl(vals),binsize=10)

end
