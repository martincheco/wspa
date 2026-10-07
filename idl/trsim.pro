function trsim_table,freqs,delays
;freqs contains frequencies
;delays is array with delays of interest

m=n_elements(freqs)
n=n_elements(delays)

result=ptrarr(m,n)


for i=0,m-1 do begin
	for j=0,n-1 do begin
		print,i,j
		t=trsim(freqs(i),delays(j),250D-12,2L^16)
		result(i,j)=ptr_new(t)
	end
end

return,result
end


pro trsim_table_draw,res

s=size(res)

for i=0,s(1)-1 do begin
	t=(*res(i,0))
	plot,t.t*1E12,t.y,background=255,color=0


	for j=0,s(2)-1 do begin
		t=(*res(i,j))
		oplot,t.t*1E12,t.dy2,color=float(j)*255/s(2)/2+80
	end
	t=(*res(i,0))
	oplot,t.t*1E12,t.y,color=0
	
end


end


pro trsim_table_plot_phase,tr,ps=ps
s=size(tr.delay)
print,s

if keyword_set(ps) then begin
	SET_PLOT, 'PS'  
	DEVICE, FILE='phaseplot.ps', /COLOR, BITS=8 
       DEVICE,decomposed=0	
end


plot,tr.delay(0,*)*1E12,tr.phi(0,*),background=255,color=0,xtit='Delay [ps]',ytit='Phase [deg]',charsize=1.2,thick=2.,charthick=4.,xrange=[1E1,1E4],/xlog,yrange=[0,90],/nodata

for j=0,s(1)-1 do begin
	oplot,tr.delay(j,*)*1E12,tr.phi(j,*),color=j*256/16,thick=4
        xyouts,0.025+0.25,0.62+float(j)/25.,string(tr.freq(j,0)/1E6,format='(I4)')+' MHz',/normal,color=j*256/16,charthick=4.
	plots,0.025+[0.2,0.24],[0.63+float(j)/25.,0.63+float(j)/25.],color=j*256/16,thick=4.,/normal
end

plot,tr.delay(0,*)*1E12,tr.phi(0,*),background=255,color=0,xtit='Delay [ps]',ytit='Phase [deg]',charsize=1.2,thick=2.,charthick=4.,xrange=[1E1,1E4],/xlog,yrange=[0,90],/nodata,/noerase
oplot,[1,1E5],[5,5],color=0,linestyle=2,thick=4
oplot,[1,1E5],[60,60],color=0,linestyle=2,thick=4



if keyword_set(ps) then begin
	DEVICE, /CLOSE  
	SET_PLOT, 'X'
end




end


pro trsim_table_plot_atten,tr,ps=ps
s=size(tr.delay)
print,s
if keyword_set(ps) then begin
	SET_PLOT, 'PS'  
	DEVICE, FILE='amplot.ps', /COLOR, BITS=8  
       DEVICE,decomposed=0	
end


plot,tr.delay(0,*)*1E12,tr.atten(0,*)*100,background=255,color=0,xtit='Delay [ps]',ytit='Attenuation [%]',charsize=1.2,thick=4.,charthick=4.,xrange=[1E1,1E4],/xlog,yrange=[0,100],/nodata

for j=0,s(1)-1 do begin
	oplot,tr.delay(j,*)*1E12,100-tr.atten(j,*)*100,color=j*256/16,thick=4
        xyouts,0.025+0.25,0.6+float(j)/25.,string(tr.freq(j,0)/1E6,format='(I4)')+' MHz',/normal,color=j*256/16,charthick=4
	plots,0.025+[0.2,0.24],[0.61+float(j)/25.,0.61+float(j)/25.],color=j*256/16,thick=4,/normal
end

plot,tr.delay(0,*)*1E12,tr.atten(0,*)*100,background=255,color=0,xtit='Delay [ps]',ytit='Attenuation [%]',charsize=1.2,thick=4.,charthick=4.,xrange=[1E1,1E4],/xlog,yrange=[0,100],/nodata,/noerase
oplot,[1,1E5],[50,50],color=0,linestyle=2,thick=4


if keyword_set(ps) then begin
	DEVICE, /CLOSE  
	SET_PLOT, 'X'
end


end



function trsim_table_shifts,res

s=size(res)

delay=dblarr(s(1),s(2))
phase=delay
atten=delay
freq=delay
phi=delay

for i=0,s(1)-1 do begin

	for j=0,s(2)-1 do begin
		t=(*res(i,j))
		delay(i,j)=t.delay
		phase(i,j)=t.phtime
		phi(i,j)=t.ph
		freq(i,j)=t.freq
		atten(i,j)=t.amp2
	end
	
end

return,{delay:delay,phase:phase,atten:atten,freq:freq,phi:phi}
end


function trsim,freq,delay,jitter,n


t=dindgen(n)/n/freq
omega=2.*!PI*freq
y=cos(omega*t)

print,delay*freq

de=exp(-t/delay)
jt=gauss1d(n,n/2,jitter*freq*n)
jt=shift(jt,-n/2)
help,y
help,de
dy=fft(fft(y,-1,/double)*fft(de/total(de,/double),-1,/double),1,/double)*float(n)
dy2=fft(fft(dy,-1,/double)*fft(jt/total(jt,/double),-1,/double),1,/double)*float(n)

w=where(dy eq max(dy))
if w(0) ne -1 then begin
	ph=float(w(0))/float(n)*360.
	phtime=t(w(0))
	amp=dy(w(0))
	amp2=dy2(w(0))

end else begin
	ph=0
	amp=0
	amp2=0
end


phcalc=atan(omega*delay)/!PI*180.
phtimecalc=atan(omega*delay)/2/!PI/freq

help,ph
help,phcalc
help,phtime
help,phtimecalc
;dy=blk_con(de,y,/double)/total(de)

return,{t:t,y:y,de:de,jt:jt,dy:dy,dy2:dy2,amp:amp,amp2:amp2,ph:ph,phcalc:phcalc,phtime:phtime,freq:freq,delay:delay,jitter:jitter}
end
