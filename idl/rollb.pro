



FUNCTION rollb_huber, x, y
	delta=10D
    ; Calculate the difference
    diff = x - y
    

    ; Compute quadratic part (|diff| <= delta)
    quadratic = (diff LE delta) * (0.5 * diff^2)
;	quadratic = diff^2
    ; Compute linear part (|diff| > delta)
   linear = (diff GT delta) * (delta * (abs(diff) - 0.5 * delta))

    ; Sum both contributions
    loss = quadratic+ linear*0.1

    RETURN, total(loss,/double)
END


function rollb, data, rz, rx,niter,zheat=zheat,xheat=xheat,bkz=bkz,bkxy=bkxy
;	if not(keyword_set(xheat)) then xheat=0.01
;	if not(keyword_set(zheat)) then zheat=0.002
	help,xheat
	help,zheat
	s=size(data)
	nz=s(1)
	nx=s(2)
	ny=s(3)

	;seeds
	if not(keyword_set(bkz)) then bkxy=fltarr(nx,ny)+1.
	avg=total(total(data,3),2)/nx/ny
	if not(keyword_set(bkz)) then bkz=median(total(total(data,3),2)/nx/ny,rz)*0.+290.


	bkz3d = rebin(reform(bkz, nz, 1, 1), nz, nx, ny)
	bkxy3d = rebin(reform(bkxy, 1, nx, ny), nz, nx, ny)

	bkg=bkz3d*bkxy3d

;diff=total((double(data-bkg))^2,/double) 
	diff=rollb_huber(data,bkg)

	bktot=total(total(bkg,3),2)/nx/ny
	plot,avg,xst=1,yst=1
	oplot,bktot,color=200
	tvscl,bkxy



	for i=0,niter-1 do begin
	  	; randomize a bit
		bkzn=bkz+zheat*(randomu(seed,nz)-0.5)
		;oplot,bkzn
		bkxyn=bkxy+xheat*(randomu(seed,nx,ny)-0.5)


		bkz3d = rebin(reform(bkzn, nz, 1, 1), nz, nx, ny)
		bkxy3d = rebin(reform(bkxyn, 1, nx, ny), nz, nx, ny)

		bkgn=bkz3d*bkxy3d
		;ndiff=total((double(data-bkgn))^2,/double) 

		ndiff=rollb_huber(data,bkgn)
;		help,ndiff
;		plot,bkxyn(15,*)
		;bktot=total(total(bkgn,2),2)/nx/ny
		;oplot,bktot,color=200

		if ndiff lt diff then begin
			print,'Improving: ',ndiff,i
			bkg=bkgn
			bkz=bkzn
			bkxy=bkxyn
			diff=ndiff
			bktot=total(total(bkgn,3),2)/nx/ny
			plot,avg,xst=1,yst=1
			oplot,bktot,color=200
			tvscl,bkxy
		end

	end

      
	return, bkg
end
