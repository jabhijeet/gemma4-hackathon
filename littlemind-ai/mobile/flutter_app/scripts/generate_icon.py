"""
Fast icon generator for LittleMind AI - creates a 512x512 PNG icon
"""
import struct
import zlib
import math
import os

def create_icon():
    size = 512
    pixels = [[0, 0, 0, 255] for _ in range(size * size)]
    
    def set_pixel(x, y, color):
        if 0 <= x < size and 0 <= y < size:
            idx = y * size + x
            pixels[idx] = list(color)
    
    def draw_filled_circle(cx, cy, r, color):
        for y in range(max(0, cy - r), min(size, cy + r + 1)):
            for x in range(max(0, cx - r), min(size, cx + r + 1)):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r ** 2:
                    set_pixel(x, y, color)
    
    def draw_line(x1, y1, x2, y2, color, thickness=4):
        steps = max(abs(x2 - x1), abs(y2 - y1))
        if steps == 0:
            return
        for i in range(steps + 1):
            t = i / steps
            x = int(x1 + (x2 - x1) * t)
            y = int(y1 + (y2 - y1) * t)
            draw_filled_circle(x, y, thickness, color)
    
    # Background gradient (blue)
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)
            r = int(40 + 30 * t)
            g = int(90 + 50 * t)
            b = int(170 + 50 * t)
            set_pixel(x, y, (r, g, b, 255))
    
    cx, cy = size // 2, size // 2
    
    # Draw brain shape - two hemispheres
    for angle in range(0, 360, 3):
        rad = math.radians(angle)
        # Left hemisphere
        lx = cx - 40 + int(140 * math.cos(rad) * 0.85)
        ly = cy + int(160 * math.sin(rad))
        draw_filled_circle(lx, ly, 5, (255, 255, 255, 255))
        # Right hemisphere
        rx = cx + 40 + int(140 * math.cos(rad) * 0.85)
        ry = cy + int(160 * math.sin(rad))
        draw_filled_circle(rx, ry, 5, (255, 255, 255, 255))
    
    # Fill brain interior
    for y in range(cy - 170, cy + 170):
        for x in range(cx - 200, cx + 200):
            dx_l = (x - (cx - 40)) / 120
            dx_r = (x - (cx + 40)) / 120
            dy = (y - cy) / 160
            if dx_l**2 + dy**2 <= 1 or dx_r**2 + dy**2 <= 1:
                idx = y * size + x
                pixels[idx][0] = int(pixels[idx][0] * 0.25 + 255 * 0.75)
                pixels[idx][1] = int(pixels[idx][1] * 0.25 + 255 * 0.75)
                pixels[idx][2] = int(pixels[idx][2] * 0.25 + 255 * 0.75)
    
    # Neural network nodes and connections
    nodes = [
        (cx - 75, cy - 50), (cx - 50, cy + 25), (cx + 25, cy - 75),
        (cx + 50, cy + 50), (cx, cy - 25), (cx - 25, cy + 75), (cx + 75, cy - 25)
    ]
    
    connections = [(0,1), (0,4), (1,5), (2,3), (2,4), (3,6), (4,5), (4,6), (1,4), (3,5)]
    
    for i, j in connections:
        draw_line(nodes[i][0], nodes[i][1], nodes[j][0], nodes[j][1], (255, 180, 80, 255), 3)
    
    for x, y in nodes:
        draw_filled_circle(x, y, 10, (255, 180, 80, 255))
        draw_filled_circle(x, y, 5, (80, 180, 255, 255))
    
    # Create PNG
    def make_png(pixels, size):
        def chunk(ctype, data):
            c = ctype + data
            return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
        
        raw = b''
        for y in range(size):
            raw += b'\x00'
            for x in range(size):
                idx = y * size + x
                raw += bytes(pixels[idx])
        
        return (b'\x89PNG\r\n\x1a\n' +
                chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0)) +
                chunk(b'IDAT', zlib.compress(raw)) +
                chunk(b'IEND', b''))
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(script_dir, '..', 'assets', 'icons')
    os.makedirs(output_dir, exist_ok=True)
    
    with open(os.path.join(output_dir, 'app_icon.png'), 'wb') as f:
        f.write(make_png(pixels, size))
    print("Created app_icon.png")
    
    # Create foreground (transparent background)
    fg = [[0, 0, 0, 0] for _ in range(size * size)]
    for y in range(size):
        for x in range(size):
            idx = y * size + x
            dx_l = (x - (cx - 40)) / 120
            dx_r = (x - (cx + 40)) / 120
            dy = (y - cy) / 160
            if dx_l**2 + dy**2 <= 1 or dx_r**2 + dy**2 <= 1:
                fg[idx] = [255, 255, 255, 255]
    
    with open(os.path.join(output_dir, 'app_icon_foreground.png'), 'wb') as f:
        f.write(make_png(fg, size))
    print("Created app_icon_foreground.png")

if __name__ == '__main__':
    create_icon()
