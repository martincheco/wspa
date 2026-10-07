function divsignal,sig,wdth,plt=plt
;divides the sound signal (in signed bytes or integers) into parts
;w is a value used for averaging and defining the boundaries
;plt plots everything nicely

;prepare an envelope function of the signal
asig=(smooth(abs(sig*1.),wdth,/edge_trunc))
asig=[asig,replicate(asig(0)*0,wdth*4)]
if keyword_Set(plt) then plot,asig

;identify silent regions

w=where(asig lt 0.2)
;print,0.04*max(asig)

;identify continuous regions

if w(0) eq -1 then return,[0,0]

dw=w-shift(w,1)


;oplot,w,dw,color=20000
dwh=where((dw) gt wdth*4)
;help,dwh
;plot,sig
if keyword_Set(plt) then for i=0,n_elements(dwh)-1 do begin
    plots,w((dwh-1)),1,color=255,psym=1
    plots,w((dwh)),1,color=128,psym=4
end

if dwh(0) eq -1 then return,[0,0]

ww=[[w(dwh-1)],[w(dwh)]]

return,transpose(ww)
end

function cutsignal,sig,a,b,wdth
if not(keyword_set(wdth)) then wdth=0
;print,a,b
;print,n_elements(sig)
n=n_elements(sig)-1-wdth
a=(a>wdth)<n
b=(b>(a))<n
;print,a,b
return,sig(a-wdth:b+wdth)
end

pro tones,f,wdth
if not(keyword_set(f)) then f=dialog_pickfile(/must_exist,filter='*.WAV,*.wav')
if f eq "" then return
fbname=file_basename(f,'.WAV',/fold_case)
sig=read_wav(f,rate)
n=n_elements(sig)
if rate eq 44100 then begin
sig=byte(congrid(sig,n/2,cubic=-0.5)/20+129)
rate=rate/2
end
t=divsignal(sig-129,wdth)
s=size(t)
print,s(2)
if s(2) lt 4 then begin
print, fbname+" - NOT even 4!"
return
end


t=t(*,s(2)-4:s(2)-1)

for i=0,3 do $
write_wav,fbname+strtrim(string(i+1),2)+'.wav',cutsignal(sig,t(0,i),t(1,i),wdth),rate

end

pro alltones,wdth
flist=loadlist(dialog_pickfile(/must_exist))
for i=0,n_elements(flist)-1 do tones,flist(i),wdth

end
