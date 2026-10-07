FUNCTION roll_bkg, data, radius
  n = N_ELEMENTS(data)
  background = DBLARR(n)
  x = DINDGEN(n)

  ; Square radius for convenience
  rad2 = radius^2

  FOR i = 0, n-1 DO BEGIN
    ymin = data[i]

    ; Check all points within radius
    idx1 = MAX([0, i - radius])
    idx2 = MIN([n - 1, i + radius])

    FOR j = idx1, idx2 DO BEGIN
      dx2 = (x[i] - x[j])^2
      IF dx2 LE rad2 THEN BEGIN
        yball = data[j] - SQRT(rad2 - dx2)
        ymin = MIN([ymin, yball])
      ENDIF
    ENDFOR

    background[i] = ymin
  ENDFOR

  RETURN, background+radius
END


FUNCTION roll_bkg_3d, data, rz,wid,smth=smth
  sz = SIZE(data, /DIMENSIONS)
  nx = sz[0]
  ny = sz[1]
  nz = sz[2]
  sdata=data

	if not(keyword_set(smth)) then smth=1 else smth=rz

  for k=0,nz-1 do sdata(*,*,k)=smooth(reform(data(*,*,k)),wid,/edge_truncate)
  background = DBLARR(nx, ny, nz)

  FOR i = 0, nx - 1 DO BEGIN

    FOR j = 0, ny - 1 DO BEGIN
	print,i,j
        background[i, j, *] = smooth(roll_bkg(sdata(i,j,*),rz),smth,/edge_truncate)
    ENDFOR
    tot=reform(total(background,3))
    tvscl,tot(0:i,*)

  ENDFOR

  RETURN, background  ; Since we're using normalized ball radius = 1
END


