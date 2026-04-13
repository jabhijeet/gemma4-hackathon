"""
Create a simple app icon as a valid PNG file
Uses a minimal approach with pre-computed PNG structure
"""
import os
import struct
import zlib

def create_png(width, height, pixels_rgba):
    """Create a PNG file from raw RGBA pixel data"""
    def make_chunk(ctype, data):
        c = ctype + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    
    # Build raw image data with filter byte per row
    raw = b''
    for y in range(height):
        raw += b'\x00'  # No filter
        for x in range(width):
            idx = (y * width + x) * 4
            raw += bytes(pixels_rgba[idx:idx+4])
    
    header = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    
    return (header + 
            make_chunk(b'IHDR', ihdr) +
            make_chunk(b'IDAT', zlib.compress(raw, 9)) +
            make_chunk(b'IEND', b''))

def generate_icon():
    size = 512
    pixels = bytearray(size * size * 4)
    
    # Colors
    BG1 = (45, 100, 190, 255)   # Dark blue
    BG2 = (70, 150, 220, 255)   # Light blue
    WHITE = (255, 255, 255, 255)
    ORANGE = (255, 170, 60, 255)
    CYAN = (80, 200, 255, 255)
    
    for y in range(size):
        for x in range(size):
            idx = (y * size + x) * 4
            # Gradient background
            t = (x + y) / (2 * size)
            pixels[idx] = int(BG1[0] + (BG2[0] - BG1[0]) * t)
            pixels[idx+1] = int(BG1[1] + (BG2[1] - BG1[1]) * t)
            pixels[idx+2] = int(BG1[2] + (BG2[2] - BG1[2]) * t)
            pixels[idx+3] = BG1[3]
    
    cx, cy = 256, 256
    
    # Draw filled brain shape
    def in_brain(x, y):
        dxl = (x - 216) / 110
        dxr = (x - 296) / 110
        dy = (y - 256) / 145
        return dxl**2 + dy**2 <= 1 or dxr**2 + dy**2 <= 1
    
    def set_px(x, y, color):
        if 0 <= x < size and 0 <= y < size:
            idx = (y * size + x) * 4
            pixels[idx], pixels[idx+1], pixels[idx+2], pixels[idx+3] = color
    
    # Fill brain
    for y in range(100, 420):
        for x in range(80, 440):
            if in_brain(x, y):
                idx = (y * size + x) * 4
                pixels[idx] = int(pixels[idx] * 0.2 + WHITE[0] * 0.8)
                pixels[idx+1] = int(pixels[idx+1] * 0.2 + WHITE[1] * 0.8)
                pixels[idx+2] = int(pixels[idx+2] * 0.2 + WHITE[2] * 0.8)
                pixels[idx+3] = WHITE[3]
    
    # Brain outline
    import math
    for angle in range(0, 360, 2):
        rad = math.radians(angle)
        for dx, dy_off in [(-40, 0), (40, 0)]:
            px = cx + dx + int(110 * math.cos(rad) * 0.85)
            py = cy + int(145 * math.sin(rad))
            for s in range(-3, 4):
                for t in range(-3, 4):
                    if s*s + t*t <= 9:
                        set_px(px+s, py+t, WHITE)
    
    # Neural nodes
    nodes = [(180,200), (200,280), (280,170), (310,310), (256,230), (230,330), (330,230)]
    conns = [(0,1),(0,4),(1,5),(2,3),(2,4),(3,6),(4,5),(4,6),(1,4),(3,5)]
    
    def draw_line(x1,y1,x2,y2,color,thick=4):
        steps = max(abs(x2-x1), abs(y2-y1), 1)
        for i in range(steps+1):
            t = i/steps
            x = int(x1+(x2-x1)*t)
            y = int(y1+(y2-y1)*t)
            for s in range(-thick, thick+1):
                for tt in range(-thick, thick+1):
                    if s*s+tt*tt <= thick*thick:
                        set_px(x+s, y+tt, color)
    
    for i,j in conns:
        draw_line(nodes[i][0], nodes[i][1], nodes[j][0], nodes[j][1], ORANGE, 3)
    
    for x,y in nodes:
        for s in range(-10, 11):
            for t in range(-10, 11):
                if s*s+t*t <= 100:
                    set_px(x+s, y+t, ORANGE)
        for s in range(-5, 6):
            for t in range(-5, 6):
                if s*s+t*t <= 25:
                    set_px(x+s, y+t, CYAN)
    
    # Save
    out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'icons')
    os.makedirs(out_dir, exist_ok=True)
    
    with open(os.path.join(out_dir, 'app_icon.png'), 'wb') as f:
        f.write(create_png(size, size, pixels))
    print(f"Created app_icon.png ({size}x{size})")
    
    # Foreground icon (transparent bg)
    fg = bytearray(size * size * 4)
    for y in range(size):
        for x in range(size):
            if in_brain(x, y):
                idx = (y * size + x) * 4
                fg[idx], fg[idx+1], fg[idx+2], fg[idx+3] = 255, 255, 255, 255
    
    with open(os.path.join(out_dir, 'app_icon_foreground.png'), 'wb') as f:
        f.write(create_png(size, size, fg))
    print(f"Created app_icon_foreground.png ({size}x{size})")

if __name__ == '__main__':
    generate_icon()
