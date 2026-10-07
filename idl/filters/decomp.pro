function decomp,x
;decompresses values encoded in one long
return,complex (round(x/10000.),round(x mod 10000.))
end
