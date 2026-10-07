function ftkill,img,x,y,r,center=center
;keyword center says that the coordinates are derived from a shifted fft
s=size(reform(img))

ftraw=fft(img,-1)
if keyword_set(center) then begin
	ftraw=shift(ftraw,s(1)/2,s(2)/2)
end

ftraw(x,y)=max(ftraw);median(ftraw((x-r)>0:(x+r)<(s(1)-1),(y-r)>0:(y+r)<(s(1)-1)))
ftraw(s(1)-x,s(2)-1-y)=ftraw(x,y)

if keyword_set(center) then begin
	ftraw=shift(ftraw,-s(1)/2,-s(2)/2)
end

return,real_part(fft(ftraw,1))

end 
