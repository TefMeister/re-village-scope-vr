import numpy as np
from PIL import Image
import os
D=r'C:/Users/TD3KX/github-backups-pd/re-village-scope-vr/dev-archive/recon/2026-09-05-steering-sweep-flat/captures'
def g(n): return np.asarray(Image.open(os.path.join(D,n)).convert('L'),dtype=np.float64)
names=['base-p180-y90.jpg','pitch-185.jpg','pitch-190.jpg','pitch-195.jpg','pitch-200.jpg','pitch-205.jpg',
       'yaw-95.jpg','yaw-100.jpg','yaw-105.jpg','yaw-110.jpg','yaw-115.jpg','back-p180.jpg','back-y90.jpg']
st=np.stack([g(n) for n in names])
mx=st.max(0); mn=st.min(0); sd=st.std(0)
Image.fromarray(mx.astype(np.uint8)).save('max-over-frames.png')
Image.fromarray(np.clip(sd*6,0,255).astype(np.uint8)).save('std-over-frames.png')

def bilin(img,x,y):
    x0=int(np.floor(x)); y0=int(np.floor(y))
    if x0<0 or y0<0 or x0>=img.shape[1]-1 or y0>=img.shape[0]-1: return 0.0
    fx=x-x0; fy=y-y0
    return (img[y0,x0]*(1-fx)*(1-fy)+img[y0,x0+1]*fx*(1-fy)+
            img[y0+1,x0]*(1-fx)*fy+img[y0+1,x0+1]*fx*fy)

def boundary(img,cx,cy,thr,rlo,rhi,nang=720):
    pts=[]
    for i in range(nang):
        th=2*np.pi*i/nang
        last=None
        r=rlo
        while r<rhi:
            v=bilin(img,cx+r*np.cos(th),cy+r*np.sin(th))
            if v>thr: last=r
            r+=0.25
        if last is not None: pts.append((th,last))
    return pts

def fitcircle(P):
    x=np.array([p[0] for p in P]); y=np.array([p[1] for p in P])
    A=np.c_[2*x,2*y,np.ones(len(x))]; b=x**2+y**2
    sol,*_=np.linalg.lstsq(A,b,rcond=None)
    cx,cy,c=sol; R=np.sqrt(c+cx*cx+cy*cy)
    res=np.hypot(x-cx,y-cy)-R
    return cx,cy,R,res

cx,cy=640.0,352.0
for it in range(6):
    pts=boundary(mx,cx,cy,70,150,300)
    P=[(cx+r*np.cos(t),cy+r*np.sin(t)) for t,r in pts]
    cx,cy,R,res=fitcircle(P)
print(f'OUTER disc  centre=({cx:.2f},{cy:.2f}) R={R:.2f}  fit resid rms={res.std():.2f} max={np.abs(res).max():.2f} n={len(P)}')
OX,OY,OR=cx,cy,R

# inner dark disc: scan outward from centre, find first radius where max-frame becomes bright
ang=np.linspace(0,2*np.pi,720,endpoint=False)
firsts=[]
for th in ang:
    r=20.0
    while r<160:
        if bilin(mx,OX+r*np.cos(th),OY+r*np.sin(th))>70:
            firsts.append((OX+r*np.cos(th),OY+r*np.sin(th))); break
        r+=0.25
icx,icy,iR,ires=fitcircle(firsts)
print(f'INNER disc  centre=({icx:.2f},{icy:.2f}) R={iR:.2f}  fit resid rms={ires.std():.2f} n={len(firsts)}')
np.save('geom.npy',np.array([OX,OY,OR,icx,icy,iR]))
