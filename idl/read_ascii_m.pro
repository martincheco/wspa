function read_ascii_m,f,data_start=data_start,header=header
;faster reading routine

openr,1,f
c=0
a=""
t=""

if keyword_set(data_start) then begin
	header=""
	for i=0,data_start-1 do begin
		readf,1,a
		header=[header,a]
	end
	header=header[1:*]
end


while not(eof(1)) do begin
readf,1,a
t=[t,a]
c=c+1
end
t=t[1:*]

close,1
return,t
end
