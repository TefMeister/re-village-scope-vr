import numpy as np
from corr import gray
CX,CY=636.0,353.0; H,W=720,1280
valid=np.load('valid.npy')
iv=np.cumsum(np.cumsum(np.pad(valid.astype(np.int64),((1,0),(1,0))),0),1)
def allvalid(x,y,P): return iv[y+P,x+P]-iv[y,x+P]-iv[y+P,x]+iv[y,x]==P*P
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
locs=[(x,y) for y in range(0,H-PS,16) for x in range(0,W-PS,16) if allvalid(x,y,PS)]
b=gray('base-p180-y90.jpg')
# use back-p180 as the "same scene, different frame" realistic target, shifted synthetically
tgt0=gray('back-p180.jpg')
L=[]
def P(s):
    print(s); L.append(s)
P('=== Detection ceiling: how large a coherent shift can this pipeline still recover on THIS imagery? ===')
P('    Target = back-p180.jpg (a genuinely re-rendered frame of the same scene) shifted by a known amount.')
P(f'{"true dy":>8s} {"medNCC":>7s} {"dxMed":>7s} {"dyMed":>7s} {"consensus%":>11s}')
for tdy in [0,-25,-50,-100,-150,-200,-250,-300,-400]:
    t=np.roll(tgt0,tdy,axis=0)
    R=[]
    for x,y in locs:
        mp=ncc_map(b[y:y+PS,x:x+PS],t)
        py,px=np.unravel_index(np.argmax(mp),mp.shape)
        R.append((mp[py,px],px-x,py-y))
    R=np.array(R); dx=R[:,1];dy=R[:,2]
    cons=100.0*np.mean((np.abs(dx-np.median(dx))<8)&(np.abs(dy-np.median(dy))<8))
    P(f'{tdy:8d} {np.median(R[:,0]):7.3f} {np.median(dx):7.1f} {np.median(dy):7.1f} {cons:10.0f}%')
open('results-ceiling.txt','w').write('\n'.join(L))
