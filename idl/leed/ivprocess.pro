function read_iv,f
chunk=read_ascii(f,data_start=1)
ch=chunk.(0)
s=size(ch)
print,"iv size",s
y=ch(1:s(1)-1,*)
e=ch(0,*)
return,{e:e,y:y}
end

pro write_iv,f,iv
s=size(iv.y)
openw,lun,f,/get_lun,width=16*(s(1)+1)
for i=0,s(2)-1 do begin
    printf,lun,iv.e(i),iv.y(*,i)
end
free_lun,lun
end

pro plot_iv,iv
;device,decomposed=0
;device,retain=2
;loadct,38
s=size(iv.y)
;window,1,xsize=900,ysize=250,title="LEED IV's"
plot,iv.e,iv.y(0,*),yrange=[0,max(iv.y)],xstyle=1,ystyle=1,background=255,xtitle="Energy [eV]",ytitle="Intensity",color=0,/nodata
	for i=0,s(1)-1 do $
	begin
		oplot,iv.e,iv.y(i,*),color=i*48-20,thick=2
		xyouts,0.9,0.3+float(i)/s(1)/2,"---- "+strtrim(string(i),2),/norm,color=i*48-20
	end
;oplot,iv.e,total(iv.y,1)/s(1),color=0,thick=3
end

function make_divs,iv
mn=min(iv.e)
mx=max(iv.e)
mxy=max(iv.y)
mny=min(iv.y)
orig=[mn,mx]

repeat begin
	cursor,x,y,/up,/data
	if y gt 0 and x gt mn and x lt mx then begin
		orig=[orig,x]
		plots,[x,x],[0,mxy],color=0
	end
endrep until y lt mny or x gt mx or x lt mn
return,orig(sort(orig))
end

pro write_msk,f,t,msk
s=size(msk)
openw,lun,f,/get_lun,width=16*(s(1)+1)
printf,lun,t
printf,lun,msk
free_lun,lun
end

function read_msk,f
mskk=read_ascii(f,data_start=1)
msk=mskk.(0)
return,msk
end

function iv_msk,iv,msk,t
s=size(msk)
print,"mask size: ",s
mskp=iv.y*0
help,mskp
for i=0,s(1)-1 do begin
    print,"i",i
    mn=abs(iv.e - t(i))
    p1=where(mn eq min(mn))
    mn=abs(iv.e - t(i+1))
    p2=where(mn eq min(mn))
    print,p1(0),p2(0)
    if p1(0) ne -1 and p2(0) ne -1 then print,t(i),t(i+1) else print,t(i),t(i+1)
;    help,mskp(0:s(1)-1,p1:p2-1)
;    help,mreplicate((reform(msk(i,0:s(1)-1),s(1))),p2(0)-p1(0))
    mskp(0:s(2)-1,p1:p2-1)=mreplicate((reform(msk(i,0:s(2)-1),s(2))),p2(0)-p1(0))
end

return,mskp
end

pro ivprocess

device,decomposed=0
device,retain=2
loadct,38
window,1,xsize=900,ysize=250,title="LEED IV's"


iv=read_iv(f)
mn=min(iv.e)
mx=max(iv.e)
mxy=max(iv.y)
mny=min(iv.y)


print,f
s=size(iv.y)

print,s
plot_iv,iv
t=make_divs(iv)
fm=f+'.msk'
print,t

msk=intarr(n_elements(t)-1,s(1))+1
help,msk
;write_msk,fm,msk
stat=0
smsk=size(msk)
print,smsk
window,0,xs=smsk(1)*20+50,ys=smsk(2)*20
device,decomposed=0
loadct,38
tv,bytarr(smsk(1)*20+50,smsk(2)*20)+255
x=0

while x lt smsk(1)*20 do begin
;	msk=read_msk(fm)
;	write_msk,fm,byte(msk);to reformat
	mskp=iv_msk(iv,msk,t)
	ivm={e:iv.e,y:iv.y*mskp}
	iva={e:iv.e,y:transpose(total(ivm.y,1)/(total(mskp,1)>1))}
	wset,1
	plot_iv,ivm
	oplot,iva.e,iva.y,psym=1,color=0
	wset,0
	;xdisplayfile,fm,/edit,/modal

	;wha follows is a crazy code, but works
	bmsk=msk
	bmsk=(byte(congrid(byte(msk),smsk(1)*20,smsk(2)*20))<1)>0
	print,min(bmsk),max(bmsk)
	bmsk2=long(bmsk)
	bmsk3=bmsk2
	help,bmsk2
	for j=0,smsk(2)-1 do begin
	    col=j*48-20
	    print,col
	    bmsk3(*,j*20:(j+1)*20-1)=bmsk2(*,j*20:(j+1)*20-1)*col
	    
	end

	print,min(bmsk3),max(bmsk3)

	for j=1,smsk(1)-1 do bmsk3(j*20,*)=0
	for j=1,smsk(2)-1 do bmsk3(*,j*20)=0
	tv,bmsk3
	cursor,x,y,/up,/device
	if x lt smsk(1)*20 then msk(x/20,y/20)=msk(x/20,y/20) eq 0
	print,msk

end

write_msk,fm,t,msk ; just for check
ff=dialog_pickfile(file=f+'.p',filter="*.p*")
write_iv,ff,ivm
fa=ff+'a'
write_iv,fa,iva

end