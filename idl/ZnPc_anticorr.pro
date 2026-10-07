pro ZnPc_anticorr,ps=ps


ff=getfiles(mask='*_645-*.sxm')
frst=0

ff=ff([1,2,6,7])

A = FINDGEN(17) * (!PI*2/16.)
; Define the symbol to be a unit circle with 16 points, 
; and set the filled flag:
USERSYM, COS(A), SIN(A), /FILL


if keyword_set(ps) then begin
	print,'will draw into ps file'
        SET_PLOT, 'PS' 
        DEVICE, FILE=ps+'.ps', /COLOR, BITS=8,xsize=15,ysize=15
       DEVICE,decomposed=0
end


cc=0
ii=0

for i=0,n_elements(ff)-1 do begin
	aa=loadnanonis(ff(i))
	a=aa.img
	x1=float(reform(a(*,*,4)))
	x1=x1-min(x1)
	x2=float(reform(a(*,*,8)))
	x2=x2-min(x2)
;	c=x1*x2
;	mx=max(c)
;	print,mx
	c=((x1/max(x1))+(x2/max(x2)))/2.
	it=float(reform(a(*,*,2)))
;	c=c/max(c)
if frst lt 1 then begin 
		plot,[0,1],[0,1],/nodata,yst=1,xst=1,background=255,color=0,xtitle='X intensity norm.',ytitle='X+ intensity norm.',charthick=5.0,thick=4.0
		frst=10
	end
;		plot,[0,1],[0,1],/nodata,yst=1,xst=1
	for j=0,n_elements(x1)-1 do begin

		plots,x1(j)/max(x1),x2(j)/max(x2),color=((256-255*c(j))>0)<255,psym=8,/data,symsize=0.5

	end

if n_elements(cc) ne 1 then cc=[cc,bytscl(c)] else cc=bytscl(c)
if n_elements(ii) ne 1 then ii=[ii,bytscl(it)] else ii=bytscl(it)

end

		plot,[0,1],[0,1],/nodata,yst=1,xst=1,color=0,/noerase

		help,cc
		help,ii
;		tvscl,[[cc],[ii]]

if keyword_set(ps) then begin

	DEVICE,/close
	SET_PLOT,'X'
end

end
