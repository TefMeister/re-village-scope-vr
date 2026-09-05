"""
Measure image-space shift of scope content vs mirror-plane pitch/yaw.
Phase correlation (numpy FFT only), Hann-windowed, mean-subtracted, disc-masked.
Image convention: x grows RIGHT, y grows DOWN.
Reported (dx,dy) = displacement of the CONTENT from base -> frame.
"""
import numpy as np, os, json
from PIL import Image

D=r'C:/Users/TD3KX/github-backups-pd/re-village-scope-vr/dev-archive/recon/2026-09-05-steering-sweep-flat/captures'
OUT=os.path.dirname(os.path.abspath(__file__))
def g(n): return np.asarray(Image.open(os.path.join(D,n)).convert('L'),dtype=np.float64)

BASE='base-p180-y90.jpg'
PITCH=[('pitch-185.jpg',5),('pitch-190.jpg',10),('pitch-195.jpg',15),('pitch-200.jpg',20),('pitch-205.jpg',25)]
YAW  =[('yaw-95.jpg',5),('yaw-100.jpg',10),('yaw-105.jpg',15),('yaw-110.jpg',20),('yaw-115.jpg',25)]

# geometry fitted in locate3.py / refined below
CX,CY = 636.0, 353.0
R_OUT = 262.0      # usable outer radius of scope picture (inside bezel)
R_IN  = 96.0       # radius of the inner dark sub-disc
H,W   = 720,1280

yy,xx=np.mgrid[0:H,0:W]
rr=np.hypot(yy-CY,xx-CX)

def crop(a,cx,cy,half):
    x0,y0=int(cx-half),int(cy-half)
    return a[y0:y0+2*half, x0:x0+2*half], x0, y0

def phasecorr(A,B,mask):
    """shift that takes A -> B, i.e. B(x) ~ A(x - d). Returns dx,dy,peak,ratio."""
    A=A.copy(); B=B.copy()
    A[~mask]=0; B[~mask]=0
    mA=A[mask].mean(); mB=B[mask].mean()
    A[mask]-=mA; B[mask]-=mB
    n,m=A.shape
    wy=np.hanning(n)[:,None]; wx=np.hanning(m)[None,:]
    w=wy*wx
    A*=w; B*=w
    FA=np.fft.rfft2(A); FB=np.fft.rfft2(B)
    Rr=FB*np.conj(FA)
    Rr/= (np.abs(Rr)+1e-12)
    c=np.fft.irfft2(Rr,s=A.shape)
    c=np.fft.fftshift(c)
    pk=np.unravel_index(np.argmax(c),c.shape)
    peak=c[pk]
    # sub-pixel: parabolic on each axis
    def sub(v0,v1,v2):
        den=(v0-2*v1+v2)
        return 0.0 if den==0 else 0.5*(v0-v2)/den
    py,px=pk
    dy=py-n//2; dx=px-m//2
    if 0<py<n-1: dy+=sub(c[py-1,px],c[py,px],c[py+1,px])
    if 0<px<m-1: dx+=sub(c[py,px-1],c[py,px],c[py,px+1])
    # peak sharpness: peak / rms of correlation outside a 9px ball
    ball=np.hypot(*np.mgrid[0:n,0:m])*0
    gy,gx=np.mgrid[0:n,0:m]
    far=np.hypot(gy-py,gx-px)>9
    ratio=peak/ (c[far].std()+1e-12)
    return dx,dy,peak,ratio

def run(region, frames, label):
    half=280
    if region=='annulus':
        mask_full=(rr<R_OUT)&(rr>R_IN+14); half=280
    elif region=='inner':
        mask_full=(rr<R_IN-8); half=110
    elif region=='outside':
        mask_full=(rr>R_OUT+40); half=350
    A0=g(BASE)
    A,x0,y0=crop(A0,CX,CY,half)
    M,_,_=crop(mask_full,CX,CY,half)
    M=M.astype(bool)
    rows=[]
    for fn,ang in frames:
        B,_,_=crop(g(fn),CX,CY,half)
        dx,dy,peak,ratio=phasecorr(A,B,M)
        rows.append((fn,ang,dx,dy,peak,ratio))
    return rows

def table(rows,title):
    s=f'\n{title}\n'
    s+=f'{"frame":18s} {"deg":>4s} {"dx":>9s} {"dy":>9s} {"|d|":>8s} {"peak":>8s} {"peak/rms":>9s}\n'
    for fn,ang,dx,dy,pk,rt in rows:
        s+=f'{fn:18s} {ang:4d} {dx:9.2f} {dy:9.2f} {np.hypot(dx,dy):8.2f} {pk:8.4f} {rt:9.1f}\n'
    return s

report=[]
report.append('='*88)
report.append('SCOPE PITCH-FIT MEASUREMENT  (image y grows DOWNWARD)')
report.append(f'outer disc centre=({CX},{CY}) usable R={R_OUT}; inner sub-disc R={R_IN}')
report.append('='*88)

for reg in ['outside','annulus','inner']:
    rp=run(reg,PITCH,reg)
    ry=run(reg,YAW,reg)
    rb=run(reg,[('back-p180.jpg',0),('back-y90.jpg',0)],reg)
    report.append(table(rp,f'--- PITCH series, region={reg} ---'))
    report.append(table(ry,f'--- YAW series (null control), region={reg} ---'))
    report.append(table(rb,f'--- repeatability controls, region={reg} ---'))
    # least squares fit through origin AND with intercept
    a=np.array([r[1] for r in rp],float)
    for comp,i in (('dx',2),('dy',3)):
        v=np.array([r[i] for r in rp],float)
        A=np.c_[a,np.ones(len(a))]
        sol,*_=np.linalg.lstsq(A,v,rcond=None)
        pred=A@sol; res=v-pred
        s0=(a@v)/(a@a)
        report.append(f'  fit {comp}: slope={sol[0]:+8.3f} px/deg  intercept={sol[1]:+7.2f}  resid rms={res.std():6.2f}  max|res|={np.abs(res).max():6.2f}   (through-origin slope={s0:+8.3f})')
        report.append(f'       residuals: '+' '.join(f'{x:+7.2f}' for x in res))

txt='\n'.join(report)
print(txt)
open(os.path.join(OUT,'results.txt'),'w').write(txt)
