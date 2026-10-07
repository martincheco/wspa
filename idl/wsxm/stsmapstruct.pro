function stsmapstruct,r,zcorr=zcorr
;makes an array of the ptrarr
;zcorr corrects Z positions of the curves at the first channel (Z)

if keyword_set(zcorr) then zc=1D else zc=0D

n=n_elements(r)
x=dblarr(n)
y=dblarr(n)
z=dblarr(n)

m=size((*r(0)).data)
rr=dblarr(n,m(1),m(2))

for i=0,n-1 do begin
	x(i)=(*r(i)).p.x
	y(i)=(*r(i)).p.y
	z(i)=(*r(i)).p.z
	rr(i,*,*)=(*r(i)).data-z(i)*zc
end

return,{data:rr,x:x,y:y,z:z};,chans:(*r(0)).chans}

end
