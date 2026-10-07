function trcorr_exp,delay,n
t=dindgen(n)/n
e=exp(-t/delay)
e=e/total(e,/double)


return,e
end

function trcorr_gauss,n,w
g=shift(gauss1d(n,n/2,w),-n/2)
return,g/total(g,/double)
end
