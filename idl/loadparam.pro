

function loadparam,f
;reads any short text file and produces an array of strings as lines
if not(file_test(f)) then f = dialog_pickfile(/read, /must_exist)
if not(file_test(f)) then return,-1

openr,1,f
par=strarr(999)
counter=-1

repeat begin
counter=counter+1
a=strarr(1)
readf,1,a
par(counter)=a
endrep until counter gt 997 or EOF(1)
par=par(0:counter+1)
par=shift(par,1)
par(0)="Filename: "+f
close,1

return,par
end