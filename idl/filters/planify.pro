
function planify_line, ln,slope=slope, funct=funct
n=n_elements(ln)
mx=ln(0)
mn=ln(n-1)
asp=(mn-mx)

span=abs(asp)

llim=asp-3*span/2
hlim=asp+3*span/2

;print,mx,mn,asp
;print,llim,hlim
curv=dblarr(abs(hlim-llim)+1)


for i=llim,hlim do begin
lnm=ln-(findgen(n)*i)/n
h1=histogram(lnm, nbins=n)
curv[i-llim]=float(n_elements(where(h1 gt 1)))*float(n_elements(where(h1 ne 0)))
end

nc=n_elements(curv)
if nc gt 30 then curvv=smooth(curv,10) else curvv=curv
pos=where(curvv eq min(curvv))
ps=pos(0)
;if ps eq 0 or ps eq n_elements(curv) then ps=asp
;print,asp,ps+llim
lnmm=ln-findgen(n)*float(ps+llim)/n
if keyword_set(funct) then return, curv else $
if keyword_set(slope) then return,ps+llim else return, lnmm
end


function planify, img, speed,xonly=xonly
;sharpens the histogram by subtracting slope to each line
;speed is the number of lines to skip in the calculation

s=size(img)
m=s(1)
n=s(2)
imgm=img
if not(keyword_set(speed)) then speed=50. else speed=(speed>1)<50
slopex=fltarr(n/speed)

for i=0,n/speed-1 do begin
slopex(i)=planify_line(reform(img(*,i*speed)),/slope)
;print,i
end

xslope=findgen(m) # replicate(mean(slopex)/m,n)
imgm=img-xslope
if not(keyword_set(xonly)) then imgm=rowsequal(imgm)
return, imgm-min(imgm)
end

function hist_byline,img
;imgm=planify(img)
imgm=img-min(img)
mn=0
mx=max(imgm)
h=histogram(imgm,min=mn,max=mx)
n=n_elements(h)-1
s=size(img)
histar=lonarr(n,s(2))

for i=0,s(1)-1 do begin
;print,i
histar(*,i)=histogram((imgm(*,i)),nbins=n, min=mn,max=mx)
end

return,histar
end

function corr_line_hists,imgm
img=imgm-min(imgm)
imgn=img

s=size(img)
for i=1,s(2)-1 do begin

shft=corrij(img,i-1,i)

imgn(*,i)=img(*,i)-shft
end

return,imgn-min(imgn)
end

function corrij,imgm,i,j
img=imgm-min(imgm)
s=size(img)
mx=max(img)

hib=histogram(img,binsize=1,max=mx)

nb=n_elements(hib)

half=3*mx/2

hib=[hib*0,hib,hib*0]

line1=reform(img(*,i))
line1h=histogram(line1,binsize=1,max=mx)
line1h=[line1h*0,line1h,line1h*0]

line2=reform(img(*,j))
line2h=histogram(line2,binsize=1,max=mx)
line2h=[line2h*0,line2h,line2h*0]
cor=ccor(line1h,line2h)
cor=shift(abs(cor),half)
shft=where((cor) eq max(cor))
shft=shft(0)
;print,shft-half,mean(line1-line2)

return,cor
end

function selmean,imgm,w,lim
lim=abs(lim)
s=size(imgm)
img=imgm*0
for i=0,s(1)-1 do begin
for j=0,s(1)-1 do begin
piece=imgm(i-w>0:i+w<s(1)-1,j-w>0:j+w<s(2)-1)
point=imgm(i,j)
img(i,j)=mean(piece(where(abs(piece-point) lt lim)))
end
end

return,img
end

function flood,imgm,i,j,lim,protect=protect
st=1
s=size(imgm)
key=bytarr(s(1),s(2))
;tvscl,[bytscl(key),bytscl(imgm)]
oldkey=key
bkey=key+1B
key(i,j)=1B
bkey(0:st,*)=0B
bkey(s(1)-st-1:*,*)=0B
bkey(*,0:st)=0B
bkey(*,s(2)-st-1:*)=0B
pp=lonarr(9)

n=n_elements(imgm)
ckey=key
;print,where(ckey)
p=where(ckey)

 while p(0) ne -1 do begin

oldkey=key
men=mean(imgm(p))
  for i=0,n_elements(p)-1 do begin
val=imgm(p(i))
;pp[1]=(p(i)+1)
;pp[2]=(p(i)-1)
;pp[3]=(p(i)+s(1))
;pp[4]=(p(i)-s(1))
;pp[5]=(p(i)+s(1)+1)
;pp[6]=(p(i)-s(1)-1)
;pp[7]=(p(i)+s(1)-1)
;pp[8]=(p(i)-s(1)+1)

pp[1]=(p(i)+st)
pp[2]=(p(i)-st)
pp[3]=(p(i)+st*s(1))
pp[4]=(p(i)-st*s(1))
pp[5]=(p(i)+st*s(1)+st)
pp[6]=(p(i)-st*s(1)-st)
pp[7]=(p(i)+st*s(1)-st)
pp[8]=(p(i)-st*s(1)+st)

for o=1,8 do begin
if keyword_set(protect) then logic=abs(val-imgm(pp[o])) lt lim and (abs(men-imgm(pp[o])) lt lim/2) $
else logic=abs(val-imgm(pp[o])) lt lim
if logic then key(pp[o])=1B
end

end
;tvscl,[bytscl(key),bytscl(imgm)]
;tvscl,key
ckey=(key-oldkey) * bkey
p=where(ckey)

 end

;img=imgm
;img(where(key))=0

return,key
end

pro areas,img,filen=filen,raw=raw,area=area
;interactive routine for extracting flat regions of different heights
;img = processed image:type any 2D
;filen(opt.) = filename of the file
;area(opt.) = output variable
;raw(opt. switch) = do not perform the planify and double flattening on the image
;
;selected point is the origin for the flood function, result is imaged,
;added by clicking on the right of the image.

if not(keyword_set(img)) then if (keyword_set(filen)) then $
img=rd_int_img(filen) else img=rd_int_img()

s=size(img)
window,1,xsize=s(1)*2+20,ysize=s(2)
goldpalette
imgps=img

if not(keyword_set(raw)) then $
    begin
    ;tv,tvscaled(img)
    ;print,'planifying'
    imgp=planify(img)
    ;print,'flattening'
    imgps=selmean(imgp,15,10)
    ;print,'reflattening'
    imgps=selmean(imgps,15,10)
    end

;tv,[imgps*0,tvscaled(imgps)]
;cursor,x,y,/up,/device
x=s(1)/2+s(1)
y=s(2)/2
bexit=0
bnewa=0
bsele=0
nset=0
narea=0
area=bytarr(s(1),s(2),16) ;max no of different sets
mask=imgps*0
        tv,[bytscl(mask+reform(area(*,*,nset))*2),boost(bytscl(imgps))]
while not(bexit) do $
    begin
	;print,x-s(1),y
        ;print,'Flooding'
        if x-s(1) lt s(1) and x-s(1) gt 0 then mask=flood(imgps,x-s(1),y,10,/protect) $
        else mask=mask*0
        tv,[bytscl(mask+reform(area(*,*,nset))*2)]
        cursor,x,y,/up,/device
        bexit=(x gt s(1)*2 and y gt 2*s(2)/3)
	bsele=(x gt s(1)*2 and y gt s(2)/3 and y lt 2*s(2)/3)
	bnewa=(x gt s(1)*2 and y lt s(2)/3)

	if bsele then $
	    begin
		mask2=mask*0
		mask2(where(reform(area(*,*,nset)) + mask))=1
		area(*,*,nset)=mask2
		narea=narea+1
	    end

	if bnewa then $
	    begin
		if nset lt 15 then nset=nset+1
		narea=0
	    end

	;print,'narea:'+string(narea)+'; nset:'+string(nset)
    end
    
imgps=imgps*0
for i=0,15 do imgps=imgps+area(*,*,i)*(i+1)
tvscl,imgps
imgps=imgps*0
if not(keyword_set(filen)) then filen="output"
ps=STRPOS(filen,'.t')
if ps then filen=STRMID(filen,0,ps)
for i=0,nset+1 do $
    begin
	wh=where(area(*,*,i))
	if wh(0) gt -1 then begin
	imgps(wh)=imgps(wh)+1
	av=mean(imgp(wh))
	imgps(wh)=imgps(wh)+1
	end else begin
	av=-1
	if i gt nset then area(*,*,i)=imgps 
	wh=where(area(*,*,i)) ;prasarna
	end

	print,'average:',av
	rfile=filen+STRTRIM(string(n_elements(wh)),2)+'_'+STRTRIM(STRING(fix(av)),2)+'.png'
	
	print,rfile
	t=img_save(rfile,bytscl(area(*,*,i)),/grey)
    end
print,'See the error map..'
tvscl,imgps
end