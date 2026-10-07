pro tvrange, b,zoom; zobrazi blok v pekne reprezentaci
j=where(b.voltage lt 0.)
k=where(b.voltage gt 0.)
s=size(b.current)
if not(keyword_set(zoom)) then zoom=1.
filled2=bytscl(total(b.lockin(j(0:n_elements(j)/2-1),*,*),1))
empty=bytscl(total(b.lockin(k,*,*),1))
filled1=bytscl(total(b.lockin(j(n_elements(j)/2:*),*,*),1))
c=(intarr(3,s(2),s(3)))
c(0,*,*)=filled1
c(2,*,*)=filled2/2
c(1,*,*)=empty
tv,congrid(c,3,zoom*s(2),zoom*s(3),cubic=-.5),true=1
end

pro tvg,img
img=float(img)
;imgr=255-img
imgr=img
imgb=img
imgg=img
;imgb=255.-2.*img
;p=where(imgb lt 0.)
;if p(0) ne -1 then imgb(p)=0.

;imgg=img*0.
;imgg=(img-128)*2
;p=where(imgg lt 0.)
;if p(0) ne -1 then imgg(p)=0.

;imgr=255-abs(2*img-255)




imgrgb=fix([[[imgr]],[[imgg]],[[imgb]]])
tv,bytscl(imgrgb),true=3
end




function filelist
f = dialog_pickfile(/read, /must_exist, /multiple_files, filter = '*.tf1')
as=fltarr(n_elements(f))
for i=0,n_elements(f)-1 do $
begin
fd=f(i)
strput,fd,'par',strpos(fd,'tf1')
d=loadstm(fd)
help,(d.parameters.voltageforward)
as(i)=(d.parameters.voltageforward)
endfor
ase=string(as(sort(as)))
f=f(sort(as))
print,transpose([[ase],[f]])

return,transpose([[ase],[f]])
end

function blockit,f,fact=fact,linext=linext,auto=auto,rmdrift=rmdrift
if (keyword_set(fact)) then print, 'Fine.' else fact=1 ;kvuli invertovanym obrazkum
if not(keyword_set(f)) then f = dialog_pickfile(/read, /must_exist, /multiple_files, filter = '*.tf1')
n=400
ads=fltarr(n_elements(f))
currents=ads
shiftx=intarr(n_elements(f))
shifty=shiftx
imori=intarr(n_elements(f),2*n,2*n)+1
imoril=intarr(n_elements(f),2*n,2*n)+1;lockin
imoria=imori
imorila=imoril
print,'First cycle - Voltage reading, data loading>'

for i=0,n_elements(f)-1 do $
begin

;iii=rowsequal(subtrplane(truncate(rd_int_img(f(i)))))
iii=truncate(fact*rd_int_img(f(i)))

fl=f(i)
if keyword_set(linext) then begin ; lockin
strput,fl,linext,strpos(fl,'.t')
iiil=rd_int_img(fl)
 if keyword_set(rmdrift) then $
 begin
 zzzz=[iii,iiil]
 zzzz=removedrift(zzzz,/hard,n=100,base_i=0)
 imoril(i,0:n-1,0:n-1)=reform(zzzz(1,*,*))
 imori(i,0:n-1,0:n-1)=reform(zzzz(0,*,*))
 end
end

if keyword_set(rmdrift) and not(keyword_set(linext)) then $
begin
iii=removedrift(iii,/hard,n=100)
imori(i,0:n-1,0:n-1)=iii ;?for mosaic
end


fd=f(i)
strput,fd,'.par',strpos(fd,'.t')
d=loadstm(fd)
ads(i)=d.parameters.voltageforward
currents(i)=d.parameters.currentforward

endfor

print,'**>>Sorting<<**'
f=f(sort(ads))
imori(*,*,*)=imori(sort(ads),*,*)
if keyword_set(linext) then imoril(*,*,*)=imoril(sort(ads),*,*) ; lockin
currents=currents(sort(ads))
ads=ads(sort(ads))


print, 'Second cycle>'
goldpalette
window,xsize=2*n, ysize=n

imr=intarr(n,n)
imrl=imr
imrr=imr

window,1,xsize=n/2, ysize=n/2,xpos=10,ypos=100


for i=0,n_elements(f)-1 do $
begin
 immo=imrr
 imr(0:n-1,0:n-1)=imori(i,0:n-1,0:n-1) ; prepsani do tv promenne 
 if keyword_set(linext) then imrl(0:n-1,0:n-1)=imoril(i,0:n-1,0:n-1)
 imrr=tvscaled(imr,mincolor=1) ;skalovani??
 imrl=tvscaled(imrl,mincolor=1)
 wset,0
 tvg,[imrr,immo]


  if not(keyword_set(auto)) then $
   begin
   print, 'Mark offset.'
   print,'Voltage',ads(i)

   xv=n/2
   yv=n/2

   imoriao=reform(rebin(imori(i,*,*),1,n/2,n/2),n/2,n/2)
    while xv lt n do begin
     wset,0
     xvd=xv
     yvd=yv
     cursor,xv,yv,/device
      if xv lt n then begin
        imoria(i,*,*)=shift(imori(i,*,*),0,n-xv,n-yv) ; !!new array
        if keyword_set(linext) then imorila(i,*,*)=shift(imoril(i,*,*),0,n-xv,n-yv) ; lockin
      end
     wset,1
     immmm=shift(imoriao,(n-xv)/4,(n-yv)/4)
     if xv lt n then tvg,bytscl(immmm)
    end
 wset,0
if keyword_set(auto) then begin
xvd=1
yvd=1
xv=1
yv=1
end
     
 imrr(xvd,yvd)=0
 end
 
endfor

if not(keyword_set(linext)) then linext='no_STS'
results=create_struct('current',imoria,'lockin',imorila,'voltage',ads,'current0',currents,$
'shiftx', shiftx,'shifty',shifty,'linext',linext)

return,results
end

pro saveblock,f,dat
openw,3,f
writeu,3,dat
close,3
openw,4,f+'.nfo'
writeu,4,size(dat.current)
close,4
end

function loadblock,f
openr,2,f+'.nfo'
g=lonarr(6)
readu,2,g
print,g
close,2

ads=fltarr(g(1))
currents=ads
shiftx=intarr(g(1))
shifty=shiftx
imoria=intarr(g(1),g(2),g(3))
imorila=intarr(g(1),g(2),g(3));lockin
linext=''

results=create_struct('current',imoria,'lockin',imorila,'voltage',ads,'current0',currents,$
'shiftx', shiftx,'shifty',shifty,'linext',linext)

openr,3,f
readu,3,results
close,3

return,results
end

function signum,i
if i gt 0 then sign=1 else sign=-1
if i eq 0 then sign=0
return,sign
end

function normalize_area,t
;normalizes everything given 
;ioffs is the current setpoint in A/D units(int)
help,t,/struct
s=size(t.current)
tcurrent=double(t.current)

for i=0,s(1)-1 do tcurrent(i,*,*)=tcurrent(i,*,*)*0.00015259+signum(t.voltage(i))*t.current0(i)
help,tcurrent

j=where(abs(t.current) lt 0.001)
print,j
if j(0) ne -1 then tcurrent(j)=0.001
tlockin=double(t.lockin+1200)
for i=0,s(1)-1 do tlockin(i,*,*)=(tlockin(i,*,*))*t.voltage(i);-min(extremesexcluded(tlockin(i,*,*)))
help,tlockin
tvscl,tlockin(12,*,*)
tvscl,tcurrent(12,*,*)
return,tlockin/tcurrent
end


function curves_pre,block,ablock,f ;temporary, take it easy
s=size(block)
if s(2) lt 400 and (3) lt 400 then zoom=2
window,xsize=s(2)*zoom+20,ysize=s(3)*zoom+20
window,1,xsize=400,ysize=200,xpos=10,ypos=500
block(4,s(2)-1,*)=0
block(4,*,s(3)-1)=0
wset,0
tvrange,ablock,zoom

curve=dblarr(2,s(1))
curve(0,*)=ablock.voltage
cntr=0
  xv=s(2)/2
  yv=s(3)/2
wset,1
while yv lt s(3)-3 do begin
  xv=s(2)/2
  yv=s(3)/2

    while xv lt s(2)-3 and yv lt s(3)-3 do begin
    wset,0 
    xvd=xv
     yvd=yv
     cursor,xv,yv,/device,/up
     xv=xv/zoom
     yv=yv/zoom 
     wset,1
     if xv lt s(2)-3 and yv lt s(3)-3 then begin
      plot,ablock.voltage,total(total(block(*,xv-1:xv+1,yv-1:yv+1),2),2)/9,color=128      
      oplot,ablock.voltage,block(*,xv,yv)
      end
    end

 if xvd lt s(2)-3 and yvd lt s(3)-3 then $
  begin
  curve(1,*)=curve(1,*)+total(total(block(*,xvd-1:xvd+1,yvd-1:yvd+1),2),2)/9.
  if yv lt s(3)-3 then cntr=cntr+1
  plot,curve(0,*),curve(1,*)
  end
print,cntr
plot,curve(0,*),curve(1,*)
  
end

wset,0
if cntr ne 0 then curve(1,*)=curve(1,*)/cntr

j=where(ablock.voltage lt 0)
k=where(ablock.voltage gt 0)
curvep=curve(*,k)
curvem=curve(*,j)

;print,total(curve(1,*))

if total(curve(1,*)) gt 0 then begin 
plot,curve(0,*),curve(1,*),/nodata
oplot,curvem(0,*),curvem(1,*),psym=-7
oplot,curvep(0,*),curvep(1,*),psym=-7
end
if not(keyword_set(f)) then begin 
print, 'Select a name for the curve'
f = dialog_pickfile(/write)
if f(0) eq ''  then return,curve
end
savecurve,curvem,f+'_avg_'+strtrim(string(cntr),2)+'-.dat'
;print,f
savecurve,curvep,f+'_avg_'+strtrim(string(cntr),2)+'+.dat'

return, curve
end


pro save_images,blockx
end


function imagesequence,block,r
j=where(block.voltage lt 0.)
k=where(block.voltage gt 0.)
s=size(block.current)
filled=bytscl(total(block.lockin(j,*,*),1))
empty=bytscl(total(block.lockin(k,*,*),1))
if not(keyword_set(r)) then r=s(2)/2

b=(intarr(3,s(2),s(3)))
b(0,*,*)=filled
b(1,*,*)=empty
b(2,s(2)-1,*)=255
window,xsize=s(2)+r/2,ysize=s(3)

tv,b,true=1
xv=s(2)/2
yv=s(3)/2
while xv lt s(3) do begin
xvd=xv
yvd=yv

cursor,xv,yv,/device
if xv gt r/2 and yv gt r/2 and $
xv lt s(2)-r/2-1 and yv lt s(2)-r/2-1 then $
begin
tvscl,congrid(b(*,xv-r/2:xv+r/2-1,yv-r/2:yv+r/2-1),3,2*r,2*r,cubic=-.5),true=1
print,xv,yv
end
end
print,xvd,yvd
current=block.current(*,xvd-r/2:xvd+r/2-1,yvd-r/2:yvd+r/2)
lockin=block.lockin(*,xvd-r/2:xvd+r/2-1,yvd-r/2:yvd+r/2)
blockx=create_struct('current',current,'lockin',lockin,'voltage',block.voltage,$
'current0',block.current0,$
'shiftx', block.shiftx,'shifty',block.shifty,'linext',block.linext)


return,blockx
end

pro savecurve,curve,f
if not(keyword_set(f)) then f = dialog_pickfile(/write)
print,f
help,f
if f(0) eq ''  then begin
print,'Duh! No filename selected. Curve not saved!'
return
end
openw,1,f
printf,1, curve
close,1
end

pro image_dump,b,smth=smth,zoom=zoom;doplnit rozliseni, zda existuje lockin nebo ne
if not(keyword_set(zoom)) then zoom=1.
s=size(b.current)
;print,s
;if not(keyword_set(smth)) then smth=2

if smth gt 2 then for j=0,s(1)-1 do begin
b.current(j,*,*)=smooth(total(b.current(j,*,*),1),smth)
b.lockin(j,*,*)=smooth(total(b.lockin(j,*,*),1),smth)
end

for j=0, s(1)-1 do begin

if b.voltage(j) lt 0. then fact=-1 else fact=1
imgi=tvscaled(congrid(total(bytscl(fact*b.current(j,*,*)),1),s(2)*zoom,s(3)*zoom,cubic=-.5),mincolor=2,maxcolor=254)
imgl=tvscaled(congrid(total(bytscl(b.lockin(j,*,*)),1),s(2)*zoom,s(3)*zoom,cubic=-0.5),mincolor=2,maxcolor=254)

t=img_save('Mi.'+strtrim(string(b.voltage(j)),1)+'.png',imgi)
t=img_save('Ml.'+strtrim(string(b.voltage(j)),1)+'.png',imgl)

end

end