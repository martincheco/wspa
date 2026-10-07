pro save_hist,f,hist,par=par
openw,1,f
if keyword_set(par) then begin
    n=n_elements(par)
    for i=0,n-1 do printf,1,"#"+string(par(i))
end
n=n_elements(hist)
for i=0,n-1 do printf,1,i,hist(i)

close,1
end

function random_points,cnt,xsize,ysize,px,py,area,dtp,seed=seed
;creates random points within rectangle area of defined size
ncnt=cnt
factor=1
factor=double(px)/double(py)
if factor lt 1. then factor=1./factor ;scaling factor for the statistics if the image is non-square

ndtp=intarr(cnt)
;help,ndtp
cnta=round(n_elements(where(dtp eq 1))*factor)
cntb=round(n_elements(where(dtp eq 3))*factor)
;print,cnt,cnta+cntb
ndtp=intarr(cnta+cntb)
;help,ndtp
xy=complex(randomu(seed,cnta),randomu(seed,cnta))*max([px,py])
ndtp(0:cnta-1)=1
xy=[xy,complex(randomu(seed,cntb),randomu(seed,cntb))*max([px,py])]
ndtp(cnta:cnta+cntb-1)=3

;rejection
if px ge py then w=where(real_part(xy) le px )
if px lt py then w=where(imaginary(xy) le py )

if w(0) ne -1 then xy=xy(w)
if w(0) ne -1 then ndtp=ndtp(w)
if w(0) ne -1 then ncnt=n_elements(w)

return,{xy:xy,cnt:ncnt,dnt:0,area:area,fact:float(xsize)/float(px),xsize:xsize,ysize:ysize,px:py,py:py,dtp:ndtp}
end

pro cpl_plots,a,b,psym=psym
plots,[real_part(a),real_part(b)],[imaginary(a),imaginary(b)],/device,psym=psym
end

function read_coords,f
openr,1,f
szes=""
readf,1,szes
readf,1,szes
str=strsplit(szes," ",/extract)
xsize=double(str(1))
ysize=double(str(3))

p1=strpos(str(5),"(")
p2=strpos(str(5),"x")
p3=strpos(str(5),")")

px=strmid(str(5),p1+1,p2-p1-1)
py=strmid(str(5),p2+1,p3-p2-1)
a=""
readf,1,a
area=strmid(a,strpos(a,"Area:")+6)
if double(area) lt xsize*ysize/2 then area=double(xsize)*double(ysize)

xy=complexarr(10000)
cnt=0
dnt=0
dtp=intarr(10000)

while not(EOF(1)) do begin
    readf,1,a
    if strtrim(a,2) ne "" and strpos(a,"#") ne 0  then begin
	str=strsplit(a," ",/extract)
	xy(cnt)=complex(str(0),str(1))
	if (n_elements(str) ge 3) then dtp(cnt)=round(str(2)) else dtp(cnt)=0
	cnt=cnt+1

	if round(strtrim(str(2),2)) ge 7 then begin
	    print,'double!'
	    xy(cnt)=complex(str(0),str(1))
	    dtp(cnt)=round(str(2))-6
	    cnt=cnt+1
	    dnt=dnt+1
	end
    end
end

close,1
return,{xy:xy(0:cnt-1),cnt:cnt,dnt:dnt,area:float(area),fact:float(xsize)/float(px),xsize:xsize,ysize:ysize,px:px,py:py,dtp:dtp(0:cnt-1)}
end

function eval_coords,coords,ord=ord,binsize=binsize,maen=maen,ab=ab,aa=aa
;if keyword_set(plt) then window,1,xs=800,ys=800


xy=coords.xy

n=n_elements(xy)

mtrix=mreplicate(xy,n)
tmtrix=transpose(mtrix)

mdist=abs(mtrix-tmtrix)
ii=indgen(n)
mdist(ii,ii)=99999 ;move diagonal zeros out to hell

if keyword_set(ord) then begin
    ords=dblarr(n)
    for i=0,n-1 do begin
	dd=mdist(i,*)
	nmdist=mdist
	if keyword_set(ab) then begin
	    ;print,'ab'
	    if coords.dtp(i) eq 1 then w=where(coords.dtp eq 3)
	    if coords.dtp(i) eq 3 then w=where(coords.dtp eq 1)
	    if w(0) ne -1 then w=w else w=indgen(n)
	    nmdist=mdist(*,w)
	    ;help,nmdist
	    dd=nmdist(i,*)
	end
	if keyword_set(aa) then begin
	    ;print,'ab'
	    if coords.dtp(i) eq 1 then w=where(coords.dtp eq 1)
	    if coords.dtp(i) eq 3 then w=where(coords.dtp eq 3)
	    if w(0) ne -1 then w=w else w=indgen(n)
	    nmdist=mdist(*,w)
	    ;help,nmdist
	    dd=nmdist(i,*)
	end

	di=sort(dd)
;	if keyword_set(plt) then begin
;	    cpl_plots,xy(i),xy(di(ord-1)),psym=-3
;	    ;plots,real_part(xy((i))),imaginary(xy((i))),color=128,psym=1
;	end
	ords(i)=nmdist(i,di(ord))
    end 
    h=histogram(ords*coords.fact,binsize=binsize,nbins=200.)
    maen=mean(ords*coords.fact)
end else begin
    h=histogram(mdist*coords.fact,binsize=binsize,nbins=200.)
    maen=mean(mdist*coords.fact)
end
wset,0
return,h
end

function eval_sim_coords,coords,n,ord=ord,seed=seed,binsize=binsize,maen=maen,aa=aa,ab=ab

hh=dblarr(200)
cnt=0D
dnt=0D
area=0D
mnm=0D
;help,coords,/struct

for i=0,n-1 do begin
    coords_fake=random_points(coords.cnt,coords.xsize,coords.ysize,coords.px,coords.py,coords.area,coords.dtp,seed=seed)
    h=eval_coords(coords_fake,ord=ord,binsize=binsize,maen=maen,aa=aa,ab=ab)
    hh=hh+h
    mnm=mnm+maen
end

maen=mnm/n

return,hh/n
end


pro defects,binsize,ord=ord,n=n,ab=ab
window,0
device,decomposed=0
loadct,12
f=dialog_pickfile(/must_exist,/multiple)
hh=dblarr(200)
hha=hh
hh1=hh
hh3=hh
hh4=hh
hh5=hh
cnt=0D
tcnta=0D
tcntb=0D
tcntc=0D
cntsq=0D
dnt=0D
area=0D
maent=0D
maen=0D
maen1=0D
maen3=0D
maen4=0D
maen5=0D
tmaen=0D
tmaen1=0D
tmaen3=0D
tmaen4=0D
tmaen5=0D
ttmaen=0D

for i=0,n_elements(f)-1 do begin
    print,f(i)
    coords=read_coords(f(i))
    h=eval_coords(coords,ord=ord,binsize=binsize,maen=maen)
    h1=eval_coords(coords,ord=ord,binsize=binsize,maen=maen1,/aa)
    h3=eval_sim_coords(coords,1000,ord=ord,seed=seed,binsize=binsize,maen=maen3,/ab)
    h5=eval_sim_coords(coords,1000,ord=ord,seed=seed,binsize=binsize,maen=maen5,/aa)
    h4=eval_coords(coords,ord=ord,binsize=binsize,maen=maen4,/ab)
    ha=eval_sim_coords(coords,1000,ord=ord,seed=seed,binsize=binsize,maen=maent)
    hh1=hh1+h1
    hh3=hh3+h3
    hh5=hh5+h5
    hh4=hh4+h4
    hh=hh+h
    hha=hha+ha
    cnta=n_elements(where(coords.dtp eq 1))
    cntb=n_elements(where(coords.dtp eq 3))
    print,cnta,cntb
    print,maen1,maen3,maen5
    area=area+coords.area
    cnt=cnt+coords.cnt
    ;cnt=cnt
    tcnta=tcnta+cnta
    tcntb=tcntb+cntb
    ttmaen=ttmaen+coords.cnt*maent
    tmaen=tmaen+coords.cnt*maen
    tmaen1=tmaen1+maen1*double(coords.cnt)
    tmaen3=tmaen3+maen3*double(coords.cnt)
    tmaen5=tmaen5+maen5*double(coords.cnt)
    tmaen4=tmaen4+maen4*double(coords.cnt)

    
    cntsq=cntsq+coords.cnt^2
    dnt=dnt+coords.dnt
end


print,"Area:",area
print,"Count/nm^2:",cnt/area
grcell=0.246^2*3^0.5/4
print,"Count/Gr_unit:",cnt/area*grcell
print,"Total histogram events:",total(hh),total(hh1),total(hh4)
print,"Mean distance (all,a,b):",tmaen/cnt,(tmaen1)/(cnt),tmaen4/cnt
print,"Sim. mean distance:",ttmaen/cnt,tmaen3/cnt,tmaen5/cnt
print,"a, b counts:",tcnta,tcntb

save_hist,"total.dat",hh,par=[double(cnt)*grcell/area,total(hh),tmaen/cnt]
save_hist,"aabb.dat",hh1,par=[double(cnt)*grcell/area,total(hh1),(tmaen1)/(cnt)]
save_hist,"abba.dat",hh4,par=[double(cnt)*grcell/area,total(hh4),tmaen4/cnt]
save_hist,"simabba.dat",hh3,par=[double(cnt)*grcell/area,total(hh3),tmaen3/cnt]
save_hist,"simaabb.dat",hh5,par=[double(cnt)*grcell/area,total(hh5),tmaen5/cnt]
save_hist,"sim.dat",hha,par=[double(cnt)*grcell/area,total(hha),ttmaen/cnt]



hh=[0,hh]
hh1=[0,hh1]
hh3=[0,hh3]
hha=[0,hha]
hh4=[0,hh4]
hh5=[0,hh5]

if keyword_set(n) then xmax=n else xmax=200
plot,findgen(200)-0.5,hh,psym=10,xrange=[-1,xmax],xst=1
oplot,findgen(200)-0.5,hh1,color=170,psym=10
oplot,findgen(200)-0.5,hh4,color=100,psym=10
oplot,findgen(200)-0.5,hh,psym=10
oplot,findgen(200)-0.5,hha,color=50,psym=10

;print,total(hh)

end


pro sim_hist,wx,sz,ord=ord,binsize=binsize

coords={xy:0,cnt:1,dnt:0,area:wx*wx,fact:float(sz)/float(wx),xsize:sz,ysize:sz,px:wx,py:wx}
device,decomposed=1
goldpalette,/pure

    xmax=50
    ha=eval_sim_coords(coords,1000,ord=ord,seed=seed,binsize=binsize)
    plot,findgen(200)-0.5,ha,psym=10,xrange=[-1,xmax],xst=1

for i=1,100,10 do begin
    coords.cnt=i
    ha=eval_sim_coords(coords,1000,ord=ord,seed=seed,binsize=binsize)
    oplot,findgen(200)-0.5,ha,color=i*255/100,psym=10
end

end


pro test_sim,n,nn

hh=0
for i=0,n do begin
h=histogram(((randomu(seed,nn)-randomu(seed,nn))^2 + (randomu(seed,nn)-randomu(seed,nn))^2)^0.5 ,binsize=0.01)
hh=hh+h
end
plot,hh,psym=10
end