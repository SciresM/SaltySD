import struct, sys, zlib, os

def crc(filename):
    return zlib.crc32(filename.encode('latin-1')) & 0xffffffff
    
if len(sys.argv) < 2:
    print("Usage: python2 cachegen.py <path to saltysd/smash/>")
    quit()
    
files = []
sys.argv[1] = sys.argv[1].replace('\\', '/')

for root, directories, filenames in os.walk(sys.argv[1]):
     for filename in filenames: 
             name = os.path.join(root,filename).replace(os.path.join(sys.argv[1], ''), "").lower().replace('\\', '/')
             print(name.lower() + " " + hex(crc(name.lower())))
             files.append(name.lower())

#print filenames
filecrcs = []
f = open(os.path.join(sys.argv[1], '') + "cache.bin", "wb")
f.write(struct.pack('<L', len(files))) 

for file in files:
    f.write(struct.pack('<L', crc(file)))

f.close()   
print("Complete!")