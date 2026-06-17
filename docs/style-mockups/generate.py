#!/usr/bin/env python3
# Pure-python (stdlib only) style-study renderer.
# Draws ONE port scene at two internal resolutions:
#   - vector  : supersampled (r=2) then box-downsampled -> smooth/anti-aliased
#   - pixel   : low-res (r=0.25) then nearest-upscaled  -> chunky pixel art
# Same draw code, two looks. Outputs 3 PNGs.
import math, zlib, struct, os

OW, OH = 540, 960  # final panel size (9:16)

# ---------- palette (shared so only STYLE differs) ----------
SEA_TOP=(26,62,92); SEA_BOT=(48,124,152); WAVE=(120,182,202)
BEACH=(214,196,138); GRASS=(108,150,86); GRASS2=(94,134,74)
WOOD=(140,92,52); WOOD_DK=(96,60,33)
HULL=(122,74,42); HULL_DK=(84,50,28); SAIL=(234,228,212); MAST=(92,62,36)
FLAG=(30,30,36)
SKIN=(234,182,142); BODY_R=(198,84,74); BODY_B=(70,112,172); BODY_G=(86,150,108)
LANT=(255,214,92); LANT_GLOW=(255,236,160)
BUBBLE=(250,250,248); BAR=(176,186,196); TAIL=(250,250,248)
HUD=(18,26,38); CHIP=(255,210,90); DOT_ON=(255,210,90); DOT_OFF=(92,102,118)
JOY=(244,246,248); KNOB=(176,188,204); BTN=(250,200,90); ARROW=(60,50,28)
RESCUE_H=(236,240,246); RESCUE_S=(250,250,250); LIGHT=(255,240,170)

class Canvas:
    def __init__(self, r):
        self.r=r
        self.iw=int(round(OW*r)); self.ih=int(round(OH*r))
        self.buf=bytearray(self.iw*self.ih*3)
    def _put(self,ix,iy,c,a):
        if ix<0 or iy<0 or ix>=self.iw or iy>=self.ih: return
        o=(iy*self.iw+ix)*3
        if a>=1.0:
            self.buf[o]=c[0]; self.buf[o+1]=c[1]; self.buf[o+2]=c[2]
        else:
            self.buf[o]=int(self.buf[o]*(1-a)+c[0]*a)
            self.buf[o+1]=int(self.buf[o+1]*(1-a)+c[1]*a)
            self.buf[o+2]=int(self.buf[o+2]*(1-a)+c[2]*a)
    def rect(self,x,y,w,h,c,a=1.0):
        r=self.r
        for iy in range(int(math.floor(y*r)),int(math.ceil((y+h)*r))):
            for ix in range(int(math.floor(x*r)),int(math.ceil((x+w)*r))):
                self._put(ix,iy,c,a)
    def vgrad(self,x,y,w,h,c0,c1):
        r=self.r; iy0=int(math.floor(y*r)); iy1=int(math.ceil((y+h)*r))
        ix0=int(math.floor(x*r)); ix1=int(math.ceil((x+w)*r)); span=max(1,(iy1-iy0))
        for iy in range(iy0,iy1):
            t=(iy-iy0)/span
            c=(int(c0[0]+(c1[0]-c0[0])*t),int(c0[1]+(c1[1]-c0[1])*t),int(c0[2]+(c1[2]-c0[2])*t))
            for ix in range(ix0,ix1): self._put(ix,iy,c,1.0)
    def circle(self,cx,cy,rad,c,a=1.0):
        r=self.r; cxi=cx*r; cyi=cy*r; ri=rad*r; r2=ri*ri
        for iy in range(int(math.floor(cyi-ri)),int(math.ceil(cyi+ri))):
            for ix in range(int(math.floor(cxi-ri)),int(math.ceil(cxi+ri))):
                dx=ix+0.5-cxi; dy=iy+0.5-cyi
                if dx*dx+dy*dy<=r2: self._put(ix,iy,c,a)
    def ring(self,cx,cy,rad,th,c,a=1.0):
        r=self.r; cxi=cx*r; cyi=cy*r; ro=rad*r; ri=(rad-th)*r; ro2=ro*ro; ri2=ri*ri
        for iy in range(int(math.floor(cyi-ro)),int(math.ceil(cyi+ro))):
            for ix in range(int(math.floor(cxi-ro)),int(math.ceil(cxi+ro))):
                dx=ix+0.5-cxi; dy=iy+0.5-cyi; d=dx*dx+dy*dy
                if ri2<=d<=ro2: self._put(ix,iy,c,a)
    def rrect(self,x,y,w,h,rad,c,a=1.0):
        self.rect(x+rad,y,w-2*rad,h,c,a); self.rect(x,y+rad,w,h-2*rad,c,a)
        self.circle(x+rad,y+rad,rad,c,a); self.circle(x+w-rad,y+rad,rad,c,a)
        self.circle(x+rad,y+h-rad,rad,c,a); self.circle(x+w-rad,y+h-rad,rad,c,a)
    def tri(self,a,b,cc,col,al=1.0):
        r=self.r; p=[(a[0]*r,a[1]*r),(b[0]*r,b[1]*r),(cc[0]*r,cc[1]*r)]
        ys=[q[1] for q in p]
        for iy in range(int(math.floor(min(ys))),int(math.ceil(max(ys)))):
            yc=iy+0.5; xs=[]
            for i in range(3):
                x1,y1=p[i]; x2,y2=p[(i+1)%3]
                if (y1<=yc<y2) or (y2<=yc<y1):
                    t=(yc-y1)/(y2-y1); xs.append(x1+t*(x2-x1))
            if len(xs)>=2:
                xs.sort()
                for ix in range(int(math.floor(xs[0])),int(math.ceil(xs[-1]))):
                    self._put(ix,iy,col,al)
    def to_final(self):
        out=bytearray(OW*OH*3); iw,ih=self.iw,self.ih; b=self.buf
        for oy in range(OH):
            sy0=oy*ih//OH; sy1=(oy+1)*ih//OH
            if sy1<=sy0: sy1=sy0+1
            for ox in range(OW):
                sx0=ox*iw//OW; sx1=(ox+1)*iw//OW
                if sx1<=sx0: sx1=sx0+1
                rr=gg=bb=n=0
                for sy in range(sy0,sy1):
                    base=sy*iw*3
                    for sx in range(sx0,sx1):
                        o=base+sx*3; rr+=b[o]; gg+=b[o+1]; bb+=b[o+2]; n+=1
                o2=(oy*OW+ox)*3; out[o2]=rr//n; out[o2+1]=gg//n; out[o2+2]=bb//n
        return out

def draw_scene(c):
    # sea
    c.vgrad(0,0,OW,592,SEA_TOP,SEA_BOT)
    for wy,wl in ((150,0.35),(250,0.30),(360,0.28),(470,0.26)):
        for wx in range(30,520,120):
            c.rect(wx,wy,46,4,WAVE,wl); c.rect(wx+60,wy+14,30,4,WAVE,wl*0.8)
    # rescue ship on the horizon (the ship you transfer to)
    c.circle(404,150,40,LIGHT,0.18); c.circle(404,150,22,LIGHT,0.16)
    c.tri((382,176),(430,176),(406,150),RESCUE_H)        # bright hull
    c.rect(404,118,4,40,(120,120,120)); c.tri((408,120),(408,156),(440,150),RESCUE_S)  # white sail
    # land
    c.rect(0,560,OW,80,BEACH)
    c.rect(0,624,OW,OH-624,GRASS)
    for gx,gy in ((60,690),(470,720),(120,860),(430,880),(300,820)):
        c.circle(gx,gy,26,GRASS2,1.0)
    # pier
    c.rect(236,360,66,300,WOOD)
    for py in range(372,660,22): c.rect(236,py,66,5,WOOD_DK)
    # ---- the player's ship: a PIRATE ship (black flag = foreshadow) ----
    c.rect(156,330,8,118,MAST)
    c.tri((164,338),(164,408),(232,398),SAIL)            # sail
    c.rrect(92,416,140,52,18,HULL)                       # hull
    c.tri((96,452),(228,452),(150,492),HULL_DK)          # keel
    c.tri((156,330),(156,356),(128,343),FLAG)            # BLACK pirate flag
    c.rect(150,470,24,14,HULL_DK)                        # rudder hint
    # NPC (speaker, e.g. an era figure) on the dock
    c.rrect(316,646,34,42,11,BODY_B); c.circle(333,632,15,SKIN)
    # Guide with lantern (the one who points to Jesus each port)
    c.rrect(196,694,32,40,10,BODY_G); c.circle(212,680,14,SKIN)
    c.circle(246,708,17,LANT_GLOW,0.55); c.circle(246,708,9,LANT)
    # speech bubble
    c.tri((300,556),(346,556),(332,604),TAIL)
    c.rrect(94,470,360,96,20,BUBBLE)
    c.rect(122,492,300,12,BAR); c.rect(122,516,256,12,BAR); c.rect(122,540,196,12,BAR)
    # player char near the joystick
    c.rrect(236,792,28,36,9,BODY_R); c.circle(250,780,13,SKIN)
    # HUD bar + progress (13 ports)
    c.rect(0,0,OW,64,HUD,0.82)
    c.rrect(16,18,118,30,14,CHIP,0.95)
    for i in range(13):
        x=176+i*27
        c.circle(x,33,6,DOT_ON if i<3 else DOT_OFF,1.0)
    # virtual joystick (pushed up)
    c.ring(96,866,56,12,JOY,0.92); c.circle(96,846,26,KNOB,0.95)
    c.tri((78,792),(114,792),(96,776),JOY,0.7)           # up arrow
    c.tri((78,940),(114,940),(96,956),JOY,0.5)           # down arrow
    # action button
    c.circle(452,872,40,BTN,0.96); c.tri((440,858),(440,886),(468,872),ARROW)

# ---------- tiny 5x7 font (only letters we need) ----------
FONT={
'P':["11110","10001","10001","11110","10000","10000","10000"],
'I':["11111","00100","00100","00100","00100","00100","11111"],
'X':["10001","10001","01010","00100","01010","10001","10001"],
'E':["11111","10000","10000","11110","10000","10000","11111"],
'L':["10000","10000","10000","10000","10000","10000","11111"],
'V':["10001","10001","10001","10001","01010","01010","00100"],
'C':["01110","10001","10000","10000","10000","10001","01110"],
'T':["11111","00100","00100","00100","00100","00100","00100"],
'O':["01110","10001","10001","10001","10001","10001","01110"],
'R':["11110","10001","10001","11110","10100","10010","10001"],
' ':["00000"]*7,
}
def text(buf,W,H,s,x,y,sc,col):
    for ch in s:
        g=FONT.get(ch,FONT[' '])
        for ry,row in enumerate(g):
            for rx,bit in enumerate(row):
                if bit=='1':
                    for dy in range(sc):
                        for dx in range(sc):
                            px=x+rx*sc+dx; py=y+ry*sc+dy
                            if 0<=px<W and 0<=py<H:
                                o=(py*W+px)*3; buf[o],buf[o+1],buf[o+2]=col
        x+=6*sc
def tw(s,sc): return len(s)*6*sc-sc

def write_png(path,rgb,w,h):
    raw=bytearray()
    for y in range(h):
        raw.append(0); raw+=rgb[y*w*3:(y+1)*w*3]
    comp=zlib.compress(bytes(raw),6)
    def chunk(t,d): return struct.pack(">I",len(d))+t+d+struct.pack(">I",zlib.crc32(t+d)&0xffffffff)
    with open(path,'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack(">IIBBBBB",w,h,8,2,0,0,0))
                +chunk(b'IDAT',comp)+chunk(b'IEND',b''))

OUT="/home/user/one-scroll-bible-game/docs/style-mockups"
os.makedirs(OUT,exist_ok=True)

print("rendering vector (supersampled)...")
v=Canvas(2.0); draw_scene(v); vfin=v.to_final()
write_png(os.path.join(OUT,"style_vector.png"),vfin,OW,OH)
print("rendering pixel (low-res)...")
p=Canvas(0.25); draw_scene(p); pfin=p.to_final()
write_png(os.path.join(OUT,"style_pixel.png"),pfin,OW,OH)

# ---------- composite compare ----------
M=40; GAP=50; HEAD=120; CW=M*2+OW*2+GAP; CH=M+HEAD+OH+M
comp=bytearray([244,244,246]*(CW*CH))
def blit(panel,ox,oy):
    for y in range(OH):
        srow=y*OW*3; drow=((oy+y)*CW+ox)*3
        comp[drow:drow+OW*3]=panel[srow:srow+OW*3]
lx=M; rx=M+OW+GAP; py=M+HEAD
# borders
for (bx,col) in ((lx,(40,46,56)),(rx,(40,46,56))):
    for t in range(3):
        # frame
        for yy in range(py-t,py+OH+t):
            for xx in (bx-t,bx+OW+t-1):
                if 0<=xx<CW and 0<=yy<CH:
                    o=(yy*CW+xx)*3; comp[o],comp[o+1],comp[o+2]=col
        for xx in range(bx-t,bx+OW+t):
            for yy in (py-t,py+OH+t-1):
                if 0<=xx<CW and 0<=yy<CH:
                    o=(yy*CW+xx)*3; comp[o],comp[o+1],comp[o+2]=col
blit(vfin,lx,py); blit(pfin,rx,py)
DARK=(40,46,56)
text(comp,CW,CH,"VECTOR",lx+(OW-tw("VECTOR",8))//2,46,8,DARK)
text(comp,CW,CH,"PIXEL",rx+(OW-tw("PIXEL",8))//2,46,8,DARK)
write_png(os.path.join(OUT,"style_compare.png"),comp,CW,CH)
print("done:",os.listdir(OUT))
