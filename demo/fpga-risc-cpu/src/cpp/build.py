from sys import argv

"""
File format:
data size: 4 byte
data
data crc8-ATM: 1 byte
"""

def compute_crc8_atm(datagram, initial_value = 0xff):
    crc = initial_value
    # Iterate bytes in data
    for byte in datagram:
        # Iterate bits in byte
        for _ in range(0, 8):
            if (crc >> 7) ^ (byte & 0x01):
                crc = ((crc << 1) ^ 0x07) & 0xFF
            else:
                crc = (crc << 1) & 0xFF
            # Shift to next bit
            byte = byte >> 1
    return crc

binfile = argv[1]
with open(binfile, "rb") as f:
    bindata = f.read()
size = len(bindata)
with open(argv[2], 'wb') as f:
    f.write(size.to_bytes(4, 'big'))
    f.write(bindata)
    f.write(compute_crc8_atm(bindata).to_bytes(1, 'big'))