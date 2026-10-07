function Autodir, filename                                                          
if size(h, /n_dimensions) EQ 0 then h = filename else h=filename[0]
case strupcase(!VERSION.OS_FAMILY) of
'UNIX': sep = '/'
'WINDOWS': sep = '\'
else: sep = ':'
endcase                                                                       
hpos = STRPOS(h, sep , /REVERSE_SEARCH)                                             
if hpos eq -1 then h='' else h=strmid(h,0,hpos+1)                                   
return,h
end         
