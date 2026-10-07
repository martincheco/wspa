function getunit,line
;used by nanonis
;tries to get unit from a line
p1=strpos(line,'(')
if p1(0) ne -1 then p1f=p1(n_elements(p1)-1)+1 else return,''
p2=strpos(line,')')
if p2(0) ne -1 then p2f=p2(n_elements(p2)-1) else return,''
return,strmid(line,p1f,p2f-p1f)
end
