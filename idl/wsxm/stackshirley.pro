function stackshirley,d,individual=individual,rev=rev
;subtracts shirley bkg obtained thru integrating
;works on single curves as well

s=size(d)

dt=d
if s(0) eq 1 then dt = reform(d,s(1),1,1)
if s(0) eq 2 then dt = reform(d,s(1),s(2),1)


s=size(dt)

ing=dt*0D
;mn=min(dt)
;for k=s(1)-2,1,-1 do ing(k,*,*)=ing(k+1,*,*)+(dt(k+1,*,*)-mn)


if keyword_set(rev) then dt=reverse(dt,1)


ndt=dt
for i=0,s(2)-1 do for j=0,s(3)-1 do begin
	dtb=dt(*,i,j);-min(dt(*,i,j))
	ndt(*,i,j)=dtb
	ing(*,i,j)=dtb
	for k=s(1)-2,1,-1 do ing(k,i,j)=ing(k+1,i,j)+dtb(k+1)
end

if not(keyword_set(individual)) then begin
	sz=size(ing)

	if sz(0) gt 1 then inga=total(total(ing,1,/double),1,/double)/double(sz(2))/double(sz(3)) else inga=ing
	for i=0,s(2)-1 do for j=0,s(3)-1 do ing(*,i,j)=inga
end

if keyword_set(rev) then return,reverse(ndt-ing/double(s(1)),1) else $
return,ing/double(s(1))

end
