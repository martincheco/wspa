function phcur_load,mask

g=getfiles(mask=mask+'*.txt')

p2=strpos(g,'mV')

n=n_elements(g)

bias=fltarr(n)

a=loadtxt(g(0))
maps=dblarr(n,a.xsize,a.ysize)

for i=0,n-1 do begin
	a=loadtxt(g(i))
	len=strlen(mask)
	bias(i)=strmid(g(i),len,strpos(g(i),'mV')-len)

	maps(i,*,*)=a.img
end


s=sort(bias)

bias=bias(s)
maps=maps(s,*,*)

return,{v:bias,maps:maps}
end


function phcur_bin_load,mask,xdim,ydim

g=getfiles(mask=mask+'*.bin')

p2=strpos(g,'mV')

n=n_elements(g)

bias=fltarr(n)

maps=dblarr(n,xdim,ydim)

for i=0,n-1 do begin
	openr,1,g(i)
	map=dblarr(xdim,ydim)
	readu,1,map
	close,1
	len=strlen(mask)
	bias(i)=strmid(g(i),len,strpos(g(i),'mV')-len)

	maps(i,*,*)=map
end


s=sort(bias)

bias=bias(s)
maps=maps(s,*,*)

return,{v:bias,maps:maps}
end

pro phcur_export,t,prefix,filt=filt,bicolor=bicolor
;exports as .stp with given prefix and filters
;t - the structure containing biases and maps (3d array)
;prefix - common identifier for the files
;filt - predefined filter same for all
;bicolor - add bipolar color filter according to max and min of the data, putting 0 between the colorscales


s=size(t.maps)
n=s(1)
for i=0,n-1 do begin

	fname=string(i,format='(I03)')+'_'+string(t.v(i),format='(I+04)')+'mV_'+prefix+'.stp'
	filtname=string(i,format='(I03)')+'_'+string(t.v(i),format='(I+04)')+'mV_'+prefix+'.stp.flt'
	filtr=filt

	;fmap=ftgauss(reform(t.maps(i,*,*)),0.2)
	fmap=reform(t.maps(i,*,*))
	if keyword_set(bicolor) then begin

		xx=(fmap(1,1))
		mn=min(fmap)
		mx=max(fmap)
		fact=abs(mn/(mx-mn))
		print,mn,mx,fact,xx
		if fact le 0.02 or fact ge 0.98 then begin
			if abs(mn) gt mx then adfilt='color '+string(bicolor(0))
			if mx gt abs(mn) then adfilt='color '+string(bicolor(1))
		end else $
			if mx gt 0D and mn lt 0D then begin
				adfilt='color '+string(bicolor(0))+' '+string(fact)+' '+string(bicolor(1))
			end
		filtr=filtr+string(10B)
		filtr=filtr+adfilt
end
	print,fname
	slicewsxm,fname,reform(t.maps(i,*,*))
	openw,2,filtname
		printf,2,filtr
	close,2
end


end

pro phcur_vis,t,ind,deriv=deriv

dt=t
if keyword_set(deriv) then begin
	dt.maps=shift(t.maps,-1,0,0)-shift(t.maps,1,0,0)
	dt.maps(0,*,*)=dt.maps(1,*,*)
	dt.maps(-1,*,*)=dt.maps(-2,*,*)
end

x=0
y=0

s=size(dt.maps)

while x lt s(2) and y lt s(3) do begin
	plot,dt.v,dt.maps(*,x,y),xst=1,yst=1,xrange=[-300,400],psym=-3
	if keyword_set(deriv) then tvscl,t.maps(ind,*,*) else tvscl,dt.maps(ind,*,*)
	cursor,x,y,/up,/device
	print,x,y
end


end

