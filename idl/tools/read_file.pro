function read_file,f,array=array,igcom=igcom
;igcom ignores line commented with #
;array stores the file contents to an array, otherwise a long string is returned
openr,1,f
a=''
b=''
while not eof(1) do begin
    readf,1,a
    if not(keyword_set(igcom)) or strmid(a,0,1) ne '#' then $
	if keyword_set(array) then b=[b,a] else b=b+a
end
close,1

if keyword_set(array) then b=b[1:*]
return,b
end
