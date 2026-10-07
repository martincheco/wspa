function offsets,iarr,nx,ny,base_i=base_i,real_i=real_i
help,real_i
;iarr in the form array(index,channel,xcoord, ycoord)=value
s=size(iarr)
if not(keyword_set(real_i)) then real_i=indgen(s(1))
s(1)=n_elements(real_i)
print,s
nx1=nx-nx/2
nx2=nx-nx1-1
ny1=ny-ny/2
ny2=ny-ny1-1

if not(keyword_set(base_i)) then base_i=0
result=intarr(s(1),s(2),nx,ny)
window,0,xs=s(3),ys=s(4)

for i=0,s(1)-1 do begin
print,'i,real_i'
print,i,real_i(i)
tvi=(reform((iarr(real_i(i),base_i,*,*))))
tvi=bytscl(tvi)
;print,s(4),ny2

tvi(*,s(4)-ny1)=255
tvi(*,ny2)=255
tvi(s(3)-nx1,*)=255
tvi(nx2,*)=255

tv,tvi
cursor,x,y,/device,/up

for j=0,s(2)-1 do begin
;if keyword_set(rmhyst) then lshift=get_shift(reform(iarr(real_i(i),base_i,*,*)),reform(iarr(real_i(i),j,*,*))) else lshift=[0,0]
;print,lshift
;x=x+lshift(0)
;y=y+lshift(1)
result(i,j,*,*)=reform(iarr(real_i(i),j,x-nx2:x+nx1,y-ny2:y+ny1))
end
end
return, result
end

function img_dump,res,vltg=vltg,smth=smth,norm=norm,unit=unit,mark=mark,inv=inv
;inv inverts
;smth smooths the image
;vltg array of parameters of each image
;mark prints it into the image

DEVICE, SET_FONT='Helvetica Bold', /TT_FONT

f=dialog_pickfile(/directory)
s=size(res)
print,s
if not(keyword_set(unit)) then unit=""
if not(keyword_set(vltg)) then vltg=string(indgen((s(1))),format='(I03)') ;else vltg=string(vltg,format='(F+06.2)')
res=double(res)
resr=res
resrr=resr
if keyword_set(smth) then begin
if (n_elements(smth) ne s(2)) then  $
begin
smt=intarr(s(2))+smth
smth=smt
end 
end else begin
smth=intarr(s(2))
end

print,smth

for i=0,s(1)-1 do begin
for j=0,s(2)-1 do begin
if (smth(j)) gt 1 then resr(i,j,*,*)=smooth(res(i,j,*,*),smth(j),/edge_truncate)
end
end


if keyword_set(norm) then begin
print,'normalizing each image'
for i=0,s(1)-1 do begin
 for j=0,s(2)-1 do begin
 resrr(i,j,*,*)=bytscl(reform(resr(i,j,*,*))) 
 end
end
end ;else begin
;print,'normalizing each channel'
;for i=0,s(1)-1 do begin
; for j=0,s(2)-1 do begin
;  resr(i,j,*,*)=resr(i,j,*,*)-min(resr(i,j,*,*)) 
; end
;end
;for j=0,s(2)-1 do begin
; resrr(*,j,*,*)=bytscl(resr(*,j,*,*))
; end
;end

window,2,xsize=s(3),ysize=s(4)
for i=0,s(1)-1 do begin
for j=0,s(2)-1 do begin
img=reform(resrr(i,j,*,*))
;print,f
print,i
if (keyword_set(unit)) then ef=f+'ch'+strtrim(string(j),1)+'_'+strtrim(vltg(i),1)+unit+'.png' $
else ef=f+'ch'+strtrim(string(j),1)+'_'+strtrim(string(i,format='(I003)'),1)+unit+'.png'
;print,ef

    if not(keyword_set(mark)) then a=img_save(ef,img) else begin
	imf=img
	tv,imf*255/max(imf)
	xyouts,0,0,strtrim(vltg(i),1)+unit,font=1,size=3.*s(4)/500.,/device
	if keyword_set(inv) then begin
	imf=tvrd(0)
	print,max(imf),min(imf)
	tv,255-imf
	end
	imf=tvrd(0,true=1)
	write_png,ef,imf
    end
end
end
wdelete,2
return,resrr
end

function get_shift,a,b ;determines an arbitrary shift between two similar or
;identical images a and b
s=size(a)
;print,s(1),s(2)
g=smooth(shift(ccor(a,b),s(1)/2,s(2)/2),3)
ii=where(g eq max(g))
r=[ii mod s(1)-s(1)/2,ii/s(1)-s(2)/2]
return,r
end

function rmshift,g,base_i=base_i,hdsft=hdsft,stuff=stuff
;hdsft is a forced shift in pixels
;g(index,channel,xpixel,ypixel)
;base_i reference frame
;stuff adds extra borders
if not(keyword_set(base_i)) then base_i=0
s=size(g)
print,s

x=intarr(s(1),s(2))
y=x

print,'x,y shift in img'
hardshift=0
if keyword_set(hdsft) then begin
    shdsft=size(hdsft)
    if s(1) eq shdsft(1) and s(2) eq shdsft(2) then hardshift=1 else hardshift=0
end

for i=0,s(1)-1 do begin
    for j=0,s(2)-1 do begin
	if i ne base_i then lshift=get_shift(reform(g(base_i,j,*,*)),reform(g(i,j,*,*))) else lshift=[0,0]
	;print,-lshift
	if hardshift then begin 
	    lshift=-hdsft(i,j,*)
	end
	
	x(i,j)=-lshift(0)
	y(i,j)=-lshift(1)
	print,x(i,j),y(i,j)

	;gg(i,j,*,*)=shift(reform(g(i,j,*,*)),x(i,j),y(i,j))
    end
end

if not(hardshift) then $
begin
    hdsft=intarr(s(1),s(2),2)
    for i=0,s(1)-1 do $
	for j=0,s(2)-1 do $
	    hdsft(i,j,*)=[x(i,j),y(i,j)]
end

gg=g


mnx=min((x))
mny=min((y))
mx=max((x))
my=max((y))
    if keyword_set(stuff) then begin
	gg=replicate(g(0,0,0,0)*0,s(1),s(2),s(3)-mnx+mx+1,s(4)-mny+my+1)
;	help,gg(*,*,mx-mnx:s(3)+mx-mnx-1,my-mny:s(4)+my-mny-1)
	gg(*,*,mx-mnx:s(3)+mx-mnx-1,my-mny:s(4)+my-mny-1)=g
    HELP,gg
    end 

for i=0,s(1)-1 do for j=0,s(2)-1 do gg(i,j,*,*)=shift(reform(gg(i,j,*,*)),x(i,j),y(i,j))

return,gg
end

pro prev_res,img,vltg,zoom=zoom
s=size(img)
if not(keyword_set(zoom)) then zoom=1.
print,"zoom:",zoom
window,0,xs=zoom*s(3),ys=zoom*s(4)+20
if not(keyword_set(vltg)) then vltg=indgen(s(1))

i=0
repeat begin
print,vltg(i)
tvscl,congrid(reform(img(i,0,*,*)),s(3)*zoom,s(4)*zoom,cubic=-0.8)
cursor,x,y,/up,/device
if x lt s(3)*zoom/2 then i=(i-1)>0 else i=i+1<(s(1)-1)
end until y gt s(4)
end