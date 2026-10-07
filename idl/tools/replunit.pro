function replunit,line,unit
;replaces a parentheses-delimited unit in a string
p1=strpos(line,'(')
if p1(0) ne -1 then p1f=p1(n_elements(p1)-1)+1 else return,line+"->("+unit+")"
p2=strpos(line,')')
if p2(0) ne -1 then p2f=p2(n_elements(p2)-1) else return,line+"->("+unit+")"
return,strmid(line,0,p1f-1)+"("+unit+")"
end
