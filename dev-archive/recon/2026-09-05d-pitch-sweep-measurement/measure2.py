import numpy as np, os
from corr import *
CX,CY=636.0,353.0
BASE='base-p180-y90.jpg'
PITCH=[('pitch-185.jpg',5),('pitch-190.jpg',10),('pitch-195.jpg',15),('pitch-200.jpg',20),('pitch-205.jpg',25)]
YAW  =[('yaw-95.jpg',5),('yaw-100.jpg',10),('yaw-105.jpg',15),('yaw-110.jpg',20),('yaw-115.jpg',25)]
CTRL =[('back-p180.jpg',0),('back-y90.jpg',0)]

def region(name):
    if name=='annulus': return 300,110,258,40
    if name=='inner':   return 130,0,88,26
    if name=='disc':    return 300,0,258,40
    if name=='outside': return 360,300,600,60   # shroud, camera control

def make(name):
    half,ri,ro,tp=region(name)
    x0,y0=int(CX-half),int(CY-half)
    def sub(a):
        return a[max(y0,0):y0+2*half, max(x0,0):x0+2*half]
    A=sub(gray(BASE))
    W=rc_window(A.shape,CX-max(x0,0),CY-max(y0,0),ri,ro,tp)
    return sub,A,W

L=[]
def P(s):
    print(s); L.append(s)

P('='*100)
P('SCOPE PITCH-FIT MEASUREMENT   image coords: x -> RIGHT, y -> DOWN')
P('(dx,dy) = displacement of scene CONTENT from the baseline frame to the named frame')
P(f'scope picture: centre=({CX},{CY}) px, outer usable radius 258 px, inner sub-disc radius ~92 px')
P('correlator: high-pass(sigma 6) + raised-cosine radial window + phase correlation, parabolic sub-pixel')
P('validation on synthetic shifts of the baseline: exact to 0.01 px out to 150 px, peak/rms >= 68')
P('='*100)

results={}
for reg in ['outside','annulus','inner','disc']:
    sub,A,W=make(reg)
    P(f'\n########## REGION: {reg} ##########')
    for title,frames in [('PITCH (plane pitch 180+d)',PITCH),('YAW (null control, yaw 90+d)',YAW),('CONTROLS (back to 180/90)',CTRL)]:
        P(f'  --- {title} ---')
        P(f'  {"frame":18s} {"deg":>4s} {"dx":>9s} {"dy":>9s} {"|d|":>8s} {"peak":>8s} {"pk/rms":>8s}')
        rows=[]
        for fn,ang in frames:
            B=sub(gray(fn))
            dx,dy,pk,rt=pcorr(A,B,W)
            rows.append((fn,ang,dx,dy,pk,rt))
            P(f'  {fn:18s} {ang:4d} {dx:9.2f} {dy:9.2f} {np.hypot(dx,dy):8.2f} {pk:8.4f} {rt:8.1f}')
        results[(reg,title)]=rows
    # linear fit on pitch
    for tag,frames in [('PITCH',PITCH),('YAW',YAW)]:
        rows=results[(reg,'PITCH (plane pitch 180+d)' if tag=='PITCH' else 'YAW (null control, yaw 90+d)')]
        a=np.array([r[1] for r in rows],float)
        P(f'  --- least-squares fit, {tag}, region={reg} ---')
        for comp,i in (('dx',2),('dy',3)):
            v=np.array([r[i] for r in rows],float)
            M=np.c_[a,np.ones(len(a))]
            sol,*_=np.linalg.lstsq(M,v,rcond=None)
            res=v-M@sol
            s0=(a@v)/(a@a)
            P(f'    {comp}: slope={sol[0]:+8.3f} px/deg  intercept={sol[1]:+7.2f}  residual rms={res.std():6.2f}  max|res|={np.abs(res).max():6.2f}  (origin-forced slope={s0:+8.3f})')
            P(f'        residuals: '+' '.join(f'{x:+7.2f}' for x in res))

txt='\n'.join(L)
open('results.txt','w').write(txt)
