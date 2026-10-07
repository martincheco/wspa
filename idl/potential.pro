pro potential_save,f,pot,dxy,xy0

stack_save,f+'pot',pot

stack_save,f+'dx',real_part(dxy)
stack_save,f+'dy',imaginary(dxy)

stack_save,f+'x0',real_part(xy0)
stack_save,f+'y0',imaginary(xy0)




end



function potential_extr,ff,strength
;searches local maxima and eliminates them
;strength is the number of cycles
if not(keyword_set(strength)) then strength=0
help,ff
fftm=ff
for i=0,strength-1 do begin
	ffs=convol(fftm,[[0,1,0],[1,0,1],[0,1,0]]/4.,/edge_wrap)
	ffr=abs(ffs-fftm)
	w=where(ffr eq max(ffr))
	fftm(w(0))=ffs(w(0))
end

return,fftm
end

pro potential_draw,pp,ff,zoom=zoom,ext=ext,win=win,decim=decim,sm=sm
p=pp(0:-2,0:-2)
s=size(p)
if keyword_set(sm) then cub=-0.5 else cub=0
xy0x=(mreplicate(indgen(s(1)),s(2)))
xy0y=transpose(mreplicate(indgen(s(2)),s(1)))
xy0=complex(xy0x,xy0y)+complex(0.5,0.5)
help,xy0
if keyword_set(zoom) then begin
    p=congrid(p,s(1)*zoom,s(2)*zoom,cubic=cub)
    xy0=xy0*zoom
    xy=ff
end else begin
    p=p
    xy=ff
end

if keyword_set(ext) then xy=ff*ext
if keyword_set(win) then window,1,xs=s(1)*zoom,ys=s(2)*zoom
tvscl,p
for i=0,s(1)-1 do for j=0,s(2)-1 do begin
    plots,[real_part(xy0(i,j)),real_part(xy0(i,j)+xy(i,j))],[imaginary(xy0(i,j)),imaginary(xy0(i,j)+xy(i,j))],psym=-3,color=255,thick=3.
    plots,[real_part(xy0(i,j))],[imaginary(xy0(i,j))],psym=3,color=128,thick=3.
end
end


function potential_di,p
di=p-shift(p,1,0)
return,di(1:-1,1:-1)
end

function potential_dj,p
di=p-shift(p,0,1)
return,di(1:-1,1:-1)
end

function potential,f,limit,pp=pp,constr=constr,inv=inv,totdif=totdif,difmap=difmap,margins=margins
;determines potential from a discrete force field
;uses random increments to minimize the least squares
;limit is a time limit for a difference between two improvements
;constr is a constraint on the vector field, to cut off excessively long vectors
;pp allows to supply a precalculated potential
;careful that result and vector field size differ by 1 in each axis!
;difmap will contain the differences squared
;margins allows to restrict the evaluation of differences only to some area

if keyword_set(margins) then begin
    x1=margins(0)
    x2=margins(1)
    y1=margins(2)
    y2=margins(3)
end else begin
    x1=0
    x2=-1
    y1=0
    y2=-1
end

if keyword_set(inv) then inv=-1 else inv=1

s=size(f)
ff=f
if keyword_set(constr) then begin
	w=where(abs(f) gt constr)
	if w(0) ne -1 then ff(w)=ff(w)/abs(ff(w))*constr
end

m=s(1)+1
n=s(2)+1
if not(keyword_set(pp)) then p=dblarr(m,n)+0.1 else p=pp
if not(keyword_set(totdif)) then totdif=0D

dif=1D99
;help,ff(0,*)
;help,p(0,1:-1)
;or i=0,s(1)-1 do p(i+1,1:-2)=p(i,1:-2)+ff(i,*)
nn=s(1)*s(2)/10.
difmap=dblarr(m-1,n-1)
cc=0
tm0=systime(/seconds)
dtm=0.
lit=0.
;tm=tm0
tm=tm0
difd=100D99

while dtm le limit do begin

if tm-lit gt 1. then begin
	
	difmapx=dblarr(m,n)
	difmapx(0:-2,0:-2)=difmap
	tvscl,[inv*congrid(p,400.,(400./m)*n),congrid(difmapx,400.,(400./m)*n)]
	lit=systime(/seconds)
	print,dtm,abs((dif-difd)/difd)^0.5
end

cc=cc+1
pd=p
difd=dif
	while dif ge difd do begin
		oo=randomn(seed,(m)*(n))
		o=reform(oo,m,n)
;		help,o
		p=pd+mmean((pd))/20.*o
		ffx=potential_di(p)
		ffy=potential_dj(p)
		dif=total((ffx(x1:x2,y1:y2)-real_part(ff(x1:x2,y1:y2)))^2,/double)+total((ffy(x1:x2,y1:y2)-imaginary(ff(x1:x2,y1:y2)))^2,/double)
	;	help,dif		
	end

totdif=[totdif,dif^0.5/n_elements(dif)]
tm=systime(/seconds)
dtm=tm-tm0
;tm0=tm
difmap=((ffx-real_part(ff))^2)+((ffy-imaginary(ff))^2)
difmap=difmap^0.5

end

return,p
end

function potentiala,f,limit,pp=pp,constr=constr,inv=inv
;determines potential from a discrete force field
;uses random increments to minimize the least squares
;limit is a time limit for a difference between two improvements
;constr is a constraint on the vector field, to cut off excessively long vectors
;pp allows to supply a precalculated potential
;careful that result and vector field size differ by 1 in each axis!

if keyword_set(inv) then inv=-1 else inv=1

s=size(f)
ff=f
if keyword_set(constr) then begin
	w=where(abs(f) gt constr)
	if w(0) ne -1 then ff(w)=ff(w)/abs(ff(w))*constr
end

m=s(1)+1
n=s(2)+1
if not(keyword_set(pp)) then p=reform(randomn(seed,m*n),m,n)+0.05 else p=pp
dif=dblarr(m-1,n-1) + 1e99
;help,ff(0,*)
;help,p(0,1:-1)
;or i=0,s(1)-1 do p(i+1,1:-2)=p(i,1:-2)+ff(i,*)
nn=s(1)*s(2)/10.

cc=0
tm0=systime(/seconds)
dtm=0.
lit=0.
;tm=tm0
tm=tm0
difd=dblarr(m-1,n-1) + 1e99

while dtm le limit do begin

if tm-lit gt 1. then begin
	tvscl,inv*congrid(p,400.,(400./m)*n)
	lit=systime(/seconds)
	;print,dtm,abs((dif-difd)/difd)^0.5
end

cc=cc+1
pd=p
difd=dif
		
oo=randomn(seed,(m)*(n))
o=reform(oo,m,n)
p=pd+mmean(pd)/20.*o
ffx=potential_di(p)
ffy=potential_dj(p)
dif=((ffx-real_part(ff))^2)+((ffy-imaginary(ff))^2)
ww=(difd-dif) gt 0D
;print,max(ww),min(ww)
www=dblarr(m,n)
www(1:-1,1:-1)=(ww)
www(1:-1,0:-2)=(www(1:-1,0:-2)+ww)
www(0:-2,0:-2)=(www(0:-2,0:-2)+ww)
www(0:-2,1:-1)=(www(0:-2,1:-1)+ww) gt 0D


if 1 gt 0 then begin
;rint,'improved'
	ooo=dblarr(m,n)
	ooo=o*double(www)
	p=pd+mmean(pd)/20.*ooo
	ffx=potential_di(p)
	ffy=potential_dj(p)
	dif=((ffx-real_part(ff))^2)+((ffy-imaginary(ff))^2)
end else begin
	p=pd
	dif=difd
	print,'not improved'
end

tm=systime(/seconds)
dtm=tm-tm0
;tm0=tm
end
return,p
end

