
pro save_vsage,f,t
openw,1,f

for i=0,n_elements(t.x)-1 do begin
    printf,1,t.x(i),t.y(i)
end

close,1

end

