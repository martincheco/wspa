function histxpand,img,limits=limits,absolute=absolute,percentile=percentile
;stretches the histogram
;limits - the transfer limits in percent (0.0-1.0)
;if not set, it is calculated automatically 
;tries to conserve the z-scaling
;but histogram works on scale of 256
;invert allows to pass the outer intervals and joins them
;absolute sets the range by values, not by percentage between min and max

imf=float(img)
mn=min(img)
mx=max(img)

IF not(finite(mn)) or not(finite(mx)) THEN return,img
IF mn eq mx then return,img

if not(keyword_set(limits)) then begin
;    h=histogram(img(where(img ne 0)),min=mn,max=mx,binsize=(mx-mn)/255.)
    h=histogram(img,min=mn,max=mx,binsize=(mx-mn)/256.)
;    help,h
    pts=where(h gt max(h)*0.02)
    llim=min(pts)*(mx-mn)/255.+mn ; the limits
    hlim=max(pts)*(mx-mn)/255.+mn
;    print,hlim,llim
end else begin
;    print,"Using limits:",limits(0),limits(1)
    if keyword_set(absolute) then begin
;	print,'absolute scale'
	llim=limits(0)
	hlim=limits(1)
    end else begin
	;print,'here'
	if keyword_set(percentile) then begin
;	    print,'percentiles'
	    h=histogram(img,min=mn,max=mx,binsize=(mx-mn)/256.)
	    hi=h
;	    help,h
	    for k=1,255 do hi(k)=hi(k-1)+h(k)
	    llimw=(where(hi le max(hi)*limits(0))>0)<255
	    hlimw=(where(hi ge max(hi)*limits(1))>0)<255
	    ;print,llimw
	    ;print,hlimw
	    llim=llimw(0)*(mx-mn)/255.+mn
	    hlim=hlimw(0)*(mx-mn)/255.+mn
	end else begin
;	    print,'relative limits'
	    llim=limits(0)*(mx-mn)+mn
	    hlim=limits(1)*(mx-mn)+mn
	end
    end

end

;help,mn
;help,mx
;help,llim
;help,hlim

imf=(imf>llim)<hlim

if keyword_set(absolute) then begin
    if llim lt mn then imf(0)=llim
    if hlim gt mx then imf(1)=hlim
end

return,imf
end