function rmshift,g,base_i=base_i,chan=chan,stuff=stuff,missing=missing,reg=reg,shfts=shfts,hdsft=hdsft;,block=block
;hdsft is a forced shift in pixels
;g(index,channel,xpixel,ypixel)
;base_i reference frame
;chan is the reference channel
;stuff adds extra borders
;block - an array defining which axes are not moved
;reg forces iterative registration (register2)
;shfts - will contain the shifts

if not(keyword_set(base_i)) then base_i=0
if not(keyword_set(chan)) then chan=0
if not(keyword_set(missing)) then missing=(-0./0.)
s=size(g)
print,s

x=intarr(s(1))
y=x

print,'x,y shift in img'

if not(keyword_set(hdsft)) then $
for i=0,s(1)-1 do begin
    if i ne base_i then lshift=get_shift(reform(g(base_i,chan,*,*)),reform(g(i,chan,*,*)),reg=reg) else lshift=[0,0]

;    for j=0,s(2)-1 do begin
	x(i)=-lshift(0)
	y(i)=-lshift(1)
	print,x(i),y(i)
;    end
end else print,'Shifts Imposed!'

    shfts=intarr(s(1),2)
    for i=0,s(1)-1 do $
	for j=0,s(2)-1 do $
	    shfts(i,*)=[x(i),y(i)]

gg=g

if keyword_set(hdsft) then begin
    x=reform(hdsft(*,0))
    y=reform(hdsft(*,1))
end

mnx=min((x))
mny=min((y))
mx=max((x))
my=max((y))

print,s
if keyword_set(stuff) then begin
    gg=replicate(missing,s(1),s(2),s(3)-mnx+mx+1,s(4)-mny+my+1)
    ;gg(*,*,-mnx:s(3)-mnx-1,-mny:s(4)-mny-1)=g
    HELP,gg
    gg(*,*,-mnx:s(3)-mnx-1,-mny:s(4)-mny-1)=g
    
end

;if keyword_set(block) then begin
;    x=block(0)*x
;    y=block(1)*y
;end

;for i=0,s(1)-1 do for j=0,s(2)-1 do gg(i,*,*,*)=shift(reform(gg(i,j,*,*)),0,reform(x(i)),reform(y(i)))
for i=0,s(1)-1 do gg(i,*,*,*)=shift(reform(gg(i,*,*,*)),0,x(i),y(i))
;if keyword_set(missing) then for i=0,s(1)-1 do begin
;	xlo=0
;	xhi=-1
;	ylo=0
;	yhi=-1
;	if x(i) gt 0 then xhi=x(i)+1 else xlo=x(i)-2
;	if y(i) gt 0 then yhi=y(i)+1 else ylo=y(i)-2
;	if x(i) ne 0 then gg(i,*,xlo:xhi,*)=(-0./0.);missing
;	if y(i) ne 0 then gg(i,*,*,ylo:yhi)=(-0./0.);missing
;	print, xlo,xhi,ylo,yhi
;end


return,gg
end
