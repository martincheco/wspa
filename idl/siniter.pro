function siniter,amp,T,dt0,w,it,maxit


dt=dt0
dtold=dt
;for i=0,10 do begin
for i=0,maxit-1 do begin
	;print,sin(w*T),sin(w*(T+dt))
	csnt=(cos(w*T)-cos(w*(T+dt)))/w/dt
	;print,csnt
	dtold2=dtold
	dtold=dt
	dt=dt0/(1.+amp*csnt)
	print,dt
	if (abs(dt-dtold)/dt le it) then break
	if abs(dtold2 - dt) le it then dt=(dt+dtold)/2.
end

if i ge maxit-1 then begin

	print,'too many iterations'
	print,amp,T,dt0,w,it,maxit,dt
	return,dt0

end


;print,'**********'
;print,dt0,dt
;print,sin(w*(T+0.5*dt0)),(cos(w*T)-cos(w*(T+dt)))/w/dt



return,dt
end

function csint,a,b


	csint=(cos(2*!PI*a)-cos(2.*!PI*b))/(b-a)/2./!PI
print,sin(2.*!PI*a),sin(2.*!PI*b),(sin(2.*!PI*a)+sin(2.*!PI*b))/2.,sin(2.*!PI*(a+b)/2.)

return,csint
end
