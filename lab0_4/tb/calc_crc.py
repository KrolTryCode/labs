import sys
import subprocess

try:
    import crcmod
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "crcmod"])
    import crcmod

def main():
    hex_string = sys.argv[1]    
    data = bytes.fromhex(hex_string)
    crc16 = crcmod.mkCrcFun(0x18005, initCrc=0xFFFF, rev=True)
    result = crc16(data)
    print(f"{result:04x}")

if __name__ == "__main__":
    main()