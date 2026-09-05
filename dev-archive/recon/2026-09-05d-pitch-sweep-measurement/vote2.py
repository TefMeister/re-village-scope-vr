import numpy as np
from corr import gray
CX,CY=636.0,353.0; H,W=720,1280
valid=np.load('valid.npy')
iv=np.cumsum(np.cumsum(np.pad(valid.astype(np.int64),((1,0),(1,0))),0),1)
def allvalid(x,y,P):
    return iv[y+P,x+P]-iv[y,x+P]-iv[y+P,x]+iv[y,x]==P*P
def ncc_map(patch,search):
    p=patch-patch.mean(); ps=np.sqrt((p*p).sum())
    n,m=search.shape; pn,pm=patch.shape
    num=np.fft.irfft2(np.fft.rfft2(search,s=(n,m))*np.fft.rfft2(p[::-1,::-1],s=(n,m)),s=(n,m))
    cs=np.cumsum(np.cumsum(np.pad(search,((1,0),(1,0))),0),1)
    cs2=np.cumsum(np.cumsum(np.pad(search*search,((1,0),(1,0))),0),1)
    box=lambda c: c[pn:,pm:]-c[:-pn,pm:]-c[pn:,:-pm]+c[:-pn,:-pm]
    S1=box(cs);S2=box(cs2);N=pn*pm
    var=np.maximum(S2-S1*S1/N,1e-9)
    nv=num[pn-1:pn-1+var.shape[0], pm-1:pm-1+var.shape[1]]
    return nv/(ps*np.sqrt(var))
PS=80
locs=[]
for y in range(0,H-PS,16):
    for x in range(0,W-PS,16):
        if allvalid(x,y,PS): locs.append((x,y))
print('scene-only patch positions:',len(locs))
locs=locs[::max(1,len(locs)//40)]
print('using',len(locs))
BASE='base-p180-y90.jpg'
pairs=[('pitch-185.jpg','P+5'),('pitch-190.jpg','P+10'),('pitch-195.jpg','P+15'),
       ('pitch-200.jpg','P+20'),('pitch-205.jpg','P+25'),
       ('yaw-95.jpg','Y+5'),('yaw-100.jpg','Y+10'),('yaw-105.jpg','Y+15'),
       ('yaw-110.jpg','Y+20'),('yaw-115.jpg','Y+25'),
       ('back-p180.jpg','back-p180'),('back-y90.jpg','back-y90')]
b=gray(BASE)
L=[]
def P_(s):
    print(s); L.append(s)
P_(f'=== Scene-only patch votes ({PS}x{PS} patches, reticle/bezel/inner-disc excluded) ===')
P_(f'{"pair":12s} {"n":>3s} {"medNCC":>7s} {"n>=.7":>6s} {"dxMed":>7s} {"dyMed":>7s} {"dxIQR":>7s} {"dyIQR":>7s} {"consensus%":>10s}')
for fn,tag in pairs:
    t=gray(fn); R=[]
    for x,y in locs:
        mp=ncc_map(b[y:y+PS,x:x+PS],t)
        py,px=np.unravel_index(np.argmax(mp),mp.shape)
        R.append((mp[py,px],px-x,py-y))
    R=np.array(R)
    ng=(R[:,0]>=0.7).sum()
    dx=R[:,1];dy=R[:,2]
    mdx,mdy=np.median(dx),np.median(dy)
    cons=100.0*np.mean((np.abs(dx-mdx)<8)&(np.abs(dy-mdy)<8))
    P_(f'{tag:12s} {len(R):3d} {np.median(R[:,0]):7.3f} {ng:6d} {mdx:7.1f} {mdy:7.1f} '
       f'{np.percentile(dx,75)-np.percentile(dx,25):7.1f} {np.percentile(dy,75)-np.percentile(dy,25):7.1f} {cons:9.0f}%')
open('results-votes2.txt','w').write('\n'.join(L))
