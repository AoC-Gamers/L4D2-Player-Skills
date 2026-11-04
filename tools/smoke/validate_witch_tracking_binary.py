#!/usr/bin/env python3
"""Offline check of smoke gamedata against the actual Linux x86 server ELF."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct

NAMES = ('WitchAttack::GetVictim', 'Action<Infected>::InvokeOnStart')


def load_config(text):
    # SourceMod's runtime parser did not expose the inline offset definition.
    # Require the canonical multiline form, rather than accepting a misleading
    # regex match for an offset the runtime would return as -1.
    offset = re.search(r'^\s*"ActorAssignmentInstruction"\s*\n\s*\{\s*\n\s*"linux"\s+"(\d+)"\s*\n\s*\}', text, re.M)
    if offset is None:
        raise ValueError('ActorAssignmentInstruction must use multiline SourceMod gamedata syntax')
    instruction = int(offset[1])
    if not 0 <= instruction <= 4096:
        raise ValueError('actor assignment instruction offset out of range')
    symbols = {}
    for name in NAMES:
        block = re.search(r'"'+re.escape(name)+r'"\s*\{([^{}]*)\}', text)
        if block is None or not re.search(r'"library"\s+"server"', block[1]):
            raise ValueError('missing server signature: '+name)
        symbol = re.search(r'"linux"\s+"@([^"\s]+)"', block[1])
        if symbol is None:
            raise ValueError('missing Linux symbol: '+name)
        symbols[name] = symbol[1]
    return symbols, instruction


def validate_binary(binary, gamedata):
    symbols, instruction = load_config(gamedata.read_text())
    data = binary.read_bytes()
    if data[:6] != b'\x7fELF\x01\x01' or len(data)<52:
        raise ValueError('requires a little-endian ELF32 Linux server binary')
    if struct.unpack_from('<H', data, 18)[0] != 3:
        raise ValueError('requires x86 machine type')
    shoff = struct.unpack_from('<I',data,32)[0]
    entsize, count = struct.unpack_from('<HH',data,46)
    if entsize != 40 or shoff+entsize*count>len(data):
        raise ValueError('invalid ELF32 section table')
    sections=[struct.unpack_from('<10I',data,shoff+i*entsize) for i in range(count)]
    found={}
    for section in sections:
        if section[1] != 2: continue  # SHT_SYMTAB, includes hidden/local symbols.
        strings=sections[section[6]]
        strings_data=data[strings[4]:strings[4]+strings[5]]
        for position in range(section[4], section[4]+section[5], section[9]):
            name, address, size, info, _, index=struct.unpack_from('<IIIBBH',data,position)
            end=strings_data.find(b'\0',name)
            symbol=strings_data[name:end].decode('ascii',errors='replace')
            if symbol not in symbols.values() or info&15 != 2 or index>=count: continue
            target=sections[index]
            file_offset=target[4]+address-target[3]
            if not target[3]<=address<target[3]+target[5] or file_offset+size>len(data):
                raise ValueError('symbol outside file-backed section: '+symbol)
            found[symbol]=(address,file_offset,size)
    for symbol in symbols.values():
        if symbol not in found: raise ValueError('symbol absent from actual binary: '+symbol)
    va,vo,vs=found[symbols[NAMES[0]]]
    aa,ao,asz=found[symbols[NAMES[1]]]
    if vs<9 or data[vo:vo+9] != bytes.fromhex('55 89 e5 8b 55 08 8b 42 38'):
        raise ValueError('unsupported GetVictim entry/ABI')
    guard=data[ao+instruction:ao+instruction+3]
    if instruction+3>asz or guard != bytes.fromhex('89 5f 1c'):
        raise ValueError('actor assignment guard failed')
    return {'valid':True,'binary_sha256':hashlib.sha256(data).hexdigest(),
            'gamedata_sha256':hashlib.sha256(gamedata.read_bytes()).hexdigest(),
            'victim_symbol':symbols[NAMES[0]],'victim_relative_address':hex(va),
            'actor_symbol':symbols[NAMES[1]],'actor_relative_address':hex(aa),
            'actor_assignment_instruction':instruction,'actor_assignment_bytes':guard.hex(' '),
            'actor_field_offset':28,'scope':'Offline ELF and gamedata validation; not runtime detour/gameplay acceptance'}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('binary',type=Path)
    parser.add_argument('--gamedata',type=Path,default=Path(__file__).with_name('gamedata')/'l4d2_skills_smoke_witch.txt')
    args=parser.parse_args()
    try: report=validate_binary(args.binary,args.gamedata)
    except (OSError,ValueError,IndexError,struct.error) as exc:
        print(json.dumps({'valid':False,'error':str(exc)},indent=2));return 1
    print(json.dumps(report,indent=2));return 0


if __name__=='__main__':raise SystemExit(main())
