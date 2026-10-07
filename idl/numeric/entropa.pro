function entropa, arrayin

;--------------------------------------------------------------------

; Modified from the procedure to return the entropy value

; Calculates the line-by-line image entropy of the image stored in 
; 'arrayin'. Prints the entropy value to screen.  If the array is of 
; integer type, a 12 bit image is assumed.  If it is of byte type,
; an 8 bit image is assumed.

; Usage: entropy_value = entropy(image_array)

; David O'Brien, 5/30/97 -- problem fixed 8/1/97

;---------------------------------------------------------------------

; Get array dimensions and type

dimensions = size(arrayin)
xsize = dimensions(1)
ysize = dimensions(2)
;type = dimensions(3)
type=1

; Fix array to integer type

;array = fix(arrayin)
tvscl,arrayin
print,max(arrayin)-min(arrayin)
array=bytscl(arrayin)
array=fix(array)

; Find correct size for probability array and create it

if type eq 1 then array_size = 256*2-1
if type eq 2 then array_size = 4096*2-1 
if (type ne 1) and (type ne 2) then print, 'Not a byte or integer array'

prob_array = fltarr(array_size)

; Loop over image array elements and count occurences of each possible
; pixel to pixel difference value.  Store these values in prob_array

for j = 0, ysize-1 do $

	for i = 0, xsize-2 do begin

		diff = array(i+1,j) - array(i,j)

		if diff lt (array_size+1)/2 and diff gt -(array_size+1)/2 then begin

			prob_array(diff+(array_size-1)/2) = prob_array(diff+(array_size-1)/2) + 1
		
		endif
		
	endfor

; Convert values in prob_array to probabilities and compute entropy

n = total(prob_array)

entrop = 0

for i = 0, array_size-1 do begin 

	prob_array(i) = prob_array(i)/n

	; Base 2 log of x is Ln(x)/Ln(2).  Take Ln of array element
	; here and divide final sum by Ln(2)	

	if prob_array(i) ne 0 then begin
	
		entrop = entrop - prob_array(i)*alog(prob_array(i))

	endif

endfor

entrop = entrop/alog(2)

return, entrop

end	 
