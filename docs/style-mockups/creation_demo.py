#!/usr/bin/env python3
# Proof-of-effects: a "Creation" 연출 rendered in PIXEL style, pure python.
# Frame A: darkness + lightning over the deep.  Frame B: light + life.
import math, zlib, struct, os, random
OW,OH=540,960
random.seed(7)

class Canvas:
    def __init__(self,r):
        self.r=r; self.iw=int(round(OW*r)); self.ih=int(round(OH*r)); self.buf=bytearray(self.iw*self.ih*3)
    def _put(self,ix,iy,c,a):
        if ix<0 or iy<0 or ix>=self.iw or iy>=self.ih: return
        o=(iy*self.iw+ix)*3
        if a>=1.0: self.buf[o]=c[0]; self.buf[o+1]=c[1]; self.buf[o+2]=c[2]
        else:
            self.buf[o]=int(self.buf[o]*(1-a)+c[0]*a); self.buf[o+1]=int(self.buf[o+1]*(1-a)+c[1]*a); self.buf[o+2]=int(self.buf[o+2]*(1-a)+c[2]*a)
    def add(self,ix,iy,c,a):  # additive-ish (for glow)
        if ix<0 or iy<0 or ix>=self.iw or iy>=self.ih: return
        o=(iy*self.iw+ix)*3
        self.buf[o]=min(255,int(self.buf[o]+c[0]*a)); self.buf[o+1]=min(255,int(self.buf[o+1]+c[1]*a)); self.buf[o+2]=min(255,int(self.buf[o+2]+c[2]*a))
    def rect(self,x,y,w,h,c,a=1.0):
        r=self.r
        for iy in range(int(math.floor(y*r)),int(math.ceil((y+h)*r))):
            for ix in range(int(math.floor(x*r)),int(math.ceil((x+w)*r))): self._put(ix,iy,c,a)
    def vgrad(self,x,y,w,h,c0,c1):
        r=self.r; iy0=int(math.floor(y*r)); iy1=int(math.ceil((y+h)*r)); ix0=int(math.floor(x*r)); ix1=int(math.ceil((x+w)*r)); span=max(1,iy1-iy0)
        for iy in range(iy0,iy1):
            t=(iy-iy0)/span; c=(int(c0[0]+(c1[0]-c0[0])*t),int(c0[1]+(c1[1]-c0[1])*t),int(c0[2]+(c1[2]-c0[2])*t))
            for ix in range(ix0,ix1): self._put(ix,iy,c,1.0)
    def circle(self,cx,cy,rad,c,a=1.0,additive=False):
        r=self.r; cxi=cx*r; cyi=cy*r; ri=rad*r; r2=ri*ri
        for iy in range(int(math.floor(cyi-ri)),int(math.ceil(cyi+ri))):
            for ix in range(int(math.floor(cxi-ri)),int(math.ceil(cxi+ri))):
                dx=ix+0.5-cxi; dy=iy+0.5-cyi
                if dx*dx+dy*dy<=r2:
                    (self.add if additive else self._put)(ix,iy,c,a)
    def glow(self,cx,cy,rad,c,a):  # soft radial additive
        r=self.r; cxi=cx*r; cyi=cy*r; ri=rad*r; r2=ri*ri
        for iy in range(int(math.floor(cyi-ri)),int(math.ceil(cyi+ri))):
            for ix in range(int(math.floor(cxi-ri)),int(math.ceil(cxi+ri))):
                dx=ix+0.5-cxi; dy=iy+0.5-cyi; d=dx*dx+dy*dy
                if d<=r2: self.add(ix,iy,c,a*(1-(d/r2)))
    def tri(self,a,b,cc,col,al=1.0,additive=False):
        r=self.r; p=[(a[0]*r,a[1]*r),(b[0]*r,b[1]*r),(cc[0]*r,cc[1]*r)]; ys=[q[1] for q in p]
        for iy in range(int(math.floor(min(ys))),int(math.ceil(max(ys)))):
            yc=iy+0.5; xs=[]
            for i in range(3):
                x1,y1=p[i]; x2,y2=p[(i+1)%3]
                if (y1<=yc<y2) or (y2<=yc<y1): t=(yc-y1)/(y2-y1); xs.append(x1+t*(x2-x1))
            if len(xs)>=2:
                xs.sort()
                for ix in range(int(math.floor(xs[0])),int(math.ceil(xs[-1]))): (self.add if additive else self._put)(ix,iy,col,al)
    def stamp(self,x0,y0,x1,y1,rad,c,a,additive=False):
        n=int(max(abs(x1-x0),abs(y1-y0))/2)+1
        for i in range(n+1):
            t=i/n; (self.glow if additive else self.circle)(x0+(x1-x0)*t,y0+(y1-y0)*t,rad,c,a)
    def to_final(self):
        out=bytearray(OW*OH*3); iw,ih=self.iw,self.ih; b=self.buf
        for oy in range(OH):
            sy0=oy*ih//OH; sy1=max(sy0+1,(oy+1)*ih//OH)
            for ox in range(OW):
                sx0=ox*iw//OW; sx1=max(sx0+1,(ox+1)*iw//OW); rr=gg=bb=n=0
                for sy in range(sy0,sy1):
                    base=sy*iw*3
                    for sx in range(sx0,sx1):
                        o=base+sx*3; rr+=b[o]; gg+=b[o+1]; bb+=b[o+2]; n+=1
                o2=(oy*OW+ox)*3; out[o2]=rr//n; out[o2+1]=gg//n; out[o2+2]=bb//n
        return out

def bolt(c, pts):
    # glow passes then bright core
    for i in range(len(pts)-1):
        c.stamp(pts[i][0],pts[i][1],pts[i+1][0],pts[i+1][1],22,(60,90,200),0.20,additive=True)
    for i in range(len(pts)-1):
        c.stamp(pts[i][0],pts[i][1],pts[i+1][0],pts[i+1][1],11,(120,160,255),0.30,additive=True)
    for i in range(len(pts)-1):
        c.stamp(pts[i][0],pts[i][1],pts[i+1][0],pts[i+1][1],4,(220,235,255),0.9)
    for i in range(len(pts)-1):
        c.stamp(pts[i][0],pts[i][1],pts[i+1][0],pts[i+1][1],1.6,(255,255,255),1.0)

def frame_night():
    c=Canvas(0.25)
    c.vgrad(0,0,OW,640,(6,8,20),(22,24,54))
    c.vgrad(0,560,OW,90,(22,24,54),(14,16,40))
    # the deep waters
    c.vgrad(0,640,OW,OH-640,(10,16,34),(6,10,24))
    for _ in range(60):
        x=random.randint(0,540); y=random.randint(660,950); c.rect(x,y,random.choice([8,12]),3,(34,54,104),0.5)
    # Spirit hovering over the waters - soft band
    c.glow(270,690,180,(40,70,150),0.5)
    # main lightning bolt
    main=[(300,40),(276,150),(312,250),(258,360),(286,470),(250,560),(272,640)]
    # jitter
    main=[(x+random.randint(-4,4),y) for (x,y) in main]
    bolt(c,main)
    # branches
    bolt(c,[(312,250),(372,300),(404,372)])
    bolt(c,[(286,470),(214,510),(196,560)])
    # flash bloom
    c.glow(290,250,260,(90,120,230),0.35)
    c.glow(300,80,120,(160,190,255),0.5)
    # sparks
    for _ in range(40):
        x=random.randint(180,400); y=random.randint(60,560); c.add(int(x*c.r),int(y*c.r),(200,220,255),0.9)
    return c.to_final()

def rays(c,cx,cy,col,a,n=12,length=520):
    for i in range(n):
        ang=(i/n)*math.tau+0.2; dx=math.cos(ang); dy=math.sin(ang)
        ex=cx+dx*length; ey=cy+dy*length; px=-dy; py=dx; w=10
        c.tri((cx+px*4,cy+py*4),(cx-px*4,cy-py*4),(ex+px*w,ey+py*w),col,a,additive=True)

def frame_light():
    c=Canvas(0.25)
    c.vgrad(0,0,OW,560,(252,224,150),(150,206,232))
    # sun / "let there be light"
    rays(c,270,150,(255,238,170),0.10)
    c.glow(270,150,230,(255,236,170),0.7)
    c.circle(270,150,58,(255,250,224),1.0); c.circle(270,150,46,(255,244,200),1.0)
    # sea
    c.vgrad(0,560,OW,200,(54,140,194),(40,116,170))
    for _ in range(50):
        x=random.randint(0,540); y=random.randint(570,748); c.rect(x,y,random.choice([10,14]),3,(150,206,230),0.6)
    # land / vegetation appearing
    c.vgrad(0,720,OW,OH-720,(112,160,86),(86,134,70))
    for gx,gy in ((70,820),(470,860),(150,910),(420,930),(300,880),(220,800)):
        c.circle(gx,gy,30,(94,140,74),1.0); c.circle(gx,gy-10,18,(120,168,92),1.0)
    # a tree
    c.rect(360,790,14,60,(96,64,40)); c.circle(367,780,34,(86,150,86)); c.circle(345,792,22,(100,164,96)); c.circle(388,792,22,(100,164,96))
    # birds
    for bx,by in ((150,250),(200,230),(120,300),(420,270)):
        c.tri((bx,by),(bx+14,by-8),(bx+28,by),(60,72,90),0.9)
    # light sparkle motes
    for _ in range(40):
        x=random.randint(60,500); y=random.randint(60,520); c.add(int(x*c.r),int(y*c.r),(255,248,210),0.8)
    return c.to_final()

# ---- font (subset) ----
FONT={
'N':["10001","11001","10101","10011","10001","10001","10001"],
'I':["11111","00100","00100","00100","00100","00100","11111"],
'G':["01110","10001","10000","10111","10001","10001","01111"],
'H':["10001","10001","10001","11111","10001","10001","10001"],
'T':["11111","00100","00100","00100","00100","00100","00100"],
'L':["10000","10000","10000","10000","10000","10000","11111"],
' ':["00000"]*7}
def text(buf,W,H,s,x,y,sc,col):
    for ch in s:
        g=FONT.get(ch,FONT[' '])
        for ry,row in enumerate(g):
            for rx,b in enumerate(row):
                if b=='1':
                    for dy in range(sc):
                        for dx in range(sc):
                            px=x+rx*sc+dx; py=y+ry*sc+dy
                            if 0<=px<W and 0<=py<H: o=(py*W+px)*3; buf[o],buf[o+1],buf[o+2]=col
        x+=6*sc
def tw(s,sc): return len(s)*6*sc-sc
def write_png(path,rgb,w,h):
    raw=bytearray()
    for y in range(h): raw.append(0); raw+=rgb[y*w*3:(y+1)*w*3]
    comp=zlib.compress(bytes(raw),6)
    def ch(t,d): return struct.pack(">I",len(d))+t+d+struct.pack(">I",zlib.crc32(t+d)&0xffffffff)
    with open(path,'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n'+ch(b'IHDR',struct.pack(">IIBBBBB",w,h,8,2,0,0,0))+ch(b'IDAT',comp)+ch(b'IEND',b''))

OUT="/home/user/one-scroll-bible-game/docs/style-mockups"; os.makedirs(OUT,exist_ok=True)
print("night frame..."); a=frame_night(); write_png(OUT+"/fx_creation_night.png",a,OW,OH)
print("light frame..."); b=frame_light(); write_png(OUT+"/fx_creation_light.png",b,OW,OH)
M=40; GAP=50; HEAD=120; CW=M*2+OW*2+GAP; CH=M+HEAD+OH+M
comp=bytearray([18,20,28]*(CW*CH))
def blit(panel,ox,oy):
    for y in range(OH):
        s=y*OW*3; d=((oy+y)*CW+ox)*3; comp[d:d+OW*3]=panel[s:s+OW*3]
lx=M; rx=M+OW+GAP; py=M+HEAD; blit(a,lx,py); blit(b,rx,py)
W=(235,238,248)
text(comp,CW,CH,"NIGHT",lx+(OW-tw("NIGHT",8))//2,46,8,W)
text(comp,CW,CH,"LIGHT",rx+(OW-tw("LIGHT",8))//2,46,8,W)
write_png(OUT+"/fx_creation_compare.png",comp,CW,CH)
print("done")
