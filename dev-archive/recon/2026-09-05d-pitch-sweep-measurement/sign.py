import numpy as np, os
from PIL import Image
D=r'C:/Users/TD3KX/github-backups-pd/re-village-scope-vr/dev-archive/recon/2026-09-05-steering-sweep-flat/captures'
CX,CY=636.0,353.0; H,W=720,1280
valid=np.load('valid.npy')
def rgb(n): return np.asarray(Image.open(os.path.join(D,n)).convert('RGB'),dtype=np.float64)
FR=[('base-p180-y90.jpg','base P180',0),('pitch-185.jpg','P+5',5),('pitch-190.jpg','P+10',10),
    ('pitch-195.jpg','P+15',15),('pitch-200.jpg','P+20',20),('pitch-205.jpg','P+25',25),
    ('yaw-95.jpg','Y+5',5),('yaw-100.jpg','Y+10',10),('yaw-105.jpg','Y+15',15),
    ('yaw-110.jpg','Y+20',20),('yaw-115.jpg','Y+25',25),('back-p180.jpg','back-P180',0)]
L=[]
def P(s):
    print(s); L.append(s)

yy,xx=np.mgrid[0:H,0:W]
P('=== A. "sky / distant haze" content: cool-toned pixels (B-R > -10) inside the scope picture ===')
P('   The baseline looks at reeds against a cool distant band at the TOP of the disc.')
P('   skyFrac = fraction of scene pixels that are cool-toned;  skyY = their mean image y (y grows DOWN)')
P(f'{"frame":10s} {"deg":>4s} {"skyFrac":>8s} {"skyY":>7s} {"skyY-CY":>8s} {"meanLum":>8s}')
for fn,tag,ang in FR:
    a=rgb(fn); lum=a.mean(2)
    cool=(a[...,2]-a[...,0])>-10
    m=valid&cool
    fr=m.sum()/valid.sum()
    sy=yy[m].mean() if m.sum()>200 else np.nan
    P(f'{tag:10s} {ang:4d} {fr:8.3f} {sy:7.1f} {sy-CY:8.1f} {lum[valid].mean():8.1f}')

P('')
P('=== B. structure-tensor orientation of the scene texture inside the disc ===')
P('   Reeds seen side-on are VERTICAL lines -> gradient energy is mostly HORIZONTAL (Jxx >> Jyy).')
P('   Looking straight down at ground, that anisotropy collapses.')
P('   ratio = Jxx/Jyy (>1 means vertical structures dominate);  angle = dominant EDGE direction, deg from horizontal')
P(f'{"frame":10s} {"deg":>4s} {"Jxx/Jyy":>8s} {"edgeAng":>8s} {"anisotropy":>11s}')
for fn,tag,ang in FR:
    a=rgb(fn).mean(2)
    gy,gx=np.gradient(a)
    m=valid
    Jxx=(gx[m]**2).mean(); Jyy=(gy[m]**2).mean(); Jxy=(gx[m]*gy[m]).mean()
    th=0.5*np.degrees(np.arctan2(2*Jxy,Jxx-Jyy))
    lam=np.sqrt((Jxx-Jyy)**2+4*Jxy**2)/(Jxx+Jyy)
    P(f'{tag:10s} {ang:4d} {Jxx/Jyy:8.3f} {th:8.1f} {lam:11.3f}')

P('')
P('=== C. vertical luminance profile inside the disc (mean brightness per 40px band of y) ===')
P('    y bands are image rows; y grows DOWNWARD.  Top of disc ~ y=110, bottom ~ y=595')
hdr=f'{"frame":10s}'+''.join(f'{lo:>7d}' for lo in range(110,600,40))
P(hdr)
for fn,tag,ang in FR:
    a=rgb(fn).mean(2); row=f'{tag:10s}'
    for lo in range(110,600,40):
        m=valid&(yy>=lo)&(yy<lo+40)
        row+=f'{(a[m].mean() if m.sum()>50 else np.nan):7.1f}'
    P(row)
open('results-sign.txt','w').write('\n'.join(L))
