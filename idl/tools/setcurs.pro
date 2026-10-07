pro setcurs

;
;	SET cursor shape and hot spot
;	(added per VSMR 104)
;
curs		= bytarr(16,16)
curs(0,*)	= [0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0]
curs(1,*)	= [1,1,0,0,0,0,0,1,0,0,0,0,0,1,1,0]
curs(2,*)	= [0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0]
curs(3,*)	= [0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0]
curs(4,*)	= [0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0]
curs(5,*)	= [0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0]
curs(6,*)	= [0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0]
curs(7,*)	= [1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,0]
curs(8,*)	= [0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0]
curs(9,*)	= [0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0]
curs(10,*)	= [0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0]
curs(11,*)	= [0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0]
curs(12,*)	= [0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0]
curs(13,*)	= [1,1,0,0,0,0,0,1,0,0,0,0,0,1,1,0]
curs(14,*)	= [0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0]
curs(15,*)	= [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

curs=shift(curs,0,8)
curs=1-curs
cursmask=1-curs

power	= 2^(indgen(16))		; define power of 2 array
cursor	= intarr(16)			; cursor must be integer array
cursormask=cursor
for i = 0, 15 do cursor(i) = total(curs(i,*) * power)
for i = 0, 15 do cursormask(i) = total(cursmask(i,*) * power)



device, cursor_image = cursor, cursor_xy = [7,8],cursor_mask=cursormask
end

