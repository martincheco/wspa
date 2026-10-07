pro show3d,stack,ch,xi,yi,zi,xp=xp,gm=gm
;print,xi,yi,zi
if not(keyword_set(gm)) then gm=1.
if keyword_set(xp) then xproj=1 else xproj=0

s=size(stack)
nx=s(3)
ny=s(4)
nz=s(1)
n_ch=n_elements(ch)

tt=bytarr(1,ny+nz)
;help,tt

sq=bytarr(nz,nz)

for i=0,n_ch-1 do begin
    tva=bytscl(reform(stack(zi,ch(i),*,*)),/nan)
    tvb=bytscl(reform(stack(*,ch(i),xi,*)^gm),/nan)
    tvc=bytscl(transpose(reform(stack(*,ch(i),*,yi)^gm)),/nan)

;    help,tva
;    help,tvb
;    help,tvc

    tva(xi,*)=200
    tva(*,yi)=200
    tvc(xi,*)=200
    tvc(*,zi)=200
    tvb(*,yi)=200
    tvb(zi,*)=200

;    tv,tva,i*(nx+nz),0
;    tv,tvb,nx+i*(nx+nz),0
;    tv,tvc,i*(nx+nz),ny

;tt=[tt,[[tvc],[tva]],[[sq],[tvb]]]

a=[[tva],[tvc]]
if xproj then b=[[tvb],[sq]]

if xproj then tt=[tt,a,b] else tt=[tt,a]



end

tv,tt

end


pro viewstack,ostack,ch,xx=xx,yx=yx,zx=zx,norm=norm,zdist=zdist,rott=rott,zgraph=zgraph,zgralt=zgralt,d=d,sav=sav,xp=xp,img=img,smth=smth,gm=gm
;keywords are expansion factors

wtime=0.2
s=size(ostack)
if s(0) eq 3 then begin
    stack=reform(ostack,s(1),1,s(2),s(3)) 
    ch=[0]
    s=size(stack)
end else stack=ostack

nx=s(3)
ny=s(4)
nz=s(1)
n_ch=n_elements(ch)

if not(keyword_set(zdist)) then zdist=findgen(nz)
if not(keyword_set(d)) then d=0
if not(keyword_set(gm)) then gm=1.

nstack=stack

mxs=float(max([nx,ny]))
print,mxs
if keyword_set(xx) then (xx=(xx)>0<10) else xx=(mxs<800.)/mxs
if keyword_set(yx) then (yx=(yx)>0<10) else yx=xx
if keyword_set(zx) then (zx=(zx)>0<10) else zx=(mxs*xx/4/nz)
print,xx,yx,zx

if xx ne 1 or yx ne 1 or zx ne 1 then begin
    nstack=dblarr(nz*zx,s(2),nx*xx,ny*yx)
end

tstack=stack

print,zdist(0:10),zdist(-10:-1)

ek=zdist

for bz=0,n_ch-1 do begin
    if keyword_set(norm) then $
	for k=0,nz-1 do tstack(k,ch(bz),*,*)=bytscl(stack(k,ch(bz),*,*),/nan)

    if keyword_set(rott) then $
	for k=0,nz-1 do tstack(k,ch(bz),*,*)=rot(reform(stack(k,ch(bz),*,*)),rott,cubic=-0.5,missing=0/0)

    if xx ne 1 or yx ne 1 or zx ne 1 then begin
	;nstack(*,ch(bz),*,*)=congrid(reform(tstack(*,ch(bz),*,*)),nz*zx,nx*xx,ny*yx,missing=0/0,cubic=-0.5)
	help,nz
	help,zx
	if zx ge 1 then nstack(*,ch(bz),*,*)=rebin(reform(tstack(*,ch(bz),*,*)),nz*zx,nx*xx,ny*yx,/sample) else nstack(*,ch(bz),*,*)=congrid(reform(tstack(*,ch(bz),*,*)),nz*zx,nx*xx,ny*yx)
	ek=congrid(reform(zdist),nz*zx)
    end $
    else $
    begin
	nstack(*,ch(bz),*,*)=tstack(*,ch(bz),*,*)
    end

end

help,ek
print,ek(0:10),ek(-10:-1)

s=size(nstack)
nx=s(3)
ny=s(4)
nz=s(1)

help,nx
help,ny
help,nz

if keyword_set(zgraph) then begin
	window,2,xs=1200,ys=400
	mng=min(nstack(*,(zgraph-1)>0,*,*),/nan)
	mxg=max(nstack(*,(zgraph-1)>0,*,*),/nan)
end
print,'opening window'

xs=n_ch*(nx+nz)
ys=ny+nz
help,xs
help,ys
window,1,xs=n_ch*(nx+nz),ys=ny+nz,title='Stack view',xpos=0,ypos=ny+nz
print,'opened window'

x=0
y=0

;goldpalette,/pure
plots,[nx+1,nx+nz-1],[ny+1,ny+nz-1],psym=-3,/device,color=128
plots,[nx+1,nx+nz-1],[ny+nz-1,ny+1],psym=-3,/device,color=128

xi=nx/2
yi=ny/2
zi=nz/2


show3d,nstack,ch,xi,yi,zi,xp=xp,gm=gm
xyouts,1,1,"Z = "+string(ek(zi))+"",/device,charsize=1.5

repeat begin
x=0
y=0
xd=0
yd=0

repeat begin
if (x lt nx) or (y lt ny) then cursor,x,y,/up,/device
term=0
;wait,0.01
    ;print,!mouse.button




    if (x lt nx) and (y lt ny) then begin
	repeat begin
	  cursor,x,y,/change,/device
	  
	  if !mouse.button eq 1 then begin
		  term=1
	  	  wait,wtime
	  end
	  if x ne xd or y ne yd then begin
	    xd=x
   	    yd=y
	    xi=(x<(nx-1))>0
	    yi=(y<(ny-1))>0
	    show3d,nstack,ch,xi,yi,zi,xp=xp,gm=gm
	    if keyword_set(zgraph) then begin
		wset,2
;		nd=newdata((xi-d)>0:(xi+d)<(nx-1),(yi-d)>0:(yi+d)<(ny-1),*)
;		nzg=double(n_elements(nd)/nz)
;		zg=total(total(nd,1),1)/nzg
		nd=nstack(*,(zgraph-1)>0,(xi-d)>0:(xi+d)<(nx-1),(yi-d)>0:(yi+d)<(ny-1))
		nzg=double(n_elements(nd)/nz)
		if (d eq 0) then $
		    zg=reform(nd) $
		    else zg=reform(total(total(nd,4),3))/nzg


;		zg=reform(nstack(*,(zgraph-1)>0,xi,yi))
		if zgraph gt 0 then plot,ek,zg,background=255,color=0,yst=1,xst=1;,yrange=[mng,mxg]
		plots,[ek[zi],ek[zi]],[min(zg),max(zg)],/data,color=150
		if keyword_set(zgralt) then oplot,ek,reform(nstack(*,zgralt-1,xi,yi)),color=128
	    	xyouts,1,1,"Z = "+string(ek(zi))+"",/device,charsize=1.5,color=0
		wset,1
	    end
	    xyouts,1,1,"Z = "+string(ek(zi))+"",/device,charsize=1.
	    xyouts,1,11,"X = "+string((xi/xx))+"",/device,charsize=1.
	    xyouts,1,21,"Y = "+string((yi/yx))+"",/device,charsize=1.
	  end
	
	end until !mouse.button eq 1 or term eq 1
    end

    if (x lt nx) and (y gt ny) then begin
	repeat begin
	  cursor,x,y,/change,/device
	  if !mouse.button eq 1 then begin
		  term=1
		  wait,wtime
	  end
	  
	  

	  if x ne xd or y ne yd then begin
	    xd=x
   	    yd=y
	    zi=((y-ny)<(nz-1))>0
	    xi=(x<(nx-1))>0
	    show3d,nstack,ch,xi,yi,zi,xp=xp,gm=gm
	    xyouts,1,1,"Z = "+string(ek(zi))+"",/device,charsize=1
	    xyouts,1,11,"X = "+string((xi/xx))+"",/device,charsize=1
	    xyouts,1,21,"Y = "+string((yi/yx))+"",/device,charsize=1
	 
	    if keyword_set(zgraph) then begin
		wset,2
;		nd=newdata((xi-d)>0:(xi+d)<(nx-1),(yi-d)>0:(yi+d)<(ny-1),*)
;		nzg=double(n_elements(nd)/nz)
;		zg=total(total(nd,1),1)/nzg
		nd=nstack(*,(zgraph-1)>0,(xi-d)>0:(xi+d)<(nx-1),(yi-d)>0:(yi+d)<(ny-1))
		nzg=double(n_elements(nd)/nz)
		if (d eq 0) then $
		    zg=reform(nd) $
		    else zg=reform(total(total(nd,4),3))/nzg


;		zg=reform(nstack(*,(zgraph-1)>0,xi,yi))
		if zgraph gt 0 then plot,ek,zg,background=255,color=0,yst=1,xst=1;,yrange=[mng,mxg]
		plots,[ek[zi],ek[zi]],[min(zg),max(zg)],/data,color=150
		if keyword_set(zgralt) then oplot,ek,reform(nstack(*,zgralt-1,xi,yi)),color=128
	    	xyouts,1,1,"Z = "+string(ek(zi))+"",/device,charsize=1.5,color=0
		wset,1
	    end
	
	  end
	end until !mouse.button eq 1 or term eq 1
    end

    if (x gt nx) and (y lt ny) then begin
	repeat begin
	  cursor,x,y,/change,/device
	  if !mouse.button eq 1 then begin 
		  term=1
		  wait,wtime
	  end



	  if x ne xd or y ne yd then begin
	    xd=x
   	    yd=y
	    zi=((x-nx)<(nz-1))>0
	    yi=(y<(ny-1))>0
	    show3d,nstack,ch,xi,yi,zi,xp=xp,gm=gm
	    xyouts,1,1,"Z = "+string(ek(zi))+"",/device,charsize=1
	    xyouts,1,11,"X = "+string((xi/xx))+"",/device,charsize=1
	    xyouts,1,21,"Y = "+string((yi/yx))+"",/device,charsize=1

  
	    if keyword_set(zgraph) then begin
		wset,2
;		nd=newdata((xi-d)>0:(xi+d)<(nx-1),(yi-d)>0:(yi+d)<(ny-1),*)
;		nzg=double(n_elements(nd)/nz)
;		zg=total(total(nd,1),1)/nzg
		nd=nstack(*,(zgraph-1)>0,(xi-d)>0:(xi+d)<(nx-1),(yi-d)>0:(yi+d)<(ny-1))
		nzg=double(n_elements(nd)/nz)
		if (d eq 0) then $
		    zg=reform(nd) $
		    else zg=reform(total(total(nd,4),3))/nzg


;		zg=reform(nstack(*,(zgraph-1)>0,xi,yi))
		if zgraph gt 0 then plot,ek,zg,background=255,color=0,yst=1,xst=1;,yrange=[mng,mxg]
		plots,[ek[zi],ek[zi]],[min(zg),max(zg)],/data,color=150
		if keyword_set(zgralt) then oplot,ek,reform(nstack(*,zgralt-1,xi,yi)),color=128
	    	xyouts,1,1,"Z = "+string(ek(zi))+"",/device,charsize=1.5,color=0
		wset,1
	    end
	




	  end
	end until !mouse.button eq 1 or term eq 1
    end

;if (x lt nx) or (y lt ny) then cursor,x,y,/up,/device

end until (x gt nx) and (y gt ny)

if keyword_set(sav) and (x-nx lt nz/2) and (y-ny) lt nz/2 then begin
    print,"Saving Z-curves"
    sx=strtrim(string(xi),2)
    sy=strtrim(string(yi),2)
    zg=dblarr(n_ch,nz)
    help,nz

    for bz=0,n_ch-1 do begin
		nd=nstack(*,ch(bz),(xi-d)>0:(xi+d)<(nx-1),(yi-d)>0:(yi+d)<(ny-1))
		nzg=double(n_elements(nd)/nz)
		if (d eq 0) then $
		    zg(bz,*)=nd $
		    else zg(bz,*)=reform(total(total(nd,4),3))/nzg
    end
    ;write z-spectroscopy to file
    openw,1,sav+"/STS_"+sx+"_"+sy+".dat"
    for lm=0,nz-1 do printf,1,ek(lm),zg(*,lm)
    close,1
    a=tvrd(0,true=1)
    write_png,sav+"/STS_"+sx+"_"+sy+".png",reverse(a,3)


end
print,"Finished2"

end until ((x-nx) gt nz/2) and ((y-ny) gt nz/2)

;elp,nstack
;elp,zdist
buf=bytarr(nz,n_ch,nx,ny)

if keyword_set(img) and keyword_set(sav) then begin
    for i=0,n_ch-1 do $
	        if keyword_set(norm) then for j=0,nz-1 do buf(j,i,*,*)=bytscl(reform(nstack(j,ch(i),*,*))) $
	else begin
		print,'normalizing entire channel'
		buf(*,i,*,*)=bytscl(nstack(*,ch(i),*,*))
	end


    for j=0,nz-1 do begin
	rj=nz-j-1
	zhi=strtrim(string(ek(rj),format='(F06.2)'),2)

	a=reform(buf(rj,0,*,*))
	
	as=size(a) ;removing the borders
	tv,a
;help,a
	png_save,sav+"/z"+zhi+".png",a,/nobtscl
    end
end

end

function process_all,dir=dir,oversample=oversample,rmdelay=rmdelay,fold=fold,rmshift=rmshift,chan=chan,base=base,reg=reg,shfts=shfts,hdsft=hdsft,cpdelay=cpdelay
if keyword_set(dir) then t=mloadwsxm(getfiles(dir)) else t=mloadwsxm(mask='*.sxm')
print,'Making stack..
tt=tostack(t)
print,'Upsampling..'
if keyword_set(oversample) then tt=stackzoom(tt,abs(oversample))
s=size(tt)
help,tt
if not(keyword_set(chan)) then chan=2
if not(keyword_set(base_i)) then base_i=s(1)/4

if keyword_set(rmshift) then r=rmshift(tt,base_i=base_i,chan=chan,/stuff,reg=reg,shfts=shfts,hdsft=hdsft) else r=tt
if keyword_set(rmdelay) then if rmdelay gt 1 then r=rmdelay(r,rmdelay,rmdelay+1,reg=reg,/stuff,cpdelay=cpdelay) else r=rmdelay(r,4,5,/stuff,reg=reg,cpdelay=cpdelay)


if keyword_set(fold) then r=stackfold(r)
;r=tt
if keyword_set(oversample) then if oversample lt 0 then begin
    print,'Downsampling..'
    r=stackzoom(r,1./abs(oversample))
end

return,r
end
