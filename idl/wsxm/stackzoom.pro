
function stackzoom,im,zom
s=size(im)
zom=(zom<8)>0.1
print,'Scaling factor: ' ,zom
if s(0) eq 3 then begin
	x=s(2)*zom
	y=s(3)*zom
	img=dblarr(s(1),x,y)*(-0./0.)
	for i=0,s(1)-1 do $
	if (where(finite(im(i,*,*))))(0) ne -1 then img(i,*,*)=congrid(reform(im(i,*,*)),x,y,/interp)
end

if s(0) eq 4 then begin
	img=dblarr(s(1),s(2),s(3)*zom,s(4)*zom) 
	for i=0,s(1)-1 do for j=0,s(2)-1 do img(i,j,*,*)=congrid(reform(im(i,j,*,*)),s(3)*zom,s(4)*zom,/interp) 
end 

return,img
end
