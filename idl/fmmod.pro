function fmmod,sig,cfq,bw,rate
;converts signal to freq modulated signal
;sig - the signal to convert

n=n_elements(sig)

signorm=(sig-min(sig))/(max(sig)-min(sig))-0.5 ;normalizing signal

sigfq=signorm*bw+cfq

newsig=sin(2*!PI*sigfq*dindgen(n)/rate)


return,newsig


end
