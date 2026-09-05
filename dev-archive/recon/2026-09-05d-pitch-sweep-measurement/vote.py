import numpy as np, os
from corr import gray
CX,CY=636.0,353.0; H,W=720,1280
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

PS=96
def patches(img,cx,cy,rmax):
    out=[]
    for ang in np.linspace(0,2*np.pi,16,endpoint=False):
        for rad in (120,175,225):
            x=int(cx+rad*np.cos(ang))-PS//2; y=int(cy+rad*np.sin(ang))-PS//2
            if x<0 or y<0 or x+PS>W or y+PS>H: continue
            # keep only patches fully inside the scope picture
            ok=True
            for ddx,ddy in ((0,0),(PS,0),(0,PS),(PS,PS)):
                if np.hypot(x+ddx-cx,y+ddy-cy)>rmax: ok=False
            if ok: out.append((x,y))
    return out

def vote(bn,tn,thr=0.75):
    b=gray(bn); t=gray(tn)
    res=[]
    for x,y in patches(b,CX,CY,258):
        mp=ncc_map(b[y:y+PS,x:x+PS],t)
        py,px=np.unravel_index(np.argmax(mp),mp.shape)
        res.append((mp[py,px],px-x,py-y))
    res=np.array(res)
    good=res[res[:,0]>=thr]
    return res,good

L=[]
def P(s):
    print(s); L.append(s)
P(f'=== High-confidence patch votes (patch {PS}x{PS}, NCC>=0.75) ===')
P('   n = patches inside the scope picture that found a >=0.75 match anywhere in the target frame')
P(f'{"pair":34s} {"nPatch":>6s} {"nGood":>6s} {"medNCC":>7s} {"dx med":>7s} {"dy med":>7s} {"dx sd":>7s} {"dy sd":>7s}')
BASE='base-p180-y90.jpg'
pairs=[(BASE,'pitch-185.jpg','base -> P+5'),(BASE,'pitch-190.jpg','base -> P+10'),
       (BASE,'pitch-195.jpg','base -> P+15'),(BASE,'pitch-200.jpg','base -> P+20'),
       (BASE,'pitch-205.jpg','base -> P+25'),
       ('pitch-185.jpg','pitch-190.jpg','P+5  -> P+10 (consecutive)'),
       ('pitch-190.jpg','pitch-195.jpg','P+10 -> P+15 (consecutive)'),
       ('pitch-195.jpg','pitch-200.jpg','P+15 -> P+20 (consecutive)'),
       ('pitch-200.jpg','pitch-205.jpg','P+20 -> P+25 (consecutive)'),
       (BASE,'yaw-95.jpg','base -> Y+5'),(BASE,'yaw-105.jpg','base -> Y+15'),
       (BASE,'yaw-115.jpg','base -> Y+25'),
       (BASE,'back-p180.jpg','base -> back-p180 (REPEAT)'),
       (BASE,'back-y90.jpg','base -> back-y90 (REPEAT)')]
store={}
for a,b,lab in pairs:
    res,good=vote(a,b)
    store[lab]=(res,good)
    if len(good)>=2:
        P(f'{lab:34s} {len(res):6d} {len(good):6d} {np.median(res[:,0]):7.3f} {np.median(good[:,1]):7.1f} {np.median(good[:,2]):7.1f} {good[:,1].std():7.1f} {good[:,2].std():7.1f}')
    else:
        P(f'{lab:34s} {len(res):6d} {len(good):6d} {np.median(res[:,0]):7.3f} {"--":>7s} {"--":>7s} {"--":>7s} {"--":>7s}')
open('results-votes.txt','w').write('\n'.join(L))
