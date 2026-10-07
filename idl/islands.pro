pro set12

dir='/home/martin/sync/data/CO_Xe_tips/sorted/Xe_island_CO_tip/Set_12_volume+curves'
bkhr='094'
bk='093'

lr=string([71,73,75,77,79,81,83,85,87,89,91],format='(I03)')
hr=string([72,74,76,78,80,82,84,86,88,90,92],format='(I03)')
w1=1
w2=40
decim=1
wtime=0.1


c=curv_convert(lr,bk,hr=hr,bkhr=bkhr,dir=dir,mask=mask,w1=w1,w2=w2,decim=decim,wtime=wtime,/dfonly)

c=curv_convert(lr,bk,hr=hr,bkhr=bkhr,dir=dir,mask=mask,w1=w1,w2=w2,decim=decim,wtime=wtime)

end


pro set2

dir='/home/martin/sync/data/CO_Xe_tips/sorted/Xe_island_CO_tip/Set_2_old_volume+curves'
bkhr='022'
bk='021'

hr=['002','004','006','008','010','012','014','016','018','020']
lr=['001','003','005','007','009','011','013','015','017','019']
w1=1
w2=250
decim=2
wtime=0.1


c=curv_convert(lr,bk,hr=hr,bkhr=bkhr,dir=dir,mask=mask,w1=w1,w2=w2,decim=decim,wtime=wtime,/dfonly)

c=curv_convert(lr,bk,hr=hr,bkhr=bkhr,dir=dir,mask=mask,w1=w1,w2=w2,decim=decim,wtime=wtime)

end
