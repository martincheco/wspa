function mmean,t,nan=nan

w=where(finite(t))
if w(0) ne -1 then return,total(t(w),/preserve,nan=nan)/n_elements(w) else return,0./0.

end
