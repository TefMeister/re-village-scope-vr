import numpy as np, os
from corr import gray, gauss_hp, rc_window
from PIL import Image
CX,CY=636.0,353.0
BASE='base-p180-y90.jpg'
FR=[('pitch-185.jpg','P+5'),('pitch-190.jpg','P+10'),('pitch-195.jpg','P+15'),('pitch-200.jpg','P+20'),
    ('pitch-205.jpg','P+25'),('yaw-95.jpg','Y+5'),('yaw-100.jpg','Y+10'),('yaw-105.jpg','Y+15'),
    ('yaw-110.jpg','Y+20'),('yaw-115.jpg','Y+25'),('back-p180.jpg','BACK-P'),('back-y90.jpg','BACK-Y')]
H,W=720,1280
yy,xx=np.mgrid[0:H,0:W]
rr=np.hypot(yy-CY,xx-CX)

L=[]
def P(s):
    print(s); L.append(s)

# ---------- 1. zero-shift NCC per region (how similar is the picture at all?) ----------
regions={'annulus (110<r<258)':(rr>110)&(rr<258),
         'inner sub-disc (r<86)':(rr<86),
         'shroud outside (r>300)':(rr>300)}
P('=== 1. Zero-shift normalised correlation of high-passed content vs baseline ===')
P('    1.00 = identical.  This says how much the PICTURE ITSELF changed, ignoring any shift.')
b=gauss_hp(gray(BASE),4.0)
hdr=f'{"frame":16s} '+' '.join(f'{k:>24s}' for k in regions)
P(hdr)
for fn,tag in FR:
    a=gauss_hp(gray(fn),4.0)
    row=f'{tag:16s} '
    for k,m in regions.items():
        x=b[m]-b[m].mean(); y=a[m]-a[m].mean()
        row+=f'{(x@y)/np.sqrt((x@x)*(y@y)):24.3f}'
    P(row)

# ---------- 2. patch-vote search: does ANY part of the base disc reappear anywhere? ----------
def ncc_map(patch,search):
    p=patch-patch.mean()
    ps=np.sqrt((p*p).sum())
    n,m=search.shape; pn,pm=patch.shape
    S=np.fft.rfft2(search,s=(n,m))
    Pf=np.fft.rfft2(p[::-1,::-1],s=(n,m))
    num=np.fft.irfft2(S*Pf,s=(n,m))
    ones=np.fft.rfft2(np.ones_like(p),s=(n,m))
    s1=np.fft.irfft2(S*np.conj(np.fft.rfft2(np.ones_like(p),s=(n,m))*0+ones)*0,s=(n,m))
    # simple local mean/std via cumulative sums
    cs=np.cumsum(np.cumsum(np.pad(search,((1,0),(1,0))),0),1)
    cs2=np.cumsum(np.cumsum(np.pad(search*search,((1,0),(1,0))),0),1)
    def box(c,ph,pw):
        return c[ph:,pw:]-c[:-ph,pw:]-c[ph:,:-pw]+c[:-ph,:-pw]
    S1=box(cs,pn,pm); S2=box(cs2,pn,pm)
    N=pn*pm
    var=S2-S1*S1/N
    var=np.maximum(var,1e-9)
    numv=num[pn-1:pn-1+var.shape[0], pm-1:pm-1+var.shape[1]]
    return numv/(ps*np.sqrt(var))

P('')
P('=== 2. Patch search: take 64x64 patches from the BASELINE scope picture and look for them')
P('    anywhere in the target frame (normalised cross-correlation over the whole 1280x720 frame).')
P('    A real translation would make most patches agree on one (dx,dy) with high NCC.')
bg=gray(BASE)
pts=[]
for ang in np.linspace(0,2*np.pi,10,endpoint=False):
    for rad in (150,215):
        pts.append((int(CX+rad*np.cos(ang))-32,int(CY+rad*np.sin(ang))-32))
pts=[(x,y) for x,y in pts if x>=0 and y>=0 and x+64<=W and y+64<=H]
P(f'    {len(pts)} patches sampled from the baseline disc')
P(f'{"frame":10s} {"medianNCC":>10s} {"maxNCC":>8s} {"n>0.5":>6s} {"n>0.7":>6s}  {"vote spread dx,dy (px, IQR)":>32s}  {"median dx,dy":>16s}')
for fn,tag in FR:
    t=gray(fn)
    dxs=[];dys=[];nccs=[]
    for x,y in pts:
        patch=bg[y:y+64,x:x+64]
        mp=ncc_map(patch,t)
        py,px=np.unravel_index(np.argmax(mp),mp.shape)
        nccs.append(mp[py,px]); dxs.append(px-x); dys.append(py-y)
    nccs=np.array(nccs);dxs=np.array(dxs,float);dys=np.array(dys,float)
    iqx=np.percentile(dxs,75)-np.percentile(dxs,25); iqy=np.percentile(dys,75)-np.percentile(dys,25)
    P(f'{tag:10s} {np.median(nccs):10.3f} {nccs.max():8.3f} {(nccs>0.5).sum():6d} {(nccs>0.7).sum():6d}  {iqx:15.1f} {iqy:16.1f}  {np.median(dxs):8.1f} {np.median(dys):7.1f}')

open('results-overlap.txt','w').write('\n'.join(L))
