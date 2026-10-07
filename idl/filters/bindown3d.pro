function bindown3d,img,a
;reduces the size of a 3d array in the first two coords, factor must be an integer factor of its size
s=size(img)

nx=round(s(1)/a)
ny=round(s(2)/a)

;imf=intarr(nx,ny,s(3))*img(0)

;xi=indgen(nx)*a
;yi=indgen(ny)*a

imf = REFORM(img, a, nx, a, ny, s(3))

imf = TOTAL(TOTAL(imf, 1), 2) / (a * a)


return,imf
end
