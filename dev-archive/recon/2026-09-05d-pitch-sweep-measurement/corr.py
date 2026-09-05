import numpy as np, os
from PIL import Image
D=r'C:/Users/TD3KX/github-backups-pd/re-village-scope-vr/dev-archive/recon/2026-09-05-steering-sweep-flat/captures'
def gray(n): return np.asarray(Image.open(os.path.join(D,n)).convert('L'),dtype=np.float64)

def gauss_hp(a,sigma):
    n,m=a.shape
    fy=np.fft.fftfreq(n)[:,None]; fx=np.fft.rfftfreq(m)[None,:]
    G=np.exp(-2*(np.pi**2)*(sigma**2)*(fy**2+fx**2))
    lo=np.fft.irfft2(np.fft.rfft2(a)*G,s=a.shape)
    return a-lo

def rc_window(shape,cx,cy,r_in,r_out,taper):
    n,m=shape
    yy,xx=np.mgrid[0:n,0:m]
    r=np.hypot(yy-cy,xx-cx)
    w=np.ones_like(r)
    if r_in>0:
        w*=np.clip((r-r_in)/taper,0,1)
        w=np.where(r<r_in,0,w)
    w*=np.clip((r_out-r)/taper,0,1)
    w=np.where(r>r_out,0,w)
    # smooth raised cosine on the ramps
    return 0.5-0.5*np.cos(np.pi*np.clip(w,0,1))

def pcorr(A,B,W,sigma=6.0,maxshift=None):
    """returns dx,dy such that content in B sits at position(A)+ (dx,dy)."""
    A=gauss_hp(A,sigma)*W
    B=gauss_hp(B,sigma)*W
    FA=np.fft.rfft2(A); FB=np.fft.rfft2(B)
    R=FB*np.conj(FA); R/=(np.abs(R)+1e-12)
    c=np.fft.fftshift(np.fft.irfft2(R,s=A.shape))
    n,m=A.shape
    cy0,cx0=n//2,m//2
    if maxshift:
        gy,gx=np.mgrid[0:n,0:m]
        c=np.where(np.hypot(gy-cy0,gx-cx0)<=maxshift,c,-1e9)
    py,px=np.unravel_index(np.argmax(c),c.shape)
    peak=c[py,px]
    def sub(v0,v1,v2):
        den=v0-2*v1+v2
        return 0.0 if den==0 else 0.5*(v0-v2)/den
    dy=py-cy0+ (sub(c[py-1,px],c[py,px],c[py+1,px]) if 0<py<n-1 else 0)
    dx=px-cx0+ (sub(c[py,px-1],c[py,px],c[py,px+1]) if 0<px<m-1 else 0)
    gy,gx=np.mgrid[0:n,0:m]
    far=np.hypot(gy-py,gx-px)>10
    cf=c[far]; cf=cf[cf>-1e8]
    return dx,dy,peak,peak/(cf.std()+1e-12)
