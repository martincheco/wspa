pro sts2wav,f,fold=fold

for i=0,n_elements(f)-1 do begin

    a=loadnanonis_sts(f(i))
    sig1=reform(a.data(1,*))
    if keyword_set(fold) then begin 
	sig2=reform(a.data(2,*))
	sig=[sig1,reverse(sig2)]
    end else sig=sig1




;    signorm=fix(32000*(sig-min(sig))/(max(sig)-min(sig)))
signorm=ammod(sig,40)

    write_wav,f(i)+".wav",fix(32000*signorm),20000

end

end







