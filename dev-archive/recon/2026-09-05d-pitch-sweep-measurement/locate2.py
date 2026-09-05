import numpy as np
from PIL import Image
import os
D=r'C:/Users/TD3KX/github-backups-pd/re-village-scope-vr/dev-archive/recon/2026-09-05-steering-sweep-flat/captures'
def g(n): return np.asarray(Image.open(os.path.join(D,n)).convert('L'),dtype=np.float64)
names=['base-p180-y90.jpg','pitch-185.jpg','pitch-190.jpg','pitch-195.jpg','pitch-200.jpg','pitch-205.jpg',
       'yaw-95.jpg','yaw-100.jpg','yaw-105.jpg','yaw-110.jpg','yaw-115.jpg','back-p180.jpg','back-y90.jpg']
H,W=720,1280
def filled_disc_stats(a):
    m=a>60
    rows=[]
    fill=np.zeros_like(m)
    for y in range(H):
        idx=np.where(m[y])[0]
        if len(idx)>40:
            fill[y,idx.min():idx.max()+1]=True
            rows.append((y,idx.min(),idx.max()))
    yy,xx=np.nonzero(fill)
    cx=xx.mean(); cy=yy.mean(); area=fill.sum()
    return cx,cy,np.sqrt(area/np.pi),rows,fill
print(f'{"frame":22s} {"cx":>8s} {"cy":>8s} {"R":>7s}  {"left@cy":>8s} {"right@cy":>9s} {"top":>5s} {"bot":>5s}')
for n in names:
    a=g(n)
    cx,cy,R,rows,fill=filled_disc_stats(a)
    ys=[r[0] for r in rows]
    # spans at the centre row
    cyr=int(round(cy))
    row=[r for r in rows if r[0]==cyr][0]
    print(f'{n:22s} {cx:8.2f} {cy:8.2f} {R:7.2f}  {row[1]:8d} {row[2]:9d} {min(ys):5d} {max(ys):5d}')
