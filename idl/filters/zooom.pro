function zooom,img,zm,xsize=xsize,ysize=ysize
s=size(img)

if n_elements(zm) ne 2 then zm=[zm,zm]
if keyword_set(xsize) or keyword_set(ysize) then $
begin
    zm(0)=(zm(0)>10)<2000;limitation
end else begin
    zm(1)=(zm(1)>0.1)<(2000./s(1));limitation
end

if zm(0) ne 1.0 or zm(1) ne 1.0 then $
    if keyword_set(xsize) then $
	imf=congrid(img,zm(0),s(2)*zm(1)/s(1),cubic=-0.5) $
     else $
	if keyword_set(ysize) then $
	    imf=congrid(img,s(1)*zm(0)/s(2),zm(1),cubic=-0.5) $
	else $
	    imf=congrid(img,s(1)*zm(0),s(2)*zm(1),cubic=-0.5) $
else imf=img


return,imf
end
