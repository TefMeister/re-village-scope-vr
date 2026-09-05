import numpy as np
from PIL import Image
import os
D=r'C:/Users/TD3KX/github-backups-pd/re-village-scope-vr/dev-archive/recon/2026-09-05-steering-sweep-flat/captures'
def g(n): return np.asarray(Image.open(os.path.join(D,n)).convert('L'),dtype=np.float64)
names=['base-p180-y90.jpg','pitch-185.jpg','pitch-190.jpg','pitch-195.jpg','pitch-200.jpg','pitch-205.jpg',
       'yaw-95.jpg','yaw-100.jpg','yaw-105.jpg','yaw-110.jpg','yaw-115.jpg','back-p180.jpg','back-y90.jpg']
H,W=720,1280
yy,xx=np.mgrid[0:H,0:W]
for n in names:
    a=g(n)
    m=a>60
    cx=xx[m].mean(); cy=yy[m].mean()
    # iterate
    for _ in range(3):
        r=np.hypot(yy-cy,xx-cx)
        mm=m&(r<330)
        cx=xx[mm].mean(); cy=yy[mm].mean()
    r=np.hypot(yy-cy,xx-cx)
    mm=m&(r<330)
    area=mm.sum()
    rad=np.sqrt(area/np.pi)
    # radial profile of mean brightness
    prof=[]
    for lo in range(0,320,10):
        s=(r>=lo)&(r<lo+10)
        prof.append(a[s].mean())
    print(f'{n:20s} c=({cx:7.2f},{cy:7.2f}) equivR={rad:6.2f} area={area}')
    if n=='base-p180-y90.jpg':
        print('   radial brightness (10px bins from 0):')
        print('   '+' '.join(f'{v:5.0f}' for v in prof))
