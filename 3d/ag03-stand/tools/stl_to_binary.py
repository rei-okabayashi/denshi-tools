"""ASCII STL をバイナリ STL に変換する（同じファイル名で上書き）。ビューアの読み込みを軽くするため。"""
import struct, sys
for path in sys.argv[1:]:
    with open(path, 'rb') as f:
        head = f.read(5)
    if head != b'solid':
        continue                                     # すでにバイナリ
    tris, normal, verts = [], None, []
    for line in open(path):
        w = line.split()
        if not w: continue
        if w[0] == 'facet': normal = tuple(map(float, w[2:5])); verts = []
        elif w[0] == 'vertex': verts.append(tuple(map(float, w[1:4])))
        elif w[0] == 'endfacet': tris.append((normal, verts))
    with open(path, 'wb') as f:
        f.write(b'binary STL from ag03_stand'.ljust(80, b' '))
        f.write(struct.pack('<I', len(tris)))
        for n, v in tris:
            f.write(struct.pack('<12fH', *n, *v[0], *v[1], *v[2], 0))
    print(path, len(tris), 'triangles')
