function gama,img,g

mn=min(img)
mx=max(img)

return,((img-mn)/(mx-mn))^g

end