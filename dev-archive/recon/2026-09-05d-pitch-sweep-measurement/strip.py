import numpy as np, os
from PIL import Image
D=r'C:/Users/TD3KX/github-backups-pd/re-village-scope-vr/dev-archive/recon/2026-09-05-steering-sweep-flat/captures'
order=[('base-p180-y90.jpg','base'),('pitch-185.jpg','+5'),('pitch-190.jpg','+10'),
       ('pitch-195.jpg','+15'),('pitch-200.jpg','+20'),('pitch-205.jpg','+25'),('back-p180.jpg','back')]
# crop the scope picture only: x 380..895, y 100..600
tiles=[]
for fn,t in order:
    a=np.asarray(Image.open(os.path.join(D,fn)).convert('RGB'))[100:600,380:895]
    tiles.append(a)
strip=np.concatenate([np.pad(t,((0,0),(0,6),(0,0)),constant_values=255) for t in tiles],axis=1)
Image.fromarray(strip).resize((strip.shape[1]//2,strip.shape[0]//2)).save('strip-pitch.png')
# top-of-disc band only, magnified
tops=[np.asarray(Image.open(os.path.join(D,fn)).convert('RGB'))[105:225,450:830] for fn,t in order]
ts=np.concatenate([np.pad(t,((0,4),(0,0),(0,0)),constant_values=255) for t in tops],axis=0)
Image.fromarray(ts).save('strip-topband.png')
print('ok',strip.shape,ts.shape)
