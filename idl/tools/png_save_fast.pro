pro png_save_fast, f, img, r=r, g=g, b=b
if (not(keyword_set(r)) OR not(keyword_set(g)) OR not(keyword_set(b))) then $
	begin
		print,'Getting colors from the device'
		tvlct,r,g,b,/get
	end


    imgb=( (256.-1.) * (img-min(img)) / (max(img)-min(img)) )

	er=r*256
	eg=g*256
	eb=b*256
    rr=er(imgb)
    gg=eg(imgb)
    bb=eb(imgb)

	s=size(img)
	imgt=uintarr(3,s(1),s(2))
	imgt(0,*,*)=rr
	imgt(1,*,*)=gg
	imgt(2,*,*)=bb

	;write_png,f,imgt
write_png,f,imgt ;new GDL/imagemagick bug, it forces 16-bit pngs


end
