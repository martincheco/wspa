function fixline,img,pos
;replaces a single row that is bad by an average of two adjacent rows
;pos is the row index

s=size(img)
;do nothing if..
if not(keyword_set(pos)) then return,img
if pos lt 1 or pos gt s(2)-2 then return,img
;print,'fixlining!!'
im=img
im(*,pos)=(im(*,pos-1)+im(*,pos+1))/2.


return,im
end