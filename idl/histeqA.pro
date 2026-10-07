function histeqA,imgx,wx
sx=size(imgx)
;print,min(imgx),max(imgx)
;imgx=imgx-min(imgx)+1
print,min(imgx),max(imgx)
nimgx=imgx
for ix=wx+1,sx(1)-wx-1 do $
for jx=wx+1,sx(2)-wx-1 do begin
if jx eq wx+1 then print,ix
px=histogram(nimgx(ix-wx:ix+wx,jx-wx:jx+wx))
for kx=1,n_elements(px)-1 do px(kx)=px(kx)+px(kx-1) ;integrate

imgx(ix,jx)=px(nimgx(ix,jx))
endfor
return,imgx
end
