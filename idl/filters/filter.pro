function filter,img,filt,fctr=fctr,proc=proc
;applies filters with parameters in defined sequence to img
;filt is a structure in this context:
;filt.type filter type
;filt.par1 filter parameter1
;filt.par2 filter parameter2
;etc
;filt is always corrected to include enough tags (3pars)
;fctr is a conversion factor of the size, important for filters which do not conserve the size
;fctr_changed signalizes that fctr should be recalculated according to pixels
;proc is a structure that will contain the results of processing


;Catch, theError
;   IF theError NE 0 THEN BEGIN
;	Catch, /CANCEL
;	print,'ERROR: FILTER-->'+actfilt+'<--caused error: ',theError
;	RETURN,img
 ;  ENDIF


if size(filt,/type) ne 8 then begin 
print,"Filter not a defined as a structure"
return,img
end

print,filt.type

fctr_changed=0
fctr=[1D,1D]
imf=reform(img)
n=n_elements(filt.type)
;help,n

nt=n_tags(filt)
if nt eq 1 then begin
    temp={type:filt.type,par1:dblarr(n),par2:dblarr(n),par3:dblarr(n)}
    filt=temp
end
if nt eq 2 then begin
    temp={type:filt.type,par1:filt.par1,par2:dblarr(n),par3:dblarr(n)}
    filt=temp
end
if nt eq 3 then begin
    temp={type:filt.type,par1:filt.par1,par2:filt.par2,par3:dblarr(n)}
    filt=temp
end

    for i=0,n-1 do begin
	
	s=size(imf) ;must be here


	actfilt=filt.type(i)
	case actfilt of
	
	"median": imf=medianfilter(imf,width=(filt.par1(i)>3)<10)
	"badlines":imf=badlines(imf,filt.par1(i))
	"fixline":imf=fixline(imf,filt.par1(i))
	"fixdblline":imf=fixdblline(imf,filt.par1(i))

	"mirror":imf=reverse(imf,1)
	"flip":imf=reverse(imf,2)
	"lineslope":imf=lineslope(imf,filt.par1(i))
	
	"subtrplane":$
	    if filt.par1(i) ne 0. or filt.par2(i) ne 0. then $
		imf=subtrplane(imf,slopex=filt.par1(i),slopey=filt.par2(i)) else imf=subtrplane(imf)

	"subtractshifts":imf=subtractshifts(imf)

	"bkg_twist":imf=bkg_twist(imf)
	
	"smooth":imf=smooth(imf,filt.par1(i)>2,/edge_truncate)

	"leefilt": imf=leefilt(imf,(filt.par1(i)>2))

	"rowsequal":imf=rowsequal(imf,backplane=filt.par1(i),col=filt.par2(i),smth=filt.par3(i))
	
	"planify": if filt.par1(i) ne 0. then imf=planify(imf,filt.par1(i),/xonly) else imf=planify(imf,/xonly)
	
	"center": imf=shift(imf,s(1)/2-filt.par1(i),s(2)/2-filt.par2(i))

	"shift": imf=shift(imf,filt.par1(i),filt.par2(i))
	
	"extremesexcluded":imf=extremesexcluded(imf,crit=filt.par1(i))
	
	"boost": $
	    begin
		imm=boost(imf)
		coef=(filt.par2(i)>0.01)<10.
		imf=(coef*imf+imm)/(1.+coef)
	    end

	"laplace": $
	    begin
		imm=laplacian(imf)
		coef=(filt.par1(i)>0.01)<10.
		imf=(coef*imf+imm)/(1.+coef)
	    end

	
	"flatten": $
	    begin
	    	imm=imf-smooth(imf,(filt.par1(i)>5.)<(min([s(1),s(2)])/4.),/edge_truncate)
		coef=(filt.par2(i)>0.01)<10.
		imf=(coef*imf+imm)/(1.+coef)
	    end

	"dedouble": $
	    begin
		imf=dedouble(imf,filt.par1(i),filt.par2(i),(filt.par3(i)>0.)<1.0,20)
	    end

;	"grid": $
;	    begin
;		ax1=(decomp(filt.par1(i)))
;		ax2=(decomp(filt.par2(i)))
;		ax3=(decomp(filt.par3(i)))
;		x0=real_part(ax1)
;		a1=imaginary(ax2)/10.
;		r1=real_part(ax3)/10.
;		y0=imaginary(ax1)
;		a2=real_part(ax2)/10.
;		r2=imaginary(ax3)/10.
;		print,x0,y0,r1,a1,r2,a2
;		imf=grids(imf,x0,y0,r1,a1,r2,a2,dim=20,/autocol,/center)
;		;imf(where(imm eq 255)>0)=min(imf)
;		
;	    end

	
	"histequal": imf=hist_equal(imf)
	
	"gauss": imf=gaussfilt(imf,filt.par1(i),filt.par2(i))
	
	"ftgauss": imf=ftgauss(imf,filt.par1(i),filt.par2(i),filt.par3(i))
	
	"invert":imf=(-imf)

	"rebin":begin
			rb1=round( (filt.par1(i)<(1600./s(1))) > 1 )

			if filt.par2(i) ne 0 then begin
				rb2=round( (filt.par2(i)<(1600./s(2))) > 1 )
			end else rb2=rb1
			imf=rebin(imf,rb1*s(1),rb2*s(2),/sample) 
		end
	"bindown":begin
			rb1=round( (filt.par1(i)<(s(1)/8)) > 1 )

			if (s(1)/rb1)*rb1 eq s(1) then $
				imf=bindown(imf,rb1) 
		end
	
	"zoom": begin
		
		if filt.par3(i) gt 0 then begin
		    if filt.par3(i) eq 1 then begin
			print,'x-rules'
			imf=zooom(imf,filt.par1(i),/xsize)
		    end $
		    else $
		    begin
			print,'y-rules'
			imf=zooom(imf,filt.par1(i),/ysize) 
		    end
		end $
		else $
		begin
		    print,'normalzoom'
		    if filt.par2(i) ne 0 then imf=zooom(imf,[filt.par1(i),filt.par2(i)]) else imf=zooom(imf,filt.par1(i))
		end
		
		end
	
	"histxpand": if filt.par2(i) ne 0. then imf=histxpand(imf,limits=[filt.par1(i),filt.par2(i)],percentil=(filt.par3(i) eq 2),absolute=(filt.par3(i) eq 1)) else imf=histxpand(imf)

;filters that do not conserve physical dimensions

	"rotate": $
	    begin
		imf=rotate(imf,filt.par1(i))
		fctr_changed=1
	    end

	"transpose": $
	    begin
		imf=transpose(imf)
		fctr_changed=1
	    end

	"rot": $
	    begin
		imf=rot(imf,filt.par1(i),cubic=-0.5,missing=imf(0))
		fctr_changed=1
	    end

	"crop": $
	    begin
		imf=crop(imf,filt.par1(i),filt.par2(i),filt.par3(i))
		fctr_changed=1
	    end
	
	"recrop": $
	    begin
		if filt.par3(i) lt 1. then $
		
		imf=cropx(imf,filt.par1(i),filt.par2(i),/comp,/swap) $
		    else $
			imf=cropx(imf,filt.par1(i),filt.par2(i),filt.par3(i),/swap)
		
		fctr_changed=1
	    end
	    
	"cropx": $
	    begin
		if filt.par3(i) lt 1. then $
		
		imf=cropx(imf,filt.par1(i),filt.par2(i),/comp) $
		    else $
			imf=cropx(imf,filt.par1(i),filt.par2(i),filt.par3(i))
		
		fctr_changed=1
	    end
	
	"drift": $
	    begin
		print,'removing drift (111)'
		if filt.par3(i) gt 0. then begin
		    ax1=decomp(filt.par1(i))
		    ax2=decomp(filt.par2(i))
		    ax3=decomp(filt.par3(i))
		    
		    ;need to sort the points
		    arrr=[ax1,ax2,ax3]
		    arreal=real_part([arrr])
		    arimg=imaginary([arrr])
		    
		    
		    arrr=arrr(sort(arreal))
		    ;print,"indices:",sort(arreal)
		    ;print,"sorted:",arrr
		    if arimg[2] le arimg[1] then arrr=arrr([0,2,1]) ;else print,'not switching 2nd and 3rd'

		    points=[arrr(1)-arrr(0),arrr(2)-arrr(0)]
		    ;print,ax1,ax2,ax3
		    ;print,points
		    imf=unidrift(imf,points=points,/recut)
		end $
		else $
		begin
		    drift=[filt.par1(i),filt.par2(i)]
		    imf=unidrift(imf,drift=drift,/recut)
		end
		fctr_changed=1
	    end

	"driftfcc110": $
	    begin
		print,'removing drift (110)'
		if filt.par3(i) gt 0. then begin
		    ax1=decomp(filt.par1(i))
		    ax2=decomp(filt.par2(i))
		    ax3=decomp(filt.par3(i))
		    
		    ;need to sort the points
		    arrr=[ax1,ax2,ax3]
		    arreal=real_part([arrr])
		    arimg=imaginary([arrr])
		    
		    
		    arrr=arrr(sort(arreal))
		    ;print,"indices:",sort(arreal)
		    ;print,"sorted:",arrr
		    if arimg[2] le arimg[1] then arrr=arrr([0,2,1]) ;else print,'not switching 2nd and 3rd'

		    points=[arrr(1)-arrr(0),arrr(2)-arrr(0)]
		    ;print,ax1,ax2,ax3
		    ;print,points
		    r12=2^0.5
		    imf=unidrift(imf,[[1.,0],[0,r12]],points=points,/recut)
		end $
		else $
		begin
		    drift=[filt.par1(i),filt.par2(i)]
		    imf=unidrift(imf,drift=drift,/recut)
		end
		fctr_changed=1
	    end

	"driftfcc100": $
	    begin
		print,'removing drift (100)'
		if filt.par3(i) gt 0. then begin
		    ax1=decomp(filt.par1(i))
		    ax2=decomp(filt.par2(i))
		    ax3=decomp(filt.par3(i))
		    
		    ;need to sort the points
		    arrr=[ax1,ax2,ax3]
		    arreal=real_part([arrr])
		    arimg=imaginary([arrr])
		    
		    
		    arrr=arrr(sort(arreal))
		    ;print,"indices:",sort(arreal)
		    ;print,"sorted:",arrr
		    if arimg[2] le arimg[1] then arrr=arrr([0,2,1]) ;else print,'not switching 2nd and 3rd'

		    points=[arrr(1)-arrr(0),arrr(2)-arrr(0)]
		    ;print,ax1,ax2,ax3
		    ;print,points
		    
		    imf=unidrift(imf,[[1.,0],[0,1.]],points=points,/recut)
		end $
		else $
		begin
		    drift=[filt.par1(i),filt.par2(i)]
		    imf=unidrift(imf,drift=drift,/recut)
		end
		fctr_changed=1
	    end


	    
	"stuff": $
	    begin
		if filt.par3(i) ne 0 then miss=filt.par3(i)
		help,miss
		imf=stuff(imf,filt.par1(i),missing=miss)
		fctr_changed=1
	    end

	"fireball": $
	    begin
		mxrep=999/max([s(1),s(2)]) ;safety
		rep=(filt.par1(i)>1)<mxrep
		imfn=dblarr(s(1)*rep,s(2)*rep)
		for ii=0,rep-1 do for jj=0,rep-1 do begin
			imfn(ii*s(1),jj*s(2))=imf
		end
		imf=imfn
		fctr_changed=1
		
		if filt.par2(i) ne 0. or filt.par3(i) ne 0. then begin
		    drift=[filt.par2(i),filt.par3(i)]*filt.par1(i)
		    imf=unidrift(imf,drift=drift,/recut)
		end
	    end


	"visualft":imf=visualft(imf,filt.par1(i))

	"color":print,'*color*'
	
	"grid":print,'*grid*'
	
	"dots":print,'*dots*'

;special for debugging

	"bug": $
	    begin
		a=intarr(1)
		print,a(2)
	    end
	
	else:print, "Unknown filter: "+filt.type(i)
	endcase
	
;calculate fctr if needed
	if fctr_changed eq 1 then begin 
		ns=size(imf)
		fctr(0)=fctr(0)*ns(1)/s(1)
		fctr(1)=fctr(1)*ns(2)/s(2)
		s=ns
		;print,"filttype ",filt.type(i),i
		;print,"filter fctr ",fctr
		fctr_changed=0
	end
	
    end

return,imf

end

