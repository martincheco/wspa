pro vib_invert,f

openr,1,f
openw,2,f+'m.log',width=100
while not(eof(1)) do begin

	s=""
	readf,1,s
	printf,2,s
	if strpos(s,"Coord Atom Element") ne -1 then begin
		nd=99	
		for i=0,300 do begin
			s=""
			readf,1,s
			ss=strsplit(s,/extract)
			nn=n_elements(ss)
			if nd eq 99 then nd=nn
			if nn ne nd then begin
				printf,2,s
				break
			end else begin
				minuses=string(-ss(3:*),format='(F9.5)')
				s0=string(ss(0),format='(I4)')
				s1=string(ss(1),format='(I6)')
				s2=string(ss(0),format='(I6)')
				printf,2,s0,s1,s2,"        ",minuses
			end

			nd=nn
		end
	end
end



close,1
close,2
end
