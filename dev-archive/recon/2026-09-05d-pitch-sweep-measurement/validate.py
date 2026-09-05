import numpy as np
from corr import *
CX,CY=636.0,353.0
base=gray('base-p180-y90.jpg')
half=300
x0,y0=int(CX-half),int(CY-half)
sub=lambda a: a[max(y0,0):y0+2*half, x0:x0+2*half]
A=sub(base)
n,m=A.shape
cx,cy=CX-x0,CY-y0
W=rc_window(A.shape,cx,cy,110,258,40)
print('synthetic-shift recovery on the annulus window (truth -> measured):')
for tdx,tdy in [(0,0),(0,-5),(0,-20),(0,-60),(0,-150),(10,0),(30,-30),(0,25),(0,90)]:
    Bfull=np.roll(np.roll(base,tdy,axis=0),tdx,axis=1)
    B=sub(Bfull)
    dx,dy,pk,rt=pcorr(A,B,W)
    print(f'  truth=({tdx:+5d},{tdy:+5d})  meas=({dx:+7.2f},{dy:+7.2f})  peak={pk:.4f} peak/rms={rt:6.1f}')
