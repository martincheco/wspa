
function readlst,f,ext=ext
a=strarr(1024)
i=0
aa=''
openr,1,f
while not(EOF(1)) do begin
readf,1,aa

if not(keyword_set(ext)) then ext='.tf0'
if strpos(aa,'.par') ne -1 then begin
    p=strpos(aa,'.par')
    strput,aa,ext,p
    end

;print,aa
a(i)=aa
i=i+1
end
a=a(where(a))
close,1
return,a
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



function stackit,f,fact=fact,slope=slope,localslope=localslope,smooth=smooth,w_channel=w_channel, filelist=filelist
;READS, FILTERS, ARRANGES(INTERACTIVELY), DUMPS THE OUTPUT TO A STRUCTURE(ARRAY SPEC.)
;slope - subtr_plane
;smooth - smooth the image, how much
;fact - factor for the inversion
;w_channel - ?

if (keyword_set(fact)) then print, 'fact=-1: Fine, why not.' else fact=1 ;inverse the picture

if keyword_set(filelist) then f=readlst(filelist) ;reading list of files (needs full paths)

if not(keyword_set(f)) then f = dialog_pickfile(/read, /must_exist, /multiple_files, filter = '*.tf0')
print,f

;f=omicron_sort(f)
ads=fltarr(n_elements(f))
;times=strarr(n_elements(f))
shiftx=intarr(n_elements(f))
shifty=shiftx
taste=rd_int_img(f(0))
print,'Tasting the first file.. Yummy :)'
help,taste
sz=size(taste)
n=sz(1)
stack=intarr(n_elements(f),2*n,2*n)+1 ; image for arranging
w_stack=stack ;processing image

print,'data loading>'

for i=0,n_elements(f)-1 do begin
p_img=fact*rd_int_img(f(i)) ; reads the img used for data processing
if keyword_set(slope) then p_img=rowsequal(subtrplane(truncate(p_img)))
if keyword_set(localslope) then p_img=rowsequal(subtrplane(truncate(p_img)),/backplane)
if keyword_set(smooth) then p_img=smooth(p_img,smooth > 3)
p_img=p_img-min(p_img)
fl=f(i)


if keyword_set(w_channel) then begin 
strput,fl,w_channel,strpos(fl,'.t')+1
w_img=(((rd_int_img(fl))))  
end $
else w_img=p_img
;reads an img to use when arranging

stack(i,0:n-1,0:n-1)=p_img
w_stack(i,0:n-1,0:n-1)=w_img 
endfor

print, 'Choose the points>'
goldpalette
window,xsize=2*n, ysize=n

imr=intarr(n,n)
imrl=imr
imrr=imr

window,1,xsize=n/2, ysize=n/2,xpos=10,ypos=100


for i=0,n_elements(f)-1 do $
begin
 immo=imrr
 imr(0:n-1,0:n-1)=w_stack(i,0:n-1,0:n-1) ; prepsani do tv promenne 
 imrr=tvscaled(imr,mincolor=1) ;skalovani??
 imrl=tvscaled(imrl,mincolor=1)
 wset,0
 tvg,[imrr,immo]


  if not(keyword_set(auto)) then $
   begin
   print, 'Mark offset.'

   xv=n/2
   yv=n/2

   imoriao=reform(rebin(w_stack(i,*,*),1,n/2,n/2),n/2,n/2)
    while xv lt n do begin
     wset,0
     xvd=xv
     yvd=yv
     cursor,xv,yv,/device
     wset,1
     immmm=shift(imoriao,(n-xv)/4,(n-yv)/4)
     if xv lt n then tvg,bytscl(immmm)
    end
    stack(i,*,*)=shift(stack(i,*,*),0,n-xvd,n-yvd)
 wset,0
shiftx(i)=xvd
shifty(i)=yvd
     
 imrr(xvd,yvd)=0
 end
 
endfor


results=create_struct('output',stack,'shiftx', shiftx,'shifty',shifty)

return,results
end

pro saveblock,f,dat
openw,3,f
writeu,3,dat
close,3
openw,4,f+'.nfo'
writeu,4,size(dat.output)
close,4
end


function loadblock,f
openr,2,f+'.nfo'
g=lonarr(6)
readu,2,g
print,g
close,2

;ads=strarr(g(1))
;time=ads
shiftx=intarr(g(1))
shifty=shiftx
output=intarr(g(1),g(2),g(3))


results=create_struct('output',output,'shiftx', shiftx,'shifty',shifty)

openr,3,f
readu,3,results
close,3

return,results
end

pro image_dump,b,heq=heq,max_filter=max_filter;needs a stack of images to write them
s=size(b)

for j=0, s(1)-1 do begin
imgi=(total(bytscl(b(j,*,*)),1))
if keyword_set(max_filter) then imgi=max_filter(imgi)
if keyword_set(heq) then imgi=hist_equal(imgi)
t=img_save('Mi.'+strtrim(string((j)),1)+'.png',imgi)
end

end