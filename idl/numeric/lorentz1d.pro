function lorentz1d,nx,x,xfwhm


ix=dindgen(nx)-x
f=1./(1.+(ix/xfwhm)^2)

return,f
end
