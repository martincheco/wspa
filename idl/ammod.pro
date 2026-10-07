function ammod,sig,cper,rate
;converts signal to freq modulated signal
;sig - the signal to convert

signorm=(sig-min(sig))/(max(sig)-min(sig)) ;normalizing signal

;sigfq=signorm*bw+cfq

newsig=exp(signorm)*(sin(2*!PI*dindgen(n_elements(sig))/cper))


return,newsig


end
