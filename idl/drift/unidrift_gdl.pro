function unidrift_gdl,imf,matrix,drift=drift,target_self=target_self,points=points
;removes drift by asking the user for the axes and uses the X axis as the most reliable
;imf - the image
;matrix - the periodicity vectors
;n - expansion of the canvas; max. expansion 2x
;orient - the angle between the first vector and the X axis in degrees in the result, if not set, no correction done
;the same could be achieved with warp_tri though
;if drift is set, wps is calculated and then warped directly, if the variable is empty, returns the right values
;recut removes automatically empty spacing around
;target_self uses an already created window (if its badly sized, maybe does not matter)
;points skip the interaction

if not(keyword_set(n)) then n=2.

n=n<2.0


im=imf ;make a copy
s=size(im)

r3=3.^0.5/2.

if not(keyword_set(matrix)) then begin
;print,"No matrix given, using the hexagonal symmetry"
matrix=[[r3,0.5],[r3,-0.5]]
end


if not(keyword_set(drift)) or n_elements(drift) ne 2 then begin 
    ;vectors: real part x, imaginary is y, have to be one above the X axis, second below; otherwise you get nonsense
    if keyword_set(points) then y=points else y=userpoints(im,target_self=target_self)
    y=repair_points(y)
    ;print,y

    ;define the correct vectors, needs to be calculated
    yi=inventpoints(y,matrix)
end




gx=[0.,s(1)*n,0.,s(1)*n]
gy=[0.,0.,s(2)*n,s(2)*n]

if (keyword_set(drift)) then $
    begin
	;print,"drift set"
    end $
    else $
    begin
	ggg=ttrans(y,yi,gx,gy)
	;returns the coordinates of the new image corners
	gix=float(ggg)
	giy=float(imaginary(ggg))
	drift=[gix(2)/n,giy(2)/n-s(2)]
    end


;print,drift ;check if is a number
if isnan(drift[0]) or isnan(drift[0]) then begin
    print,'Drift cannot be calculated!'
    return,im
end

im=congrid(im,s(1)*n,s(2)*n,cubic=-0.5)


imm=skew(im,drift(0)*n,drift(1)*n); temporary replacement for gdl

ss=size(imm)
if n ne 1. then imm=congrid(imm,ss(1)/n,ss(2)/n,cubic=-0.5)


return,imm
end