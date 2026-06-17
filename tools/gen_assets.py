#!/usr/bin/env python3
"""
Placeholder PIXEL sprite generator (stdlib only -> RGBA PNG).
These are temporary, hand-coded pixel sprites so the game runs out of the box.
Swap with Kenney CC0 pixel packs later (see assets/sprites/ATTRIBUTION.md).
Run:  python3 tools/gen_assets.py
"""
import zlib, struct, os, math

OUTDIR = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
OUTDIR = os.path.abspath(OUTDIR)
os.makedirs(OUTDIR, exist_ok=True)

class G:
    def __init__(self, w, h):
        self.w=w; self.h=h
        self.px=[[(0,0,0,0)]*w for _ in range(h)]
    def set(self,x,y,c):
        x=int(x); y=int(y)
        if 0<=x<self.w and 0<=y<self.h:
            if len(c)==3: c=(c[0],c[1],c[2],255)
            if c[3]>0: self.px[y][x]=c
    def rect(self,x0,y0,x1,y1,c):
        for y in range(int(y0),int(y1)+1):
            for x in range(int(x0),int(x1)+1): self.set(x,y,c)
    def disc(self,cx,cy,r,c):
        for y in range(int(cy-r-1),int(cy+r+2)):
            for x in range(int(cx-r-1),int(cx+r+2)):
                if (x+0.5-cx)**2+(y+0.5-cy)**2<=r*r: self.set(x,y,c)
    def tri(self,a,b,cc,c):
        pts=[a,b,cc]; ys=[p[1] for p in pts]
        for y in range(int(min(ys)),int(max(ys))+1):
            xs=[]
            for i in range(3):
                x1,y1=pts[i]; x2,y2=pts[(i+1)%3]
                if (y1<=y<y2) or (y2<=y<y1):
                    t=(y-y1)/(y2-y1); xs.append(x1+t*(x2-x1))
            if len(xs)>=2:
                xs.sort()
                for x in range(int(xs[0]),int(xs[-1])+1): self.set(x,y,c)
    def png(self,name):
        raw=bytearray()
        for y in range(self.h):
            raw.append(0)
            for x in range(self.w):
                r,g,b,a=self.px[y][x]; raw+=bytes((r,g,b,a))
        comp=zlib.compress(bytes(raw),9)
        def ch(t,d): return struct.pack(">I",len(d))+t+d+struct.pack(">I",zlib.crc32(t+d)&0xffffffff)
        with open(os.path.join(OUTDIR,name),'wb') as f:
            f.write(b'\x89PNG\r\n\x1a\n'+ch(b'IHDR',struct.pack(">IIBBBBB",self.w,self.h,8,6,0,0,0))
                    +ch(b'IDAT',comp)+ch(b'IEND',b''))
        print("  ",name,f"{self.w}x{self.h}")

DARK=(34,28,40); SKIN=(234,182,142)

def person(name, shirt, hair=(64,46,36), hat=None):
    g=G(12,16)
    # legs
    g.rect(3,13,4,15,DARK); g.rect(7,13,8,15,DARK)
    # body outline + shirt
    g.rect(2,7,9,14,DARK)
    g.rect(3,8,8,13,shirt)
    g.rect(2,8,2,12,shirt); g.rect(9,8,9,12,shirt)   # arms
    # head
    g.disc(6,4.4,3.5,DARK)
    g.disc(6,3.7,3.0,hair)
    g.disc(6,5.0,2.6,SKIN)
    g.set(5,5,DARK); g.set(7,5,DARK)                 # eyes
    if hat: g.rect(3,1,8,2,hat); g.rect(2,2,9,2,hat)
    g.png(name)

def lantern():
    g=G(8,11)
    g.rect(3,0,4,1,(120,120,130))      # ring
    g.rect(2,2,5,3,(90,70,40))         # top
    g.disc(3.5,6,3.0,(255,236,160))    # glow
    g.disc(3.5,6,2.0,(255,214,92))     # core
    g.rect(2,9,5,10,(90,70,40))        # base
    g.png("lantern.png")

def ship(name, hull, sail, flag, cross=False):
    g=G(44,32)
    # hull outline + body (3/4 view boat)
    g.disc(10,23,5.5,(60,38,22)); g.disc(33,23,5.5,(60,38,22)); g.rect(10,18,33,27,(60,38,22))
    g.disc(10,22,4.5,hull); g.disc(33,22,4.5,hull); g.rect(10,18,33,26,hull)
    g.rect(11,18,32,19,(255,255,255,40))   # deck highlight
    # mast
    g.rect(21,5,22,20,(92,62,36))
    # sail (triangle)
    for y in range(7,19):
        w=int((y-7)*1.3)
        for x in range(23,23+w): g.set(x,y,sail)
    g.rect(23,7,23,18,(255,255,255,60))
    if cross:
        g.rect(28,9,29,15,(212,160,60)); g.rect(26,11,31,12,(212,160,60))
    # flag at masthead
    g.rect(13,4,21,7,flag)
    g.tri((13,4),(13,7),(9,5.5),flag)
    if flag==(30,30,36):                    # skull on pirate flag
        g.set(16,5,(235,235,235)); g.set(18,5,(235,235,235)); g.set(17,6,(235,235,235))
    g.png(name)

def sign():
    g=G(14,18)
    g.rect(6,14,7,17,(70,52,34))            # post
    g.rect(1,1,12,13,(70,74,84))            # stone border
    g.rect(2,2,11,12,(150,158,168))         # stone face
    g.rect(3,4,10,4,(96,104,116)); g.rect(3,7,9,7,(96,104,116)); g.rect(3,10,10,10,(96,104,116))
    g.png("sign.png")

def cross():
    g=G(14,22)
    g.rect(5,1,8,21,(60,38,22)); g.rect(1,6,12,9,(60,38,22))
    g.rect(6,2,7,20,(150,96,52)); g.rect(2,7,11,8,(150,96,52))
    g.png("cross.png")

def serpent():
    g=G(18,11)
    body=(70,120,70); dk=(40,80,46)
    pts=[(1,8),(4,4),(8,7),(12,3),(15,6),(16,2)]
    for i in range(len(pts)-1):
        x0,y0=pts[i]; x1,y1=pts[i+1]; n=8
        for s in range(n+1):
            t=s/n; x=x0+(x1-x0)*t; y=y0+(y1-y0)*t
            g.disc(x,y,1.6,dk); g.disc(x,y,1.0,body)
    g.set(16,2,(220,60,60))   # tongue/eye
    g.png("serpent.png")

def tree():
    g=G(16,20)
    g.rect(7,13,9,19,(96,64,40))
    g.disc(8,9,5.5,(54,110,60)); g.disc(5,11,3.5,(54,110,60)); g.disc(11,11,3.5,(54,110,60))
    g.disc(8,8,4.0,(86,150,86))
    g.png("tree.png")

def bush():
    g=G(12,8)
    g.disc(4,5,3.0,(70,120,72)); g.disc(8,5,3.0,(70,120,72)); g.disc(6,4,3.2,(94,150,94))
    g.png("bush.png")

def tile_water():
    g=G(16,16)
    g.rect(0,0,15,15,(48,124,152))
    for (x,y) in ((2,3),(9,5),(5,10),(12,12),(1,13),(11,1)):
        g.rect(x,y,x+2,y,(110,178,200))
    g.png("tile_water.png")

def tile_grass():
    g=G(16,16)
    g.rect(0,0,15,15,(108,150,86))
    for (x,y) in ((3,4),(10,2),(6,9),(13,11),(2,12),(9,13)):
        g.set(x,y,(94,134,74)); g.set(x+1,y,(126,166,98))
    g.png("tile_grass.png")

def tile_sand():
    g=G(16,16)
    g.rect(0,0,15,15,(214,196,138))
    for (x,y) in ((4,5),(11,3),(7,11),(2,9)): g.set(x,y,(196,176,120))
    g.png("tile_sand.png")

def tile_plank():
    g=G(16,16)
    g.rect(0,0,15,15,(140,92,52))
    for y in (0,5,10,15): g.rect(0,y,15,y,(96,60,33))
    g.rect(7,0,7,15,(110,72,40))
    g.png("tile_plank.png")

def waterfx():  # a small foam/sparkle used for shimmer
    g=G(6,3); g.rect(0,1,5,1,(180,220,235)); g.set(1,0,(220,240,250)); g.png("sparkle.png")

print("generating sprites ->", OUTDIR)
person("player.png",(70,112,172), hair=(50,40,34), hat=(40,40,46))
person("guide.png",(206,186,146), hair=(190,190,196))
person("npc_red.png",(198,84,74))
person("npc_teal.png",(86,150,108))
person("npc_purple.png",(150,110,200), hair=(48,40,52))
lantern()
ship("ship_pirate.png",(122,74,42),(232,226,210),(30,30,36))
ship("ship_rescue.png",(150,110,80),(248,248,250),(244,210,120),cross=True)
sign(); cross(); serpent(); tree(); bush()
tile_water(); tile_grass(); tile_sand(); tile_plank(); waterfx()
print("done.")
