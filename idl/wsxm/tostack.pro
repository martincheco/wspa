function tostack,t,chans=chans,sub=sub
;takes mloadwsxm data, converts to a double array (index,channel,x,y)
;chans specifies no. of channels of the same index
;sub takes only a slice on a channel

nn=n_elements(t)

if not(keyword_set(chans)) then begin ;heuristics how many channels are here
    map=multidatamap(t)
    chans=map(0)+1
end

m=nn/chans

if not(keyword_set(sub)) then sub=indgen(chans)

ns=n_elements(sub)
s=size((*t(0)).img)

nt=dblarr(m,ns,s(1),s(2))

for i=0,m-1 do $
    for j=0,ns-1 do begin
	nt(i,j,*,*)=(*t(chans*i+sub(j))).img
    end

return,nt
end