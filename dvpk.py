# -*- coding: utf-8 -*-
"""

WOTB DVPK files utilities
~~~~~~~~~~~~~~~~~~~~~~~~~

"""

import binascii
import io
import os
import struct

DVPK_MARKER = b'DVPK'

try:
    import lz4.block
except ImportError:
    def byte2int(bs):
        return bs[0]

    class CorruptError(Exception):
        pass 
 
    def lz4_uncompress(src, uncompressed_size=None):
        """uncompress a block of lz4 data.
     
        :param bytes src: lz4 compressed data (LZ4 Blocks)
        :param uncompressed_size: unused, for compatibility only
        :returns: uncompressed data
        :rtype: bytearray
        """
        src = io.BytesIO(src)
     
        # if we have the original size, we could pre-allocate the buffer with
        # bytearray(original_size), but then we would have to use indexing
        # instad of .append() and .extend()
        dst = bytearray()
        min_match_len = 4
     
        def get_length(src, length):
            """get the length of a lz4 variable length integer."""
            if length != 0x0f:
                return length
     
            while True:
                read_buf = src.read(1)
                if len(read_buf) != 1:
                    raise CorruptError("EOF at length read")
                len_part = byte2int(read_buf)
     
                length += len_part
     
                if len_part != 0xff:
                    break
     
            return length
     
        while True:
            # decode a block
            read_buf = src.read(1)
            if len(read_buf) == 0:
                raise CorruptError("EOF at reading literal-len")
            token = byte2int(read_buf)
     
            literal_len = get_length(src, (token >> 4) & 0x0f)
     
            # copy the literal to the output buffer
            read_buf = src.read(literal_len)
     
            if len(read_buf) != literal_len:
                raise CorruptError("not literal data")
            dst.extend(read_buf)
     
            read_buf = src.read(2)
            if len(read_buf) == 0:
                if token & 0x0f != 0:
                    raise CorruptError("EOF, but match-len > 0: %u" % (token % 0x0f, ))
                break
     
            if len(read_buf) != 2:
                raise CorruptError("premature EOF")
     
            offset = byte2int([read_buf[0]]) | (byte2int([read_buf[1]]) << 8)
     
            if offset == 0:
                raise CorruptError("offset can't be 0")
     
            match_len = get_length(src, (token >> 0) & 0x0f)
            match_len += min_match_len
     
            # append the sliding window of the previous literals
            for _ in range(match_len):
                dst.append(dst[-offset])
     
        return dst

    __lz4_mode__ = 'pure python'
    
else:
    # lz4.block is found
    __lz4_mode__ = 'python lz4'

    def lz4_uncompress(data, uncompressed_size):
        return lz4.block.decompress(data, uncompressed_size=uncompressed_size)

def crc32(data):
    return (binascii.crc32(data) & 0xffffffff)

def read_file(f, filter=''):
    f.seek(0, os.SEEK_END)
    file_size = f.tell()

    # footer
    FOOTER = '8s8I4s'
    FOOTER_SIZE = struct.calcsize(FOOTER)

    if file_size < FOOTER_SIZE:
        raise ValueError('Input file size is too small: %d' % file_size)

    f.seek(-FOOTER_SIZE, os.SEEK_END)
    data = f.read(FOOTER_SIZE)
    reserved, meta_data_crc32, meta_data_size, info_crc32, num_files, names_size_compressed, names_size_original, files_table_size, files_table_crc32, marker = struct.unpack(FOOTER, data)

    if marker != DVPK_MARKER:
        raise ValueError('Input file footer marker is invalid: %s' % binascii.hexlify(marker))
    
    print('Total files: %d' % (num_files))

    # files table
    f.seek(-(FOOTER_SIZE + files_table_size), os.SEEK_END)
    #print(hex(f.tell()))

    FILE = 'Q6I'
    FILE_SIZE = struct.calcsize(FILE)
    files_table = []
    for i in range(num_files):
        start_position, compressed_size, original_size, compressed_crc32, file_type, original_crc32, meta_index = struct.unpack(FILE, f.read(FILE_SIZE))
        files_table.append((start_position, compressed_size, original_size, compressed_crc32, file_type, original_crc32, meta_index,))

    # names
    names_compressed = f.read(names_size_compressed)
    names_compressed_crc32, = struct.unpack('I', f.read(4))
    if crc32(names_compressed) != names_compressed_crc32:
        raise ValueError('Incorrect crc32 for compressed file names block')
    names = lz4_uncompress(names_compressed, names_size_original)
    names_list = names.decode('ascii').split('\x00')

    for i in range(num_files):
        if i % 100 == 0:
            print('.', end='', flush=True)
        if not names_list[i].startswith(str(filter)):
            continue
        n = 'out/%s' % names_list[i]
        v = files_table[i]
        f.seek(v[0])
        bin = f.read(v[1])
        if crc32(bin) != v[3]:
            print('File %s incorrect compressed crc32' % (names_list[i],))
            continue
        bin_full = None
        if v[4] in (1, 2):
            bin_full = lz4_uncompress(bin, uncompressed_size=v[2])
        elif v[4] == 0:
            bin_full = bin
        else:
            print(names_list[i], v[4])
        if bin_full is not None:
            if crc32(bin_full) != v[5]:
                print('File %s incorrect uncompressed crc32' % (names_list[i],))
                continue
            os.makedirs(os.path.dirname(n), exist_ok=True)
            with open(n, 'wb') as fo:
                fo.write(bin_full)
 
def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="WOTB DVPK utilities (%s)" % (__lz4_mode__))
    parser.add_argument('input', nargs=1, help='File to be read (.dvpk)')
    parser.add_argument('filter', nargs='?', help="Filter to decode only begin of the path", metavar='filter', default='')

    args = parser.parse_args()
    with open(args.input[0], 'rb') as f:
        read_file(f, filter=args.filter)

if __name__ == '__main__':
    main()
