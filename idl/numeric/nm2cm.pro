function nm2cm,wv,exc=exc
;calculates redshift from exc
if not(keyword_set(exc)) then return,1E7/wv

return,1E7/exc-1E7/wv
end
