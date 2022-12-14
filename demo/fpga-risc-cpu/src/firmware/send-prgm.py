import serial
import threading
import time

from sys import argv

binfile = argv[1]
with open(binfile, "rb") as f:
    bindata = f.read()
size = bytearray(len(bindata).to_bytes(4, 'big'))

def compute_crc8_atm(datagram, initial_value=0xff):
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


class ReadThread(threading.Thread):
    def __init__(self, ser: serial.Serial):
        threading.Thread.__init__(self)
        self.ser = ser
        self.running = True

    def run(self):
        while self.running:
            print(ser.readline())

crc = compute_crc8_atm(bindata)
with serial.Serial('/dev/ttyUSB1', 115200, timeout=1) as ser:
    res = b''
    print('[SENDER] send {} bytes'.format(int.from_bytes(size, 'big')))
    ser.write(size)
    ser.flush()
    time.sleep(0.5)

    res = b''
    while b'Waiting for user program...\n' not in res:
        res = ser.readline()
        print(res)
    rt = ReadThread(ser)
    rt.start()

    # Write program
    print('[SENDER] Write program data')
    ser.write(bindata)
    print('[SENDER] write CRC {}'.format(crc))
    # Write CRC
    ser.write(crc.to_bytes(1, 'big'))
    time.sleep(5)

    rt.running = False
    rt.join()
