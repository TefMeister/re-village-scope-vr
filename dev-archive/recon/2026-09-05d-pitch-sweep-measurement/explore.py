import numpy as np
from PIL import Image
import os
D=r'C:/Users/TD3KX/github-backups-pd/re-village-scope-vr/dev-archive/recon/2026-09-05-steering-sweep-flat/captures'
def g(n):
    return np.asarray(Image.open(os.path.join(D,n)).convert('L'),dtype=np.float64)
base=g('base-p180-y90.jpg')
names=['pitch-185.jpg','pitch-190.jpg','pitch-195.jpg','pitch-200.jpg','pitch-205.jpg',
       'yaw-95.jpg','yaw-100.jpg','yaw-105.jpg','yaw-110.jpg','yaw-115.jpg',
       'back-p180.jpg','back-y90.jpg']
H,W=base.shape
yy,xx=np.mgrid[0:H,0:W]
for n in names:
    d=np.abs(g(n)-base)
    m=d>12
    tot=m.sum()
    if tot>50:
        cy=(yy[m]).mean(); cx=(xx[m]).mean()
        # radial spread from that centroid
        r=np.hypot(yy[m]-cy,xx[m]-cx)
        print(f'{n:18s} meanabs={d.mean():7.3f} npx>12={tot:7d} centroid=({cx:6.1f},{cy:6.1f}) r50={np.percentile(r,50):6.1f} r95={np.percentile(r,95):6.1f}')
    else:
        print(f'{n:18s} meanabs={d.mean():7.3f} npx>12={tot:7d}')
