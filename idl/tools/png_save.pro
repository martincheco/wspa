pro png_save, f, img, r=r, g=g, b=b, alpha=alpha,nobtscl=nobtscl
if (not(keyword_set(r)) OR not(keyword_set(g)) OR not(keyword_set(b))) then $
	begin
		print,'Getting colors from the device'
		tvlct,r,g,b,/get
	end

common png_save_pal_cache, prev_r, prev_g, prev_b, cached_er, cached_eg, cached_eb

if n_elements(cached_er) eq 0 or n_elements(prev_r) eq 0 or n_elements(prev_g) eq 0 or n_elements(prev_b) eq 0 then begin
    cached_er = 16.*rebin(float(r), 256*16)
    cached_eg = 16.*rebin(float(g), 256*16)
    cached_eb = 16.*rebin(float(b), 256*16)
    prev_r = r & prev_g = g & prev_b = b
end else if not array_equal(r, prev_r) or not array_equal(g, prev_g) or not array_equal(b, prev_b) then begin
    cached_er = 16.*rebin(float(r), 256*16)
    cached_eg = 16.*rebin(float(g), 256*16)
    cached_eb = 16.*rebin(float(b), 256*16)
    prev_r = r & prev_g = g & prev_b = b
endif
er = cached_er & eg = cached_eg & eb = cached_eb

;print,min(img),max(img)

s=size(img)
if keyword_set(alpha) then begin 
    sa=size(alpha)
    if (total(sa(1:2) eq s(1:2)) ne 2) then aa=0 else aa=byte(alpha)
end

imgf=float(img)

if keyword_set(nobtscl) then imgb=(256.*16.-1.)*imgf/256. else begin
    mn=min(imgf, max=mx)
    rng=mx-mn
    if rng ne 0.0 then scale=(256.*16.-1.)/rng else scale=0.0
    imgb=round( (imgf-mn)*scale )
end

;print,max(imgb),min(imgb)
;help,er
;hack around imagemagick flaw for grayscale images
if array_equal(r,g) and array_equal(g,b) then begin
    ;print,"ACTIVATING GRAYSCALE IMAGEMAGICK HACK!!"
    imga=imgb
    w=where(imga eq mean(imga)) 
    if imga(w(0)) lt 256*16-1 then imga(w(0))=imga(w(0))+1 else imga(w(0))=imga(w(0))-1
    rr=er(imgb)
    gg=eg(imgb)
    bb=eb(imga)
end else $
begin
    rr=er(imgb)
    gg=eg(imgb)
    bb=eb(imgb)
end
;tvscl,rr

;print,min(rr),max(rr)

rrr=reform(rr,s(1),s(2))/16
ggg=reform(gg,s(1),s(2))/16
bbb=reform(bb,s(1),s(2))/16

;print,min(rrr),max(rrr)

if keyword_set(alpha) then imgc=[[[rrr]],[[ggg]],[[bbb]],[[aa]]] else imgc=[[[rrr]],[[ggg]],[[bbb]]]
;help,imgc
imgt=transpose(byte(imgc),[2,0,1])
;help,imgt

common png_save_lib_cache, has_fastpng_lib

libpath = '/var/www/wspa/libfastpng.so'
if n_elements(has_fastpng_lib) eq 0 then has_fastpng_lib = file_test(libpath)
if has_fastpng_lib then begin
    sz_t = size(imgt)
    n_ch = sz_t(1)
    w_px = sz_t(2)
    h_px = sz_t(3)
    imgt_fast = reverse(imgt, 3)
    res = CALL_EXTERNAL(libpath, 'save_png_fast', f, w_px, h_px, imgt_fast, n_ch, VALUE=[1,0,0,0,0])
end else begin
    write_png, f, imgt
endelse

end
