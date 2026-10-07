function ramanplot_read,f
;f - filename
;export - if set, then will be exported as f.png


if n_elements(f) gt 1 then begin
	n=n_elements(f)
	;for stitching
	t=loadnanonis_sts(f(0))
	tt=t.data

	wnm=where(t.chans eq 'Wavelength (nm)')
	wcnt=where(t.chans eq 'Counts')
	help,wnm,wcnt
	print,wcnt
	print,wnm

	x=tt(wnm(0),*)
	y=tt(wcnt(0),*)


	xx=dblarr(n_elements(x),n)
	yy=xx
	xx(*,0)=x
	yy(*,0)=y

	for i=1,n-1 do begin
		t=loadnanonis_sts(f(0))
		tt=t.(0)

		wnm=where(t.chans eq 'Wavelength (nm)')
		wcnt=where(t.chans eq 'Counts')
		help,wnm,wcnt

		x=tt(wnm(0),*)
		y=tt(wcnt(0),*)

		xx(*,i)=x
		yy(*,i)=y
	end

end else begin

	t=loadnanonis_sts(f)
	tt=t.data

	wnm=where(t.chans eq 'Wavelength (nm)')
	wcnt=where(t.chans eq 'Counts')
	help,wnm,wcnt
	print,wnm,wcnt
	xx=tt(wnm(0),*)
	yy=tt(wcnt(0),*)


end

return,{xw:xx,x:1E7/xx,y:yy,f:f}
end

;function ramanplot_stitch,dt



;return,{xw:xx,x:1E7/xx,y:yy}
;end



