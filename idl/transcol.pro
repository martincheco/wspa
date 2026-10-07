function transcol,gg
r=gg(0)
g=gg(1)
b=gg(2)
return, r + g*256L + b*256L^2
end