import numpy as np
from PIL import Image
from corr import gray
CX,CY=636.0,353.0; H,W=720,1280
same=['base-p180-y90.jpg','back-p180.jpg','back-y90.jpg','yaw-95.jpg','yaw-100.jpg','yaw-105.jpg','yaw-110.jpg','yaw-115.jpg']
st=np.stack([gray(n) for n in same])
med=np.median(st,0)
yy,xx=np.mgrid[0:H,0:W]
rr=np.hypot(yy-CY,xx-CX)
# scene = bright in the same-scene frames, inside the annulus
scene=(med>75)&(rr>105)&(rr<245)
# grow the exclusion (reticle lines / rim) by 6 px
bad=~scene
gb=bad.copy()
for _ in range(6):
    gb=gb|np.roll(gb,1,0)|np.roll(gb,-1,0)|np.roll(gb,1,1)|np.roll(gb,-1,1)
valid=~gb
np.save('valid.npy',valid)
print('valid scene pixels:',valid.sum())
vis=np.stack([gray('base-p180-y90.jpg')]*3,-1)
vis[...,1]=np.where(valid,255,vis[...,1])
Image.fromarray(vis.astype(np.uint8)).save('check-scene-mask.png')
# geometry overlay
ov=np.stack([gray('base-p180-y90.jpg')]*3,-1)
for R,c in ((258,(255,0,0)),(105,(0,128,255)),(92,(255,255,0))):
    ring=np.abs(rr-R)<1.2
    for i in range(3): ov[...,i]=np.where(ring,c[i],ov[...,i])
Image.fromarray(ov.astype(np.uint8)).save('check-disc-geometry.png')
print('wrote check-scene-mask.png, check-disc-geometry.png')
