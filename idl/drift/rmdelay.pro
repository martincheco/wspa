function rmdelay,g,ch1,ch2,stuff=stuff,reg=reg,cpdelay=cpdelay
;determines a mutual shift of fwd and bwd channels in X
;puts Nan's to mean
;g(index,channel,xpixel,ypixel)
;ch1,ch2 are the fwd and bwd measurement of the same channel
;stuff adds extra borders
;cpdelay are additional pairs of channels to be shifted accordingly
s=size(g)

x=intarr(s(1))
y=x



print,'x,y shifts in imgs'
hardshift=0

;if keyword_set(hdsft) then begin
;    shdsft=size(hdsft)
;    if s(1) eq shdsft(1) and s(2) eq shdsft(2) then hardshift=1 else hardshift=0
;end

for i=0,s(1)-1 do begin

    lshift=get_shift(rmnan(reform(g(i,ch1,*,*))),rmnan(reform(g(i,ch2,*,*))),reg=reg)

	x(i)=-lshift(0)
	y(i)=-lshift(1)
;	print,x(i),y(i)
end

;    hdsft=intarr(s(1),2)
;    for i=0,s(1)-1 do $
;	    hdsft(i,*)=[x(i),y(i)]

gg=g


mnx=min((x))
mny=min((y))
mx=max((x))
my=max((y))

print,s
print,mx,my,mnx,mny


ax=median(x)

help,ax
sh=abs((ax))


if keyword_set(stuff) then begin
    gg=replicate(g(0,0,0,0)*0/0,s(1),s(2),s(3)+sh+1,s(4))
    HELP,gg
    gg(*,*,0+sh/2+1:s(3)+sh/2,*)=g
end


;for i=0,s(1)-1 do for j=0,s(2)-1 do gg(i,*,*,*)=shift(reform(gg(i,j,*,*)),0,reform(x(i)),reform(y(i)))
gg(*,ch1,*,*)=shift((gg(*,ch1,*,*)),0,0,round(-ax/2),0)
gg(*,ch2,*,*)=shift((gg(*,ch2,*,*)),0,0,round(ax/2),0)


if keyword_set(cpdelay) then begin
    scp=size(cpdelay)
    n=scp(1)
    help,cpdelay
    help,n
    for i=0,n-1 do begin
	help,i
	gg(*,cpdelay(i,0),*,*)=shift((gg(*,cpdelay(i,0),*,*)),0,0,round(-ax/2),0)
	gg(*,cpdelay(i,1),*,*)=shift((gg(*,cpdelay(i,1),*,*)),0,0,round(ax/2),0)

    end
end

return,gg
end
