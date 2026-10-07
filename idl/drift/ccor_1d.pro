function ccor_1d,x,y,nan=nan
;print, 'Creating crosscorrelation..'
xt=x
yt=y
if keyword_set(nan) then begin
    w=(where(finite(xt,/nan)))
    if w(0) ne -1 then xt(w)=0
    w=(where(finite(yt,/nan)))
    if w(0) ne -1 then yt(w)=0
end
temp1=fft(xt,-1)
temp2=fft(yt,-1)
res=fft(temp1*CONJ(temp2),-1)
return, res
end
