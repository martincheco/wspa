function gauss5,img
;filter that applies gaussian 5x5 kernel

kernel = [$  
[ 1,  8, 15,  8, 1], $  
[ 8, 63,127, 63, 8], $  
[15,127,255,127,15], $  
[ 8, 63,127, 63, 8], $  
[ 1,  8, 15,  8, 1]]  
	         
; and replaced by 0 if there are no valid values  
; within the kernel  

result = CONVOL( img, kernel, /NORMALIZE, /EDGE_ZERO )

return,result

end
		  