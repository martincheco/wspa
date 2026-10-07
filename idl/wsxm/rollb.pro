FUNCTION rollb_huber, x, y
    ; Calculate the difference
    delta=0D
    diff = x - y
    abs_diff = ABS(diff)

    ; Compute quadratic part (|diff| <= delta)
    quadratic = (abs_diff LE delta) * (0.5 * diff^2)

    ; Compute linear part (|diff| > delta)
    linear = (abs_diff GT delta) * (delta * (abs_diff - 0.5 * delta))
    
    overshoot = (diff LT -0.) * (delta * (abs_diff - 0.5 * delta))

    ; Sum both contributions
    ;loss = quadratic + linear + overshoot
    loss =  abs_diff^0.5
    RETURN, total(loss,1,/double)
END

function rollb_med,arr
	s=size(arr)
	n=s(1)
	avg=dblarr(n)
	for i=0,n-1 do avg(i)=median(arr(i,*,*))
	return,avg
end


function rollb, data, rz, rx,niter,zheat=zheat,xheat=xheat,bkz=bkz,bkxy=bkxy,vis=vis
	help,xheat
	help,zheat
	s=size(data)
	nz=s(1)
	nx=s(2)
	ny=s(3)
	print,nz,nx,ny
	;seeds
	if not(keyword_set(bkz)) then bkxy=fltarr(nx,ny)+1.
	avgm=rollb_med(data) 
	avg=total(total(data,3,/double),2,/double)/nx/ny
	if not(keyword_set(bkz)) then bkz=smooth(roll_bkg(avg,rz),rz,/edge_mirror)
	;f not(keyword_set(bkz)) then bkz=(roll_bkg(avgm,rz))

	bkz3d = rebin(reform(bkz, nz, 1, 1), nz, nx, ny)
	bkxy3d = rebin(reform(bkxy, 1, nx, ny), nz, nx, ny)

	bkg=bkz3d*bkxy3d

	diff=rollb_huber(data,bkg)

	bktot=total(total(bkg,3,/double),2,/double)/nx/ny
	if keyword_set(vis) then begin
		plot,avg,xst=1,yst=1
		;oplot,avgm,color=130
		oplot,bktot,color=200
		tvscl,rebin(bkxy,nx*2,ny*2,/sample)
	end

	bkzn=bkz
	bkxyn=bkxy

	bkz3d = rebin(reform(bkzn, nz, 1, 1), nz, nx, ny)
	bkxy3d = rebin(reform(bkxyn, 1, nx, ny), nz, nx, ny)

	if xheat gt 1E-8 then print,'xheat on'
	if zheat gt 1E-8 then print,'zheat on'

	for i=0,niter-1 do begin
	  	; randomize a bit
		if zheat gt 1E-8 then bkzn=bkz*congrid(1.+zheat*randomn(seed,nz/rz),nz,cubic=-0.5)
		if xheat gt 1E-8 then bkxyn=bkxy*congrid(1.+xheat*randomn(seed,nx/rx,ny/rx),nx,ny,cubic=-0.5)

		if zheat gt 1E-8 then bkz3d = rebin(reform(bkzn, nz, 1, 1), nz, nx, ny)
		if xheat gt 1E-8 then bkxy3d = rebin(reform(bkxyn, 1, nx, ny), nz, nx, ny)

		bkgn=bkz3d*bkxy3d
		ndiff=rollb_huber(data,bkgn)
		
		w=where(ndiff lt diff)

		if w(0) ne -1 then begin
			print,'Improving: ',total(ndiff,/double),i
			bkz=bkzn
			bkxy(w)=bkxyn(w)
			diff(w)=ndiff(w)
			bktot=total(total(bkgn,3,/double),2,/double)/nx/ny
			if keyword_set(vis) then begin
				plot,avg,xst=1,yst=1
				;oplot,avgm,color=130
				oplot,bktot,color=200
				tvscl,rebin(bkxy,nx*2,ny*2,/sample)
			end


		end
;
;		if ndiff lt diff then begin
;			print,'Improving: ',ndiff,i
;			bkg=bkgn
;			bkz=bkzn
;			bkxy=bkxyn
;			diff=ndiff
;			bktot=total(total(bkgn,3),2)/nx/ny
;			if keyword_set(vis) then begin
;				plot,avg,xst=1,yst=1
;				oplot,avgm,color=130
;				oplot,bkz,color=200
;				tvscl,rebin(bkxy,nx*2,ny*2,/sample)
;			end
;		end

	end

      
	return, bkgn
end
