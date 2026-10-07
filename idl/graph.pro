function graph,x,y,xerr,yerr
mnx=min(x)-2*xerr
mxx=max(x)+2*xerr
mny=min(y)-2*yerr
mxy=max(y)+2*yerr

print,n_elements(x),n_elements(y)

xstep=0.05
ystep=0.05

xn=(mxx-mnx)/xstep<800
yn=(mxy-mny)/ystep<600
print,xn,yn

img=fltarr(xn,yn)

for i=0.,n_elements(x)-1 do begin
    img=img+gauss2d(xn,yn,(x(i)-mnx)/(mxx-mnx)*xn,(y(i)-mny)/(mxy-mny)*yn,2*xerr/xstep,2*yerr/ystep)
end

return,{img:img,x:findgen(xn)/xn*(mxx-mnx)+mnx,y:findgen(yn)/yn*(mxy-mny)+mny}

end

pro graphics1,file,x=x,y=y,tx=tx,ty=ty,xerr=xerr,yerr=yerr,antinub=antinub,noexp=noexp,latin=latin

set_plot,'ps'
!P.Font=-1

device,/encapsul,bits_per_pixel=8,/color,filename=strtrim(file,2)+'.eps',xsize=16,ysize=12


col0=[0,0,0]
col1=([255,0,0]) ;red
col3=([0,0,255]) ;blue
col2=([0,255,0]) ;green
col4=([255,128,128]) ;lightred
col5=([128,255,128]) ;lightgreen
col6=([128,128,128]) ;lightblue
col99=([255,255,255]) ;white

tbl=[[col0],[col1],[col2],[col3],[col4],[col5],[col6],[col99]]
help,tbl
val=color_quan(tbl(0,*),tbl(1,*),tbl(2,*),rr,gg,bb)

col0=val(0)
col1=val(1)
col2=val(2)
col3=val(3)
col4=val(4)
col5=val(5)
col6=val(6)

!p.background=val(n_elements(val)-1)
!p.color=val(0)
!p.charsize=1.2
!p.charthick=3.0
!x.charsize=1.0
!y.charsize=1.0
!x.thick=2
!y.thick=2
!p.thick=2


if not(keyword_set(x)) and not(keyword_set(noexp)) then begin
a=read_ascii()
s=size(a.field1)
help,a.field1,/struct
x=a.field1(1,*)
y=a.field1(0,*)
end

if not(keyword_set(tx)) then begin
b=read_ascii(data_start=3)
sb=size(b.field1)
help,b.field1,/struct
tx=b.field1(3,*)
ty=b.field1(2,*)
if sb(1) gt 6 then expa=(b.field1(6,*)) else expa=0
print,expa
help,expa
expa=(ty*0.+1.)*expa ;a trick to make it an array in any case
print,expa

srt=sort(ty)
tx=tx(srt)
ty=ty(srt)
expa=expa(srt)
end


if not(keyword_set(xerr)) then $
begin
xerr=2.5
yerr=1.5
end

;choosing the unique values
un=find_uniq(ty,tx,xtol=0.05,ytol=0.2)
tx=tx(un)
ty=ty(un)
expa=expa(un)

srta=sort(ty)
tx=tx(srta)
ty=ty(srta)
expa=expa(srta)

if (keyword_set(noexp)) then begin
    antinub=1
    im={img:intarr(30,20),x:findgen(30),y:findgen(20)}
end else im=graph(x,y,xerr/2.,yerr/2.)

help,im
;device,retain=2
;device,decomposed=0
;white=transcol([255,255,255])
;black=transcol([0,0,0])

;col1=transcol([0,0,255])
;col2=transcol([200,0,0])
;col3=transcol([170,170,255])
loadct,0

bkg=max(im.img)-im.img-0.05
if keyword_set(antinub) then bkg=bkg*0
contour,bkg,im.x,im.y,/fill,nlevels=60,xrange=[-3.,33.],xst=1,yrange=[0.,max(ty)+2],yst=1,$
xtitle="Apparent angle !4X!X [deg]",ytitle="Periodicity L [!3"+string(197B)+"!X]"


tvlct,rr,gg,bb

if not(keyword_Set(noexp)) then begin
;device,decomposed=1
print,xerr,yerr
for i=0,n_elements(x)-1 do plots,[x(i)-xerr,x(i)+xerr],[y(i),y(i)],psym=-3,color=val(6),noclip=0
for i=0,n_elements(x)-1 do plots,[x(i),x(i)],[y(i)+yerr,y(i)-yerr],psym=-3,color=val(6),noclip=0
oplot,x,y,color=val(0),psym=1

end



grcol=val(expa+2)
print,grcol

for i=0,n_elements(tx)-1 do plots,tx(i),ty(i),color=grcol(i),psym=4,thick=3.

if keyword_Set(latin) then chars=" " else chars="!4 "
if not(keyword_set(latin)) then latin=1
if latin gt 0 then for i=0,n_elements(tx)-1 do xyouts,tx(i),ty(i),chars+strtrim(string(97B+byte(i)),2)+"!X",color=grcol(i),charsize=2.0,charthick=4.

device,/close
set_plot,'X'

end


pro fig3c,file


set_plot,'ps'
!P.Font=-1

device,/encapsul,bits_per_pixel=8,/color,filename=strtrim(file,2)+'.eps',xsize=16,ysize=12


col0=[0,0,0]
col1=([255,0,0]) ;red
col3=([0,0,255]) ;blue
col2=([0,255,0]) ;green
col4=([255,128,128]) ;lightred
col5=([128,255,128]) ;lightgreen
col6=([128,128,255]) ;lightblue
col99=([255,255,255]) ;white

tbl=[[col0],[col1],[col2],[col3],[col4],[col5],[col6],[col99]]
help,tbl
val=color_quan(tbl(0,*),tbl(1,*),tbl(2,*),rr,gg,bb)

col0=val(0)
col1=val(1)
col2=val(2)
col3=val(3)
col4=val(4)
col5=val(5)
col6=val(6)

!p.background=val(n_elements(val)-1)
!p.color=val(0)
!p.charsize=1.2
!p.charthick=3.0
!x.charsize=1.0
!y.charsize=1.0
!x.thick=2
!y.thick=2
!p.thick=2


a=read_ascii()

per=a.field1(0,*)
area=a.field1(2,*)
mis=a.field1(3,*)/2.46*100
greek=a.field1(4,*)

srt=sort(per)

per=per(srt)
area=area(srt)
mis=mis(srt)
greek=greek(srt)

srt=[0,1,2,6,7,8,9,10]

per=per(srt)
area=area(srt)
mis=mis(srt)
greek=greek(srt)

print,correlate(mis,area)

plot,area,mis,psym=4,thick=3.,xst=2,yst=2,ytitle="Mismatch/a!LG!N [%]",xtitle="Total area [nm!E2!N]"

for i=0,n_elements(area)-1 do $
xyouts,area(i),mis(i)," !4"+string(97B+byte(greek(i)-1))+"!3 "+string(per(i),format='(F4.1)')+string(197B),color=val(1),alignment=0.0

device,/close

set_plot,'X'
end