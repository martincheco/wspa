function sum_it,x,y,error
mn=min(x)
mx=max(x)

end

function reduce_angle,angle,half=half
;half reduces only to -30..30DEG
if not(keyword_set(half)) then rangle=30-abs(((angle +180) mod 60)-30) else rangle=(((angle) mod 60)) 
return,rangle
end

function mreplicate,v,dim
m=dcomplexarr(n_elements(v),n_elements(v))
for i=0,dim-1 do m(*,i)=v
return,m
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

function minimo,angles,misfit
;this function extracts only the minimum misfit for all unique angles, ignores zero values
sangles=angles(sort(angles))
smisfit=misfit(sort(angles))
angulos=sangles(uniq(sangles)) ;unique angles
windex=lonarr(n_elements(angulos))

for i=0,n_elements(angulos)-1 do begin
    w=where(angles eq angulos(i)) ;all misfits with this angulo
;    print,angulos(i),w,smisfit(w) 
    ww=where((smisfit(w)) ne 0) ;all misfits that aren't zero
    if ww(0) eq -1 then ww=0 ;if there is only zero value, solve it later

;fix this if its still a dirty trick
;    www=where((smisfit) eq min((smisfit(w(ww)))))
;    print,www(0)
;    windex(i)=www(0)
;the FIX
    www=where((smisfit(w(ww))) eq min((smisfit(w(ww)))))
    
;    print,www(0)
    wi=w(ww(www))
    windex(i)=wi(0)
end

;final fix for the zero values
wnonzero=where((smisfit(windex)) ne 0)
windex=windex(wnonzero)
return,windex
end


pro lattice_misfit,dim,angle,a,b,limit=limit,mis=mis,per=per,connect=connect,noplot=noplot,hex=hex,mang=mang,cutoff=cutoff,vect=vect,nplt=nplt
;plots the overlay of lattices according to given angle and lattice parameters
;running the indexes in the same manner as the misfit calculation
;hex adds hexagonal graphene lattice
;limit defines the acceptable misfit that will be denoted in the image

if not(keyword_set(nplt)) then nplt=0
if not(keyword_set(cutoff)) then cutoff=22.2 ;Pt


col0=[0,0,0]
col1=([1,1,1]*160) ;a dots
col2=([1,1,1]*0) ;b dots
col3=([0,0,255]) ;misfit marks
col4=([255,255,255]) ;hex misfit marks
col5=([255,0,0]) ;angle
col6=([0,0,255]) ;app. angle
col99=([255,255,255])

tbl=[[col0],[col1],[col2],[col3],[col4],[col5],[col6],[col99]]
;help,tbl
val=color_quan(tbl(0,*),tbl(1,*),tbl(2,*),rr,gg,bb)
tvlct,rr,gg,bb

col0=val(0)
col1=val(1)
col2=val(2)
col3=val(3)
col4=val(4)
col5=val(5)
col6=val(6)

!p.background=val(n_elements(val)-1)
!p.color=val(0)


if not(keyword_set(a)) then a=2.774 ;Pt
if not(keyword_set(b)) then b=2.46 ;graphene
if keyword_set(noplot) then pl=0 else pl=1

ix=lindgen((dim*2)^2)
ii=ix / (2*dim)
jj=ix mod (2*dim)
ii=ii-dim
jj=jj-dim


rotation=exp(dcomplex(0,angle*!PI/180.))

va=a*vector(dcomplex(ii,jj)) ;substrate, triangular
vb=b*vector(dcomplex(ii,jj))*rotation ;adsorbate
vbx=vb+b*vector(dcomplex(1,2))/3*rotation ;hexagonal atom in adsorbate


mn=min([a,b])
;fact=2.; 3^0.5/2 ;factor of zoom-in

if pl then begin
    if nplt then plot,real_part(va),imaginary(va),psym=8,xstyle=1,ystyle=1,/iso,$,
    xrange=[-cutoff,cutoff]*25./23.,yrange=[-cutoff,cutoff]*25./23.,/nodata,/noerase,ticklen=-0.02,charsize=1.,$
    xtickname=replicate(" ",30),ytickname=replicate(" ",30),xmargin=[2,1],ymargin=[1,2]

    
;    plot,real_part(va),imaginary(va),psym=8,xstyle=1,ystyle=1,/iso,xrange=[-cutoff,cutoff]*25./23.,yrange=[-cutoff,cutoff]*25./23.,/nodata,ticklen=-0.02,charsize=1.
    

end

if pl then $
    if keyword_set(connect) then begin
	va1=va+a*vector(dcomplex(1,1))
	va2=va+a*vector(dcomplex(0,1))
	vby=vb+b*vector(dcomplex(1,1))*rotation
	vbz=vb+b*vector(dcomplex(0,1))*rotation
	
	for c=0,n_elements(vb)-1 do begin
	    ;a
	    x1=[real_part(va(c)),real_part(va1(c))]
	    y1=[imaginary(va(c)),imaginary(va1(c))]
	    x2=[real_part(va1(c)),real_part(va2(c))]
	    y2=[imaginary(va1(c)),imaginary(va2(c))]
	    x3=[real_part(va(c)),real_part(va2(c))]
	    y3=[imaginary(va(c)),imaginary(va2(c))]
	    
	    ;plots,x1,y1,color=col1,noclip=0
	    ;plots,x2,y2,color=col1,noclip=0
	    ;plots,x3,y3,color=col1,noclip=0
	    
	    ;b
	    x1=[real_part(vb(c)),real_part(vbx(c))]
	    y1=[imaginary(vb(c)),imaginary(vbx(c))]
	    x2=[real_part(vbx(c)),real_part(vby(c))]
	    y2=[imaginary(vbx(c)),imaginary(vby(c))]
	    x3=[real_part(vbx(c)),real_part(vbz(c))]
	    y3=[imaginary(vbx(c)),imaginary(vbz(c))]
	    
if nplt then 	    plots,x1,y1,color=col2,noclip=0
if nplt then 	    plots,x2,y2,color=col2,noclip=0
if nplt then 	    plots,x3,y3,color=col2,noclip=0
	end
    end

if pl then begin
    usersym1    
    if nplt then oplot,real_part(va),imaginary(va),psym=8,color=col1
    usersym2
    if nplt then oplot,real_part(vb),imaginary(vb),psym=8,color=col2
    if keyword_set(hex) then if nplt then oplot,real_part(vbx),imaginary(vbx),psym=8,color=col2
    
    ;Substrate axis
    aa=findgen(2)*2*!PI/2.
    rtt=1.5*cutoff*exp(complex(aa*0,aa))
    ;print,rtt
    
    for i=0,1 do plots,[0,real_part(rtt(i))],[0,imaginary(rtt(i))],noclip=0,psym=-3,thick=3.
    ;plots,[0,0],[-1,1]*cutoff*1.5,noclip=0


end

if keyword_set(limit) then begin

    nnn=n_elements(va)

    van=mreplicate(va,nnn)
    vbn=transpose(mreplicate(vb,nnn))
    vbxn=transpose(mreplicate(vbx,nnn))

    ;corner atom
    res=van-vbn
    w=where(abs(res) lt limit*b)
    

    if w(0) ne -1 then begin

	wa=w mod nnn ;column
	wb=w / nnn ;row

        mis=res(w)
        per=abs(vb(wb)) ;yes, everything related to graphene
        ;the angle of moire
        mang=imaginary(alog(vb(wb)/per))/!PI*180
	vect=vb(wb)

        if pl then begin
	for cc=0,n_elements(w)-1 do begin 
;	    plots,real_part(va(wa(cc))),imaginary(va(wa(cc))),psym=7,noclip=0,color=col3
;	    plots,real_part(vb(wb(cc))),imaginary(vb(wb(cc))),psym=1,noclip=0,color=col3
;	    plots,[real_part(va(wa(cc))),real_part(vb(wb(cc)))],[imaginary(va(wa(cc))),imaginary(vb(wb(cc)))],psym=-3,noclip=0,color=col3
	    
	    ;the angle
	    rang=angle*!PI/180.
	    plots,1.5*cutoff*cos(rang)*[-1,1],1.5*cutoff*sin(rang)*[-1,1],psym=-3,noclip=0,color=col5,thick=4.
	
	    
	end
	    ;the app.angle
	    ss=(sort(abs(mis)))
	    
	    mangs=mang(ss) ;by misfit
	    pers=per(ss)
	    vects=vect(ss)
	    miss=mis(ss)
	    
	    mangs=mangs(1:*)
	    pers=pers(1:*)
	    vects=vects(1:*)
	    
	    wwww=where(pers le cutoff)
	    if wwww(0) ne -1 then begin
	    
		mangs=mangs(where(pers le cutoff))
		vects=vects(where(pers le cutoff))
;	    	pers=pers(where(pers le cutoff))

		rmangs=reduce_angle(mangs(0),/half)
		help,rmangs
		rmangs=rmangs/180.*!PI
		help,rmangs
		;print,rmangs
		help,per(0)
		print,vects(0:5)
		vangles=imaginary(alog(vects(0:5)))/!PI*180
		help,vangles
		print,vangles
		vangles=vangles(where(abs(vangles) eq min(abs(vangles))))
		help,vangles
	    
;	    	plots,cutoff*cos(rmangs)*[-1,1],cutoff*sin(rmangs)*[-1,1],psym=-3,noclip=0,color=col6,thick=3.0
		for i=0,5 do plots,[0,real_part(vects(i))],[0,imaginary(vects(i))],psym=-3,thick=3.,color=col6,symsize=1.
		plots,real_part(vects(0:5)),imaginary(vects(0:5)),psym=1,thick=3.,color=col3,symsize=1.
	
	    end
	
	end



    end else begin
        per=0
	mis=1
	mang=0
	vect=0
    end
    
    
    ;hex atom
    if keyword_set(hex) then begin
        resx=van-vbxn
        wx=where(abs(resx) lt limit*b)

	if wx(0) ne -1 then begin
    
	    wa=wx mod nnn ;column
	    wb=wx / nnn ;row

	    misx=resx(wx)
	    perx=abs(vb(wb))
	    mangx=imaginary(alog(vb(wb)/perx))/!PI*180
	    vectx=vb(wb)

    	    if pl then $
    	    for cc=0,n_elements(wx)-1 do begin 
;		plots,real_part(va(wa(cc))),imaginary(va(wa(cc))),psym=1,noclip=0,color=col2
;		plots,real_part(vbx(wb(cc))),imaginary(vbx(wb(cc))),psym=7,noclip=0,color=col2
;		plots,[real_part(va(wa(cc))),real_part(vbx(wb(cc)))],[imaginary(va(wa(cc))),imaginary(vbx(wb(cc)))],psym=-3,noclip=0,color=col2
	    end
	end else begin
	    perx=0
	    misx=1
	    mangx=0
	    vectx=0
	end

;	per=[per,perx]
;	mis=[mis,misx]
;	mang=[mang,mangx]
;	vect=[vect,vectx]
    end

;redraw axes
    deg=string("260B)
if pl then if nplt then $
    plot,real_part(va),imaginary(va),psym=8,xstyle=1,ystyle=1,/iso,$,
    xrange=[-cutoff,cutoff]*25./23.,yrange=[-cutoff,cutoff]*25./23.,/nodata,/noerase,ticklen=-0.02,charsize=1.,$
    title="Angle:"+string(abs(angle),format='(F4.1)')+deg+", App. angle: "+string(abs(vangles(0)),format='(F4.1)')+deg,$
    xtickname=replicate(" ",30),ytickname=replicate(" ",30),xmargin=[2,1],ymargin=[1,2],$
    charthick=1.5

;take out the periodicities bigger than the cutoff
    w5=where(per le cutoff)
    if w5(0) ne -1 then begin
	per=per(w5)
	mis=mis(w5)
	mang=mang(w5)
	vect=vect(w5)
    end else begin
	print,"no periodicity within the minimum circle found!"
    end


end

end


function moire2,dim,a,b,limit=limit,anglestep=anglestep,hex=hex,noplot=noplot,record=record,cutoff=cutoff
;parameter record initiates saving of the images


if not(keyword_set(cutoff)) then cutoff=22.2 ;Pt

if not(keyword_set(a)) then a=2.774 ;Pt
if not(keyword_set(b)) then b=2.46 ;graphene
if not(keyword_set(limit)) then limit=0.1 ;10%
if not(keyword_set(anglestep)) then anglestep=0.05
if keyword_set(record) then wdir=dialog_pickfile(/directory)
help,wdir

na=30./anglestep+1
if not(keyword_set(angleset)) then as=findgen(na)/(na-1)*30. else as=angleset

na=n_elements(as)

periodicity=0
misfits=0
angles=0
mangles=0
vectors=0

for i=0,na-1 do begin
lattice_misfit,dim,as(i),a,b,per=per,mis=mis,limit=limit,mang=mang,hex=hex,noplot=noplot,cutoff=cutoff,vect=vect
    if keyword_set(record) then begin
	img=tvrd(0,true=1)
	fn=wdir+"/img"+strtrim(string(as(i),format='(F06.2)'),2)+'.png'
	;img=reverse(img,2)
	write_png,fn,img
    end

periodicity=[periodicity,per]
misfits=[misfits,mis]
angles=[angles,replicate(as(i),n_elements(mis))]
mangles=[mangles,mang]
vectors=[vectors,vect]

print,as(i),n_elements(where(mis lt 0.1*b and mis gt 0))
end

return,{dim:dim,a:a,b:b,cutoff:cutoff,limit:limit,misfits:misfits(1:*),periodicity:periodicity(1:*),angles:angles(1:*),mangles:mangles(1:*),vectors:vectors(1:*)}
end


pro save_data,t,all=all,minima=minima
;all saves all
;minima reduces everything to only minima
;all has preference


if keyword_set(all) then w=where(t.periodicity gt 0.) else begin
	w=minimo(t.angles,abs(t.misfits))
	if keyword_set(minima) then w=w(localmin(t.angles(w),abs(t.misfits(w))))
end

mangles=reduce_angle(t.mangles(w))
openw,1,dialog_pickfile(),width=300
printf,1,"a       b       dim         cutoff     limit      nothing   nothing" 
;nothing is just employed to get the proper count of columns in the array
printf,1,t.a,t.b,float(t.dim),t.cutoff,t.limit,0.,0.


printf,1,"angle   ","misfit   ","periodicity   ","app.angle   ","vector X   ","vector Y   ","expansion   "
for i=0,n_elements(w)-1 do $
begin
x1=real_part(t.misfits(w(i)))
x2=real_part(t.vectors(w(i)))
y1=imaginary(t.misfits(w(i)))
y2=imaginary(t.vectors(w(i)))
compression=sgn(x1*x2+y1*y2)
printf,1,t.angles(w(i)),abs(t.misfits(w(i))),t.periodicity(w(i)),mangles(i),real_part(t.vectors(w(i))),imaginary(t.vectors(w(i))),compression
end
close,1
end



function load_data,f
;loads the saved data

st=read_ascii(f)
stt=st.field1

a=stt(0,1)
b=stt(1,1)
dim=stt(2,1)
cutoff=stt(3,1)
limit=stt(4,1)

s=size(stt)

ang=reform(stt(0,3:*))
mis=reform(stt(1,3:*))
per=reform(stt(2,3:*))
app=reform(stt(3,3:*))
vx=reform(stt(4,3:*))
vy=reform(stt(5,3:*))
if s(1) gt 6 then compression=reform(stt(6,3:*)) else compression=0

return,{dim:dim,a:a,b:b,limit:limit,cutoff:cutoff,angles:ang,misfits:mis,periodicity:per,mangles:app,vectors:complex(vx,vy),compression:compression}
end



pro graphics3,t,file,xcm,ycm

set_plot,'ps'
!P.Font=-1

device,/encapsul,bits_per_pixel=8,/color,filename=strtrim(file,2)+'.eps',xsize=xcm,ysize=ycm


col0=[0,0,0]
col1=([255,0,0]) ;red
col2=([0,0,255]) ;blue
col3=([0,255,0]) ;green
col4=([255,128,128]) ;lightred
col5=([128,255,128]) ;lightgreen
col6=([128,128,128]) ;halfgrey
col99=([255,255,255]) ;white

tbl=[[col0],[col1],[col2],[col3],[col4],[col5],[col6],[col99]]
help,tbl
val=color_quan(tbl(0,*),tbl(1,*),tbl(2,*),rr,gg,bb)
tvlct,rr,gg,bb

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
!p.charthick=2.0
!x.charsize=1.0
!y.charsize=1.0
!x.thick=1.8
!y.thick=1.8
!p.thick=1.8

plot,t.angles,abs(t.misfits)/t.b*100,psym=3,xrange=[-1,31],xst=1,yrange=[-1.5,max(abs(t.misfits)/t.b)*101],yst=1,ytitle="Mismatch [%]",xtitle="Angle ["+string("260B)+"]"
w=minimo(t.angles,abs(t.misfits))
ww=localmin(t.angles(w),abs(t.misfits(w)))
www=w(ww)
x=t.angles(www)
psrt=sort(t.periodicity(www))
x=x(psrt)
y=abs(t.misfits(www)/t.b*100)
y=y(psrt)
per=t.periodicity(www)
per=per(psrt)
app=reduce_angle(t.mangles(www))
app=app(psrt)



nn=n_elements(x)
labelz=strarr(nn)

help,www
print,per


;choosing the unique values

wu=find_uniq(per,app,xtol=0.05,ytol=0.2)

help,wu



for i=0,nn-1 do labelz(i)="!16"+string(97B+byte(where(abs(per(wu) - per(i)) le 0.01 and abs(app(wu) - app(i)) le 0.2)))+"!X"
help,labelz

oplot,x,y,color=val(1),psym=1,thick=3.

xyouts,x,-0.85,labelz,color=val(1),charsize=1.5,alignment=0.5
oplot,t.angles(w),abs(t.misfits(w)/t.b*100),psym=-3

device,/close
set_plot,'X'


end

pro usersym1
a=2.*!PI*findgen(21.)/20.
x=(0.8*cos(a))
y=(0.8*sin(a))
usersym,x,y,/fill
end

pro usersym2
a=2.*!PI*findgen(11.)/10.
x=(0.4*cos(a))
y=(0.4*sin(a))
usersym,x,y,/fill
end

pro usersym3
a=2.*!PI*findgen(81.)/80.
x=(40*cos(a))
y=(40*sin(a))
usersym,x,y,/fill
end

pro ps_img,angle,xcm,ycm,file
set_plot,'ps'
!P.Font=-1

device,/encapsul,bits_per_pixel=8,/color,filename=strtrim(file,2)+'.eps',xsize=xcm,ysize=ycm

lattice_misfit,20,angle,limit=0.1,cutoff=23,nplt=0

device,/close
set_plot,'X'

end
