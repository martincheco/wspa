
function xyiread, f
;vezme jelinkuv zatim blize nespecifikovany format, 
;ktery je zadan jako tri sloupce x, y a z souradnic
if not(keyword_set(f)) then f = dialog_pickfile(/read, /must_exist)
print,"Reading:",f
s=read_ascii(f,data_start=4)
a=s.field1
return,a
end


function diffthem,f1,f2
if not(keyword_set(f1)) or not(keyword_set(f1)) then $
begin
print, 'Select one!'
f1 = dialog_pickfile(/read, /must_exist)
print, 'Select the second one!'
f2 = dialog_pickfile(/read, /must_exist)
end

resultt=(xyi2img(f1)-xyi2img(f2))

return,resultt
end


function xyi2img, f
;vezme jelinkuv zatim blize nespecifikovany format, 
;ktery je zadan jako tri sloupce x, y a z souradnic
;vykucha z neho pocet radek a sloupcu a vygeneruje pole se spravnymi hodnotami
if not(keyword_set(f)) then f = dialog_pickfile(/read, /must_exist)
print,"Reading:",f
s=read_ascii(f,data_start=1)
a=s.field1

a1=a(0,*)
a2=a(1,*)
a3=a(2,*)


help,a1
help,a2
help,a3

print,a1(0,0)
print,'a'
mia1=min(a1)
mxa1=max(a1)
mia2=min(a2) 
mxa2=max(a2)

print, mia1,mxa1,mia2,mxa2

mii1=where(a1 eq mia1)
mxi1=where(a1 eq mxa1)

help,mii1
help,mxi1

mii2=where(a2 eq mia2)
mxi2=where(a2 eq mxa2)

help,mii2
help,mxi2

n=n_elements(a1)

if mxi1(0)-mii1(0) lt mxi2(0)-mxi2(0) then begin
xl=n/(mxi1(1)-mxi1(0))
yl=n/xl
end $
else begin
yl=n/(mxi2(1)-mxi2(0))
xl=n/yl
end

yy=reform(a3,xl,yl)
s=size(yy)
yy=yy(0:s(1)-2,0:s(2)-2)
print,'MIN., MAX. VALUE:',min(yy),',',max(yy)
return,yy
end


function xyz2png, f
;vezme jelinkuv zatim blize nespecifikovany format, 
;ktery je zadan jako tri sloupce x, y a z souradnic
;a vygeneruje z nej obrazek
if not(keyword_set(f)) then f = dialog_pickfile(/read, /must_exist)
print,"Reading:",f
s=read_ascii(f,data_start=4)
a=s.field1

a1=reform(a(0,*))
a2=reform(a(1,*))
a3=reform(a(2,*))


help,a1
help,a2
help,a3

print,a1(0,0)
print,'a'
mia1=min(a1) ;hledani zakladnich vektoru
mxa1=max(a1)
mia2=min(a2) 
mxa2=max(a2)

print, mia1,mxa1,mia2,mxa2

mii1=where(a1 eq mia1)
mxi1=where(a1 eq mxa1)

help,mii1
help,mxi1

mii2=where(a2 eq mia2)
mxi2=where(a2 eq mxa2)

help,mii2
help,mxi2

n=n_elements(a1)

if mxi1(0)-mii1(0) lt mxi2(0)-mxi2(0) then begin
xl=n/(mxi1(1)-mxi1(0))
yl=n/xl
end $
else begin
yl=n/(mxi2(1)-mxi2(0))
xl=n/yl
end

print, xl,yl

yy=reform(a3,xl,yl)
s=size(yy)
yy=yy(0:s(1)-2,0:s(2)-2)
print,'MIN., MAX. VALUE:',min(yy),',',max(yy)
zooom=10
imgg=congrid([[yy,yy],[yy,yy]],s(1)*zooom,s(2)*zooom,cubic=-0.5)
tvscl,imgg
vx=mxa1-mia1
vy=mxa2-mia2

;r=((vx^2+vy^2)/2)^(0.5)*zooom
r2=xl*zooom/2


fromx=[0.,0.,xl*zooom,xl*zooom]
fromy=[0.,yl*zooom,0.,yl*zooom]
tox=[r2,0.,xl*zooom+r2,xl*zooom]
toy=[0,yl*zooom,0.,yl*zooom]
result=warp_tri(tox,toy,fromx,fromy,imgg,output_size=[zooom*xl*1.5,zooom*yl])
return,result
end



function diffthem,f1,f2
if not(keyword_set(f1)) or not(keyword_set(f1)) then $
begin
print, 'Select one!'
f1 = dialog_pickfile(/read, /must_exist)
print, 'Select the second one!'
f2 = dialog_pickfile(/read, /must_exist)
end

resultt=(xyi2img(f1)-xyi2img(f2))

return,resultt
end

function jel2png,fin,dif=dif,fout,vis=vis,zooom=zooom

ll=intarr(85)*0                                                                 
hl=intarr(85)+255                                                               
sl=indgen(85)*3                                                                 
ssl=indgen(170)*3/2+1  
r=[0,ssl,hl]                                                                    
g=[0,ll,ssl]                                                                    
b=[0,ll,ll,sl] 
if (keyword_set(fin) and keyword_set(fout)) then $
begin
img=xyi2img(fin)
s=size(img)
mgg=[[img],[img]]
imgg2=shift(imgg,0,28)
imgg=[imgg,imgg2]
end $
else $
begin
img=xyi2img()
s=size(img)
imgg=[[img],[img]]
imgg2=shift(imgg,0,28)
imgg=[imgg,imgg2]

if keyword_set(dif) then $
begin
imgx=xyi2img()
s=size(imgx)
img=(img-imgx)/(img+imgx) ;
print,'test:',min(img),max(img)
imgg=[[img],[img]]
imgg2=shift(imgg,0,28)
imgg=[imgg,imgg2]

end

fout=dialog_pickfile(/write)
end
if keyword_set(zooom) then imgg=congrid(imgg,s(1)*zooom,s(2)*zooom,cubic=-0.5)
write_png,fout,bytscl(imgg),r,g,b
if keyword_set(vis) then begin
goldpalette,/pure
tv,[bytscl(imgg),hist_equal(imgg)]
end
return,imgg
end

function contourxyi,a,cut=cut
if not(keyword_set(a)) then begin
a=xyiread()
help,a
b=xyiread()
help,b
a(2,*)=a(2,*)-b(2,*)
end
aa=reform(a(2,*),50,57)
;help,aa
s=size(aa)
if keyword_set(cut) then aa=aa(0:s(1)-2,0:s(2)-2)

aax=reform(a(0,*),50,57)
if keyword_set(cut) then aax=aax(0:s(1)-2,0:s(2)-2)

aay=reform(a(1,*),50,57)
if keyword_set(cut) then aay=aay(0:s(1)-2,0:s(2)-2)


contour,aa,aax,aay,/fill,/isotropic,nlevels=128,$
xrange=[min(aax),max(aax)],xstyle=1,$
yrange=[min(aay),max(aay)],ystyle=1,charsize=1.8,xtitle='X [A]',ytitle='Y [A]',$
title='Difference of +0.55V and +0.45V: line at ZERO',charthick=2.
contour,aa,aax,aay,levels=[0.],thick=2.,/overplot
print,'test:',min(aa),max(aa)
return,aa
end

pro rgb_goldpalette,r,g,b

ll=intarr(85)*0                                                                 
hl=intarr(85)+255                                                               
sl=indgen(85)*3                                                                 
ssl=indgen(170)*3/2+1  
r=[0,ssl,hl]                                                                    
g=[0,ll,ssl]                                                                    
b=[0,ll,ll,sl]

end
