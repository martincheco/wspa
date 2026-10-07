
function despk,array,tol=tol,width=width
if not(keyword_set(tol)) then tol=0.1 ;standard 10 percent tolerance
if not(keyword_set(width)) then width=9 ;standard 9 point median filter

newarray=reform(array) ;need to clone the array not to overwrite it
dtm=median(newarray,width)
w=where( (newarray / dtm)-1. gt tol )


newarray(w)=dtm(w)

return,newarray
end

function lumi_despk,d,tol=tol,wid=wid
;runs a despiker on all spectra

s=size(d.map)

map=d.map

for i=0,s(1)-1 do for j=0,s(2)-1 do begin
	map(i,j,*)=despk(reform(map(i,j,*)),tol=tol,wid=wid)
end

return,{map:map,num:d.num,par:d.par,x:d.x,curr:d.curr}
end


function lumi_despk2d,d,tol,dry=dry
;runs a despiker on 2d slices
;dry run sends detected spikes to zero

s=size(d.map)
print,s
map=d.map
med=dblarr(s(3))

mn=min(map)

if keyword_set(dry) then fact=0. else fact=1.

for i=0,s(3)-1 do begin
	sl=reform(map(*,*,i))
	med=filter_image(sl,median=5,/all_pixels)
;	med(i)=median(sl,/double,/even)
;	w=where((sl-med(i)) gt tol)
	w=where((sl-med) gt tol)
	if w(0) ne -1 then begin
		sl(w)=med(w)*fact+mn*(1.-fact)
		map(*,*,i)=sl
	end
end

return,{map:map,num:d.num,par:d.par,x:d.x,curr:d.curr,med:med}
end

