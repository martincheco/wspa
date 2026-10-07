
pro distort_draw,res,zoom=zoom,decim=decim,offs=offs
;draws the result, using the structure returned by the distort function

if not(keyword_set(decim)) then decim=1

if keyword_set(zoom) then begin
    s=size(res.a)
    a=congrid(res.a,s(1)*zoom,s(2)*zoom)
    b=congrid(res.b,s(1)*zoom,s(2)*zoom)
    xy0=res.xy0*zoom
    xy=res.dxy*zoom
end else begin
    a=res.a
    b=res.b
    xy0=res.xy0
    xy=res.dxy
end

if keyword_set(offs) then xy=xy-total(xy,/double)/n_elements(xy)

tvscl,[a,b]
s=size(xy0)
for i=0,s(1)-1,decim do for j=0,s(2)-1,decim do begin
    plots,[real_part(xy0(i,j)),real_part(xy0(i,j)+xy(i,j))],[imaginary(xy0(i,j)),imaginary(xy0(i,j)+xy(i,j))],psym=-3,color=255
    plots,[real_part(xy0(i,j)+xy(i,j))],[imaginary(xy0(i,j)+xy(i,j))],psym=3
end
end

;will smooth the result, thus improving the distortion
;function distort_improve,res
;dxy=res.dxy
;xy0=res.xy0
;s=size(xy0)
;    

;end

function distort_cmask,x,d
;generates circular mask
xx=dindgen(x)-double(x)/2+0.5
i=mreplicate(xx,x)
j=transpose(i)
dd=d^2
w=where(i^2+j^2 le dd)
i=i*(-0./0.) ;fill with Nan
if w(0) ne -1 then i(w)=1.
return,i 
end


function distort_shift,a,b,d,vis=vis ;determines an arbitrary shift between two similar or
;identical size images a and b, d is the diameter of the circular mask
s=size(b)

cmsk=distort_cmask(s(1),d)
ncmsk=total(finite(cmsk,/nan))
;print,ncmsk
bb=b*cmsk
if total(finite(bb,/nan)) ne ncmsk then return,complex(0.,0.)
aa=reform(a,1,s(1),s(2))
bb=reform(bb,1,s(1),s(2))

;find a shift between the two supplied images, restrict to x,y, motion only
gr=register_iter(bb,aa,1.,0.,0.,0.,0.,0.,0.,step=[0.,0.,0.,2.,2.,0.,0.],mask=[0.,0.,0.,1.,1.,0.,0.],/norot,vis=vis,/silent)


r=complex(gr.vect(3),gr.vect(4))
return,r
end


function distort,ao,bo,st,d,p,draw=draw,vis=vis
;ao,bo - grayscale images (or data) must be the same size
;function maps a to b
;st - grid base size
;d - diameter of the search motive
;p - radius of the search background
;vis - visualisation, slows down the calculation!!

a=ao
b=bo

s=size(a)
m=s(1)/st ;number of tiles
n=s(2)/st
p=p>d ;ensure background is at least as the search motive
pst=(p/st)+1

xy=complexarr(m,n) ;vectors
xy0=xy
;tvscl,[b,a]
td=systime(/seconds)

for i=pst,m-pst-1 do begin
print,'Row:',i,'/',m-2
	for j=pst,n-1-pst do begin
		xy0(i,j)=complex(i*st,j*st)
		dis=distort_shift(ao(i*st-p:i*st+p,j*st-p:j*st+p),bo(i*st-p:i*st+p,j*st-p:j*st+p),d,vis=vis)
		xy(i,j)=dis
	end
	dt=(systime(/seconds)-td)
	print,'TOTAL(sec)/ETA(min): ',dt,'/',round(dt*(m-pst-1-i)/(i+1)/60.)
end

res={xy0:xy0(pst:m-1-pst,pst:n-1-pst),dxy:xy(pst:m-1-pst,pst:n-1-pst),a:ao,b:bo}

if keyword_set(draw) then distort_draw,res,zoom=1,/offs

return,res

end
