function rdnline,par,pattern,n=n

;used by loadnanonis.pro
;finds parameter line(s) indices
;if n is set, all set is returned until next tag
if strmid(pattern, 0, 1) eq ":" then begin
    w=where(strpos(par,pattern) eq 0)
    if w(0) eq -1 then w=where(strpos(par,pattern) ne -1)
end else begin
    w=where(strpos(par,pattern) ne -1)
endelse
if w(0) ne -1 then begin
    if not(keyword_set(n)) then return,[w(0),w(0)+1]
    nn=n_elements(par)
    ww=where(strpos(par(w(0)+1:nn-1),":") eq 0)
    if ww(0) ne -1 then return,w(0)+indgen(ww(0)+1)
end
return,-1
end
