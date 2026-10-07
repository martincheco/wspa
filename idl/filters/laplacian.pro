function laplacian,img
kern=[[-1,-1,-1],[-1,8,1],[-1,-1,-1]]
return,convol(img,kern)
end