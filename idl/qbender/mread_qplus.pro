function presort,f,sm
;should sort sets according to number of setmembers (sm)
;poorman's sort at the moment

if not(keyword_set(sm)) then sm=4
n=n_elements(f)
f=f(sort(f))
if n mod sm ne 0 then return,reform(f,1,n)

return,reform(f,sm,n/sm)
end



function mread_qplus,f,sm
;should get sorted filenames, in the form (set,setmember)
if not(keyword_set(sm)) then sm=4 ; number of members in a set
ff=presort(f,sm)
s=size(ff)
help,ff
m=s(1) ;sets
n=s(2) ;setmembers

sets=ptrarr(n)
PRINT, FORMAT='($,"Reading set #",I3)', 0
for i=0,n-1 do begin
    sets(i)=ptr_new(read_vsage_set(reform(ff(*,i),m)))
    
    PRINT, FORMAT='($,%"\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b",I5)'
    PRINT, FORMAT='($,"Reading set #",I3)', i+1
end

print
print,"Finished"
return,sets
end