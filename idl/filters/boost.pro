function boost,img
;applies boost mask to 2d array
kern=[[-1,-1,-1],[-1,9,-1],[-1,-1,-1]]
return,convol(img,kern)
end