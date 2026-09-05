import numpy as np
from PIL import Image
import os
D=r'C:/Users/TD3KX/github-backups-pd/re-village-scope-vr/dev-archive/recon/2026-09-05-steering-sweep-flat/captures'
def g(n): return np.asarray(Image.open(os.path.join(D,n)).convert('L'),dtype=np.float64)
base=g('base-p180-y90.jpg')
for n in ['pitch-205.jpg','back-p180.jpg','yaw-115.jpg']:
    d=np.abs(g(n)-base)
    im=Image.fromarray(np.clip(d*4,0,255).astype(np.uint8))
    im.save('diff-'+n.replace('.jpg','')+'.png')
# radial profile of mean abs diff about (640,360)
H,W=base.shape
yy,xx=np.mgrid[0:H,0:W]
r=np.hypot(yy-360,xx-640)
for n in ['pitch-205.jpg','back-p180.jpg']:
    d=np.abs(g(n)-base)
    print(n)
    for lo in range(0,640,40):
        m=(r>=lo)&(r<lo+40)
        print(f'   r {lo:3d}-{lo+40:3d}: mean|d|={d[m].mean():6.2f}  baseMean={base[m].mean():6.1f}')
