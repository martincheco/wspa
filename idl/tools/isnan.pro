function isnan,value
IF(Finite(value) EQ 0)  THEN BEGIN
      return,1
   END

return,0
end