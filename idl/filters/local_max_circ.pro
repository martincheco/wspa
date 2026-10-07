function local_max_circ,im,l
lim=im*0.
rng=max(im)-min(im)
;print,rng
n=n_elements(im)
for i=0,n-1 do $
begin
ims=shift(im,n/2-i)
if ims(n/2) gt ((ims(n/2-l)+ims(n/2+l))/2) then lim(i)=float((ims(n/2)-(ims(n/2-l)+ims(n/2+l))/2))

end

llim=lim*0

s=0L
c=0L
sm=0L
for i=0,n-1 do begin

if s eq 1 then $
begin
 if lim(i) eq 0 then $
 begin
  llim(sm/c)=lim(sm/c)
  s=0
  c=0
  sm=0L
 end $
  else $
 begin
  sm=sm+i
  c=c+1 
 end
end $
else $
begin
 if lim(i) ne 0 then $
 begin
  s=1
  sm=sm+i
  c=c+1
 end
end

end

return,llim
end
