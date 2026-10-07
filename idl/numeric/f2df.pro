function Sader2, F, n
; compute convolutuion mask dY
x = 2D*dindgen(n+1)/(n)-1D
Y = sqrt(1-x*x)
dY =  Y[1:*] - Y[0:-1]      
dF = convol(F, dY,/edge_truncate)
 
return, dF/n/0.5
end

function f2df,F,dz=dz,k0=k0,f0=f0,n=n
;calculates df from force, thanks to the properties of 
;convol, works for arrays, where the z direction is the first
;amplitude of oscillation is given here as number of z points 
;over which extends
if not(keyword_set(dz)) then dz=0.05 ;[A]
if not(keyword_set(n)) then n=4 ;a=n*dz
if not(keyword_set(f0)) then f0=1E6 ;[Hz]
if not(keyword_set(k0)) then k0=5E5*2 ;[N/m]
print,'dz',dz
print,'f0',f0
print,'k0',k0
print,'a',dz*n/2.
print,'n',n

df2K = 2.*k0/f0 
dF = 16.0217656  * Sader2(F, n)/df2K/dz      ; to [Hz]
return,dF
end



