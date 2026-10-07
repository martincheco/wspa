pro png_save_faster, f, img, r=r, g=g, b=b
if (not(keyword_set(r)) OR not(keyword_set(g)) OR not(keyword_set(b))) then $
	begin
		print,'Getting colors from the device'
		tvlct,r,g,b,/get
	end


    imgb=( (256.-1.) * (img-min(img)) / (max(img)-min(img)) )

    rr=r(imgb)
    gg=g(imgb)
    bb=b(imgb)

	s=size(img)
	imgt=bytarr(3,s(1),s(2))
	imgt(0,*,*)=rr
	imgt(1,*,*)=gg
	imgt(2,*,*)=bb

	;write_png,f,imgt
write_png,f,imgt ;new GDL/imagemagick bug, it forces 16-bit pngs


end
