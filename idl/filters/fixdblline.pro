function fixdblline,img,pos
;replaces a two rows that are bad by an average of two adjacent rows
;pos is the row index of the lower bad row

s=size(img)
;do nothing if..
if not(keyword_set(pos)) then return,img
if pos lt 1 or pos gt s(2)-3 then return,img
;print,'fixlining!!'
im=img
im(*,pos)=(im(*,pos-1)+im(*,pos+2))/2.
im(*,pos+1)=im(*,pos)


return,im
end