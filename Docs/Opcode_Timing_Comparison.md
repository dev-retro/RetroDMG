| Opcode | Mnemonic         | Your T-Cycle | Pandocs T-Cycle | Match? | Notes (method called)                |
|--------|------------------|--------------|-----------------|--------|--------------------------------------|
| 0x00   | NOP              | 4            | 4               | Yes    | Direct assignment                    |
| 0x01   | LD BC,d16        | 12           | 12              | Yes    | loadFromMemory(to: .BC) assigns 12   |
| 0x02   | LD (BC),A        | 8            | 8               | Yes    | load(indirect: .BC, register: .A)    |
| 0x03   | INC BC           | 8            | 8               | Yes    | increment(register: .BC) assigns 8   |
| 0x04   | INC B            | 4            | 4               | Yes    | increment(register: .B) assigns 4    |
| 0x05   | DEC B            | 4            | 4               | Yes    | decrement(register: .B) assigns 4    |
| 0x06   | LD B,d8          | 8            | 8               | Yes    | load(from: .PC, to: .B) assigns 8    |
| 0x07   | RLCA             | 4            | 4               | Yes    | rotateLeftCarry(register: .A)        |
| 0x08   | LD (a16),SP      | 20           | 20              | Yes    | loadToMemory(from: .SP) assigns 20   |
| 0x09   | ADD HL,BC        | 8            | 8               | Yes    | add(register: .BC) assigns 8         |
| 0x0A   | LD A,(BC)        | 8            | 8               | Yes    | load(register: .A, indirect: .BC)    |
| 0x0B   | DEC BC           | 8            | 8               | Yes    | decrement(register: .BC) assigns 8   |
| 0x0C   | INC C            | 4            | 4               | Yes    | increment(register: .C) assigns 4    |
| 0x0D   | DEC C            | 4            | 4               | Yes    | decrement(register: .C) assigns 4    |
| 0x0E   | LD C,d8          | 8            | 8               | Yes    | load(from: .PC, to: .C) assigns 8    |
| 0x0F   | RRCA             | 4            | 4               | Yes    | rotateRightCarry(register: .A)       |
| 0x10   | STOP             | 4            | 4               | Yes    | (if implemented)                     |
| 0x11   | LD DE,d16        | 12           | 12              | Yes    | loadFromMemory(to: .DE) assigns 12   |
| 0x12   | LD (DE),A        | 8            | 8               | Yes    | load(indirect: .DE, register: .A)    |
| 0x13   | INC DE           | 8            | 8               | Yes    | increment(register: .DE) assigns 8   |
| 0x14   | INC D            | 4            | 4               | Yes    | increment(register: .D) assigns 4    |
| 0x15   | DEC D            | 4            | 4               | Yes    | decrement(register: .D) assigns 4    |
| 0x16   | LD D,d8          | 8            | 8               | Yes    | load(from: .PC, to: .D) assigns 8    |
| 0x17   | RLA              | 4            | 4               | Yes    | rotateLeft(register: .A)             |
| 0x18   | JR r8            | 12           | 12              | Yes    | jump(type: .memorySigned8Bit)        |
| 0x19   | ADD HL,DE        | 8            | 8               | Yes    | add(register: .DE) assigns 8         |
| 0x1A   | LD A,(DE)        | 8            | 8               | Yes    | load(register: .A, indirect: .DE)    |
| 0x1B   | DEC DE           | 8            | 8               | Yes    | decrement(register: .DE) assigns 8   |
| 0x1C   | INC E            | 4            | 4               | Yes    | increment(register: .E) assigns 4    |
| 0x1D   | DEC E            | 4            | 4               | Yes    | decrement(register: .E) assigns 4    |
| 0x1E   | LD E,d8          | 8            | 8               | Yes    | load(from: .PC, to: .E) assigns 8    |
| 0x1F   | RRA              | 4            | 4               | Yes    | rotateRight(register: .A)            |
| 0x20   | JR NZ,r8         | 8/12         | 8/12            | Yes    | jumpIfNot(type: .memorySigned8Bit, flag: .Zero) |
| 0x21   | LD HL,d16        | 12           | 12              | Yes    | loadFromMemory(to: .HL) assigns 12   |
| 0x22   | LD (HL+),A       | 8            | 8               | Yes    | load(indirect: .HL, register: .A) + increment(register: .HL, partOfOtherOpCode: true) |
| 0x23   | INC HL           | 8            | 8               | Yes    | increment(register: .HL) assigns 8   |
| 0x24   | INC H            | 4            | 4               | Yes    | increment(register: .H) assigns 4    |
| 0x25   | DEC H            | 4            | 4               | Yes    | decrement(register: .H) assigns 4    |
| 0x26   | LD H,d8          | 8            | 8               | Yes    | load(from: .PC, to: .H) assigns 8    |
| 0x27   | DAA              | 4            | 4               | Yes    | daa()                                |
| 0x28   | JR Z,r8          | 8/12         | 8/12            | Yes    | jumpIf(type: .memorySigned8Bit, flag: .Zero) |
| 0x29   | ADD HL,HL        | 8            | 8               | Yes    | add(register: .HL) assigns 8         |
| 0x2A   | LD A,(HL+)       | 8            | 8               | Yes    | load(register: .A, indirect: .HL) + increment(register: .HL, partOfOtherOpCode: true) |
| 0x2B   | DEC HL           | 8            | 8               | Yes    | decrement(register: .HL) assigns 8   |
| 0x2C   | INC L            | 4            | 4               | Yes    | increment(register: .L) assigns 4    |
| 0x2D   | DEC L            | 4            | 4               | Yes    | decrement(register: .L) assigns 4    |
| 0x2E   | LD L,d8          | 8            | 8               | Yes    | load(from: .PC, to: .L) assigns 8    |
| 0x2F   | CPL              | 4            | 4               | Yes    | cpl()                                |
| 0x30   | JR NC,r8         | 8/12         | 8/12            | Yes    | jumpIfNot(type: .memorySigned8Bit, flag: .Carry) |
| 0x31   | LD SP,d16        | 12           | 12              | Yes    | loadFromMemory(to: .SP) assigns 12   |
| 0x32   | LD (HL-),A       | 8            | 8               | Yes    | load(indirect: .HL, register: .A) + decrement(register: .HL, partOfOtherOpCode: true) |
| 0x33   | INC SP           | 8            | 8               | Yes    | increment(register: .SP) assigns 8   |
| 0x34   | INC (HL)         | 12           | 12              | Yes    | increment(indirect: .HL) assigns 12  |
| 0x35   | DEC (HL)         | 12           | 12              | Yes    | decrement(indirect: .HL) assigns 12  |
| 0x36   | LD (HL),d8       | 12           | 12              | Yes    | load(indirect .HL) assigns 12        |
| 0x37   | SCF              | 4            | 4               | Yes    | setCarryFlag()                       |
| 0x38   | JR C,r8          | 8/12         | 8/12            | Yes    | jumpIf(type: .memorySigned8Bit, flag: .Carry) |
| 0x39   | ADD HL,SP        | 8            | 8               | Yes    | add(register: .SP) assigns 8         |
| 0x3A   | LD A,(HL-)       | 8            | 8               | Yes    | load(register: .A, indirect: .HL) + decrement(register: .HL, partOfOtherOpCode: true) |
| 0x3B   | DEC SP           | 8            | 8               | Yes    | decrement(register: .SP) assigns 8   |
| 0x3C   | INC A            | 4            | 4               | Yes    | increment(register: .A) assigns 4    |
| 0x3D   | DEC A            | 4            | 4               | Yes    | decrement(register: .A) assigns 4    |
| 0x3E   | LD A,d8          | 8            | 8               | Yes    | load(from: .PC, to: .A) assigns 8    |
| 0x3F   | CCF              | 4            | 4               | Yes    | ccf()                                |
| 0x40   | LD B,B            | 4            | 4               | Yes    | load(from: .B, to: .B) assigns 4     |
| 0x41   | LD B,C            | 4            | 4               | Yes    | load(from: .C, to: .B) assigns 4     |
| 0x42   | LD B,D            | 4            | 4               | Yes    | load(from: .D, to: .B) assigns 4     |
| 0x43   | LD B,E            | 4            | 4               | Yes    | load(from: .E, to: .B) assigns 4     |
| 0x44   | LD B,H            | 4            | 4               | Yes    | load(from: .H, to: .B) assigns 4     |
| 0x45   | LD B,L            | 4            | 4               | Yes    | load(from: .L, to: .B) assigns 4     |
| 0x46   | LD B,(HL)         | 8            | 8               | Yes    | load(register: .B, indirect: .HL) assigns 8 |
| 0x47   | LD B,A            | 4            | 4               | Yes    | load(from: .A, to: .B) assigns 4     |
| 0x48   | LD C,B            | 4            | 4               | Yes    | load(from: .B, to: .C) assigns 4     |
| 0x49   | LD C,C            | 4            | 4               | Yes    | load(from: .C, to: .C) assigns 4     |
| 0x4A   | LD C,D            | 4            | 4               | Yes    | load(from: .D, to: .C) assigns 4     |
| 0x4B   | LD C,E            | 4            | 4               | Yes    | load(from: .E, to: .C) assigns 4     |
| 0x4C   | LD C,H            | 4            | 4               | Yes    | load(from: .H, to: .C) assigns 4     |
| 0x4D   | LD C,L            | 4            | 4               | Yes    | load(from: .L, to: .C) assigns 4     |
| 0x4E   | LD C,(HL)         | 8            | 8               | Yes    | load(register: .C, indirect: .HL) assigns 8 |
| 0x4F   | LD C,A            | 4            | 4               | Yes    | load(from: .A, to: .C) assigns 4     |
| 0x50   | LD D,B            | 4            | 4               | Yes    | load(from: .B, to: .D) assigns 4     |
| 0x51   | LD D,C            | 4            | 4               | Yes    | load(from: .C, to: .D) assigns 4     |
| 0x52   | LD D,D            | 4            | 4               | Yes    | load(from: .D, to: .D) assigns 4     |
| 0x53   | LD D,E            | 4            | 4               | Yes    | load(from: .E, to: .D) assigns 4     |
| 0x54   | LD D,H            | 4            | 4               | Yes    | load(from: .H, to: .D) assigns 4     |
| 0x55   | LD D,L            | 4            | 4               | Yes    | load(from: .L, to: .D) assigns 4     |
| 0x56   | LD D,(HL)         | 8            | 8               | Yes    | load(register: .D, indirect: .HL) assigns 8 |
| 0x57   | LD D,A            | 4            | 4               | Yes    | load(from: .A, to: .D) assigns 4     |
| 0x58   | LD E,B            | 4            | 4               | Yes    | load(from: .B, to: .E) assigns 4     |
| 0x59   | LD E,C            | 4            | 4               | Yes    | load(from: .C, to: .E) assigns 4     |
| 0x5A   | LD E,D            | 4            | 4               | Yes    | load(from: .D, to: .E) assigns 4     |
| 0x5B   | LD E,E            | 4            | 4               | Yes    | load(from: .E, to: .E) assigns 4     |
| 0x5C   | LD E,H            | 4            | 4               | Yes    | load(from: .H, to: .E) assigns 4     |
| 0x5D   | LD E,L            | 4            | 4               | Yes    | load(from: .L, to: .E) assigns 4     |
| 0x5E   | LD E,(HL)         | 8            | 8               | Yes    | load(register: .E, indirect: .HL) assigns 8 |
| 0x5F   | LD E,A            | 4            | 4               | Yes    | load(from: .A, to: .E) assigns 4     |
| 0x60   | LD H,B            | 4            | 4               | Yes    | load(from: .B, to: .H) assigns 4     |
| 0x61   | LD H,C            | 4            | 4               | Yes    | load(from: .C, to: .H) assigns 4     |
| 0x62   | LD H,D            | 4            | 4               | Yes    | load(from: .D, to: .H) assigns 4     |
| 0x63   | LD H,E            | 4            | 4               | Yes    | load(from: .E, to: .H) assigns 4     |
| 0x64   | LD H,H            | 4            | 4               | Yes    | load(from: .H, to: .H) assigns 4     |
| 0x65   | LD H,L            | 4            | 4               | Yes    | load(from: .L, to: .H) assigns 4     |
| 0x66   | LD H,(HL)         | 8            | 8               | Yes    | load(register: .H, indirect: .HL) assigns 8 |
| 0x67   | LD H,A            | 4            | 4               | Yes    | load(from: .A, to: .H) assigns 4     |
| 0x68   | LD L,B            | 4            | 4               | Yes    | load(from: .B, to: .L) assigns 4     |
| 0x69   | LD L,C            | 4            | 4               | Yes    | load(from: .C, to: .L) assigns 4     |
| 0x6A   | LD L,D            | 4            | 4               | Yes    | load(from: .D, to: .L) assigns 4     |
| 0x6B   | LD L,E            | 4            | 4               | Yes    | load(from: .E, to: .L) assigns 4     |
| 0x6C   | LD L,H            | 4            | 4               | Yes    | load(from: .H, to: .L) assigns 4     |
| 0x6D   | LD L,L            | 4            | 4               | Yes    | load(from: .L, to: .L) assigns 4     |
| 0x6E   | LD L,(HL)         | 8            | 8               | Yes    | load(register: .L, indirect: .HL) assigns 8 |
| 0x6F   | LD L,A            | 4            | 4               | Yes    | load(from: .A, to: .L) assigns 4     |
| 0x70   | LD (HL),B         | 8            | 8               | Yes    | load(indirect: .HL, register: .B) assigns 8 |
| 0x71   | LD (HL),C         | 8            | 8               | Yes    | load(indirect: .HL, register: .C) assigns 8 |
| 0x72   | LD (HL),D         | 8            | 8               | Yes    | load(indirect: .HL, register: .D) assigns 8 |
| 0x73   | LD (HL),E         | 8            | 8               | Yes    | load(indirect: .HL, register: .E) assigns 8 |
| 0x74   | LD (HL),H         | 8            | 8               | Yes    | load(indirect: .HL, register: .H) assigns 8 |
| 0x75   | LD (HL),L         | 8            | 8               | Yes    | load(indirect: .HL, register: .L) assigns 8 |
| 0x76   | HALT              | 4            | 4               | Yes    | halt()                               |
| 0x77   | LD (HL),A         | 8            | 8               | Yes    | load(indirect: .HL, register: .A) assigns 8 |
| 0x78   | LD A,B            | 4            | 4               | Yes    | load(from: .B, to: .A) assigns 4     |
| 0x79   | LD A,C            | 4            | 4               | Yes    | load(from: .C, to: .A) assigns 4     |
| 0x7A   | LD A,D            | 4            | 4               | Yes    | load(from: .D, to: .A) assigns 4     |
| 0x7B   | LD A,E            | 4            | 4               | Yes    | load(from: .E, to: .A) assigns 4     |
| 0x7C   | LD A,H            | 4            | 4               | Yes    | load(from: .H, to: .A) assigns 4     |
| 0x7D   | LD A,L            | 4            | 4               | Yes    | load(from: .L, to: .A) assigns 4     |
| 0x7E   | LD A,(HL)         | 8            | 8               | Yes    | load(register: .A, indirect: .HL) assigns 8 |
| 0x7F   | LD A,A            | 4            | 4               | Yes    | load(from: .A, to: .A) assigns 4     |
| 0x80   | ADD A,B           | 4            | 4               | Yes    | add(register: .B) assigns 4          |
| 0x81   | ADD A,C           | 4            | 4               | Yes    | add(register: .C) assigns 4          |
| 0x82   | ADD A,D           | 4            | 4               | Yes    | add(register: .D) assigns 4          |
| 0x83   | ADD A,E           | 4            | 4               | Yes    | add(register: .E) assigns 4          |
| 0x84   | ADD A,H           | 4            | 4               | Yes    | add(register: .H) assigns 4          |
| 0x85   | ADD A,L           | 4            | 4               | Yes    | add(register: .L) assigns 4          |
| 0x86   | ADD A,(HL)        | 8            | 8               | Yes    | add(indirect: .HL) assigns 8         |
| 0x87   | ADD A,A           | 4            | 4               | Yes    | add(register: .A) assigns 4          |
| 0x88   | ADC A,B           | 4            | 4               | Yes    | adc(register: .B) assigns 4          |
| 0x89   | ADC A,C           | 4            | 4               | Yes    | adc(register: .C) assigns 4          |
| 0x8A   | ADC A,D           | 4            | 4               | Yes    | adc(register: .D) assigns 4          |
| 0x8B   | ADC A,E           | 4            | 4               | Yes    | adc(register: .E) assigns 4          |
| 0x8C   | ADC A,H           | 4            | 4               | Yes    | adc(register: .H) assigns 4          |
| 0x8D   | ADC A,L           | 4            | 4               | Yes    | adc(register: .L) assigns 4          |
| 0x8E   | ADC A,(HL)        | 8            | 8               | Yes    | adc(indirect: .HL) assigns 8         |
| 0x8F   | ADC A,A           | 4            | 4               | Yes    | adc(register: .A) assigns 4          |
| 0x90   | SUB B             | 4            | 4               | Yes    | sub(register: .B) assigns 4          |
| 0x91   | SUB C             | 4            | 4               | Yes    | sub(register: .C) assigns 4          |
| 0x92   | SUB D             | 4            | 4               | Yes    | sub(register: .D) assigns 4          |
| 0x93   | SUB E             | 4            | 4               | Yes    | sub(register: .E) assigns 4          |
| 0x94   | SUB H             | 4            | 4               | Yes    | sub(register: .H) assigns 4          |
| 0x95   | SUB L             | 4            | 4               | Yes    | sub(register: .L) assigns 4          |
| 0x96   | SUB (HL)          | 8            | 8               | Yes    | sub(indirect: .HL) assigns 8         |
| 0x97   | SUB A             | 4            | 4               | Yes    | sub(register: .A) assigns 4          |
| 0x98   | SBC A,B           | 4            | 4               | Yes    | sbc(register: .B) assigns 4          |
| 0x99   | SBC A,C           | 4            | 4               | Yes    | sbc(register: .C) assigns 4          |
| 0x9A   | SBC A,D           | 4            | 4               | Yes    | sbc(register: .D) assigns 4          |
| 0x9B   | SBC A,E           | 4            | 4               | Yes    | sbc(register: .E) assigns 4          |
| 0x9C   | SBC A,H           | 4            | 4               | Yes    | sbc(register: .H) assigns 4          |
| 0x9D   | SBC A,L           | 4            | 4               | Yes    | sbc(register: .L) assigns 4          |
| 0x9E   | SBC A,(HL)        | 8            | 8               | Yes    | sbc(indirect: .HL) assigns 8         |
| 0x9F   | SBC A,A           | 4            | 4               | Yes    | sbc(register: .A) assigns 4          |
| 0xA0   | AND B             | 4            | 4               | Yes    | and(register: .B) assigns 4          |
| 0xA1   | AND C             | 4            | 4               | Yes    | and(register: .C) assigns 4          |
| 0xA2   | AND D             | 4            | 4               | Yes    | and(register: .D) assigns 4          |
| 0xA3   | AND E             | 4            | 4               | Yes    | and(register: .E) assigns 4          |
| 0xA4   | AND H             | 4            | 4               | Yes    | and(register: .H) assigns 4          |
| 0xA5   | AND L             | 4            | 4               | Yes    | and(register: .L) assigns 4          |
| 0xA6   | AND (HL)          | 8            | 8               | Yes    | and(indirect: .HL) assigns 8         |
| 0xA7   | AND A             | 4            | 4               | Yes    | and(register: .A) assigns 4          |
| 0xA8   | XOR B             | 4            | 4               | Yes    | xor(register: .B) assigns 4          |
| 0xA9   | XOR C             | 4            | 4               | Yes    | xor(register: .C) assigns 4          |
| 0xAA   | XOR D             | 4            | 4               | Yes    | xor(register: .D) assigns 4          |
| 0xAB   | XOR E             | 4            | 4               | Yes    | xor(register: .E) assigns 4          |
| 0xAC   | XOR H             | 4            | 4               | Yes    | xor(register: .H) assigns 4          |
| 0xAD   | XOR L             | 4            | 4               | Yes    | xor(register: .L) assigns 4          |
| 0xAE   | XOR (HL)          | 8            | 8               | Yes    | xor(indirect: .HL) assigns 8         |
| 0xAF   | XOR A             | 4            | 4               | Yes    | xor(register: .A) assigns 4          |
| 0xB0   | OR B              | 4            | 4               | Yes    | or(register: .B) assigns 4           |
| 0xB1   | OR C              | 4            | 4               | Yes    | or(register: .C) assigns 4           |
| 0xB2   | OR D              | 4            | 4               | Yes    | or(register: .D) assigns 4           |
| 0xB3   | OR E              | 4            | 4               | Yes    | or(register: .E) assigns 4           |
| 0xB4   | OR H              | 4            | 4               | Yes    | or(register: .H) assigns 4           |
| 0xB5   | OR L              | 4            | 4               | Yes    | or(register: .L) assigns 4           |
| 0xB6   | OR (HL)           | 8            | 8               | Yes    | or(indirect: .HL) assigns 8          |
| 0xB7   | OR A              | 4            | 4               | Yes    | or(register: .A) assigns 4           |
| 0xB8   | CP B              | 4            | 4               | Yes    | cp(register: .B) assigns 4           |
| 0xB9   | CP C              | 4            | 4               | Yes    | cp(register: .C) assigns 4           |
| 0xBA   | CP D              | 4            | 4               | Yes    | cp(register: .D) assigns 4           |
| 0xBB   | CP E              | 4            | 4               | Yes    | cp(register: .E) assigns 4           |
| 0xBC   | CP H              | 4            | 4               | Yes    | cp(register: .H) assigns 4           |
| 0xBD   | CP L              | 4            | 4               | Yes    | cp(register: .L) assigns 4           |
| 0xBE   | CP (HL)           | 8            | 8               | Yes    | cp(indirect: .HL) assigns 8          |
| 0xBF   | CP A              | 4            | 4               | Yes    | cp(register: .A) assigns 4           |
| 0xC0   | RET NZ            | 8/20         | 8/20            | Yes    | retIfNotSet(flag: .Zero) assigns 8/20|
| 0xC1   | POP BC            | 12           | 12              | Yes    | pop(register: .BC) assigns 12        |
| 0xC2   | JP NZ,a16         | 12/16        | 12/16           | Yes    | jumpIfNot(type: .memoryUnsigned16Bit, flag: .Zero) |
| 0xC3   | JP a16            | 16           | 16              | Yes    | jump(type: .memoryUnsigned16Bit)     |
| 0xC4   | CALL NZ,a16       | 12/24        | 12/24           | Yes    | callIfNot(flag: .Zero) assigns 12/24 |
| 0xC5   | PUSH BC           | 16           | 16              | Yes    | push(register: .BC) assigns 16       |
| 0xC6   | ADD A,d8          | 8            | 8               | Yes    | add() assigns 8                      |
| 0xC7   | RST 00H           | 16           | 16              | Yes    | rst(value: 0x00) assigns 16          |
| 0xC8   | RET Z             | 8/20         | 8/20            | Yes    | retIfSet(flag: .Zero) assigns 8/20   |
| 0xC9   | RET               | 16           | 16              | Yes    | ret() assigns 16                     |
| 0xCA   | JP Z,a16          | 12/16        | 12/16           | Yes    | jumpIf(type: .memoryUnsigned16Bit, flag: .Zero) |
| 0xCB   | PREFIX CB         | -            | -               | -      | extendedOpCodes()                    |
| 0xCC   | CALL Z,a16        | 12/24        | 12/24           | Yes    | callIf(flag: .Zero) assigns 12/24    |
| 0xCD   | CALL a16          | 24           | 24              | Yes    | call() assigns 24                    |
| 0xCE   | ADC A,d8          | 8            | 8               | Yes    | adc() assigns 8                      |
| 0xCF   | RST 08H           | 16           | 16              | Yes    | rst(value: 0x08) assigns 16          |
| 0xD0   | RET NC            | 8/20         | 8/20            | Yes    | retIfNotSet(flag: .Carry) assigns 8/20|
| 0xD1   | POP DE            | 12           | 12              | Yes    | pop(register: .DE) assigns 12        |
| 0xD2   | JP NC,a16         | 12/16        | 12/16           | Yes    | jumpIfNot(type: .memoryUnsigned16Bit, flag: .Carry) |
| 0xD3   | Unused            | -            | -               | -      | unused()                             |
| 0xD4   | CALL NC,a16       | 12/24        | 12/24           | Yes    | callIfNot(flag: .Carry) assigns 12/24|
| 0xD5   | PUSH DE           | 16           | 16              | Yes    | push(register: .DE) assigns 16       |
| 0xD6   | SUB A,d8          | 8            | 8               | Yes    | sub() assigns 8                      |
| 0xD7   | RST 10H           | 16           | 16              | Yes    | rst(value: 0x10) assigns 16          |
| 0xD8   | RET C             | 8/20         | 8/20            | Yes    | retIfSet(flag: .Carry) assigns 8/20  |
| 0xD9   | RETI              | 16           | 16              | Yes    | reti() assigns 16                    |
| 0xDA   | JP C,a16          | 12/16        | 12/16           | Yes    | jumpIf(type: .memoryUnsigned16Bit, flag: .Carry) |
| 0xDB   | Unused            | -            | -               | -      | unused()                             |
| 0xDC   | CALL C,a16        | 12/24        | 12/24           | Yes    | callIf(flag: .Carry) assigns 12/24   |
| 0xDD   | Unused            | -            | -               | -      | unused()                             |
| 0xDE   | SBC A,d8          | 8            | 8               | Yes    | sbc() assigns 8                      |
| 0xDF   | RST 18H           | 16           | 16              | Yes    | rst(value: 0x18) assigns 16          |
| 0xE0   | LDH (a8),A        | 12           | 12              | Yes    | loadToMemory(from: .A, masked: true) assigns 12 |
| 0xE1   | POP HL            | 12           | 12              | Yes    | pop(register: .HL) assigns 12        |
| 0xE2   | LDH (C),A         | 8            | 8               | Yes    | loadToMemory(masked: .C) assigns 8   |
| 0xE3   | Unused            | -            | -               | -      | unused()                             |
| 0xE4   | Unused            | -            | -               | -      | unused()                             |
| 0xE5   | PUSH HL           | 16           | 16              | Yes    | push(register: .HL) assigns 16       |
| 0xE6   | AND A,d8          | 8            | 8               | Yes    | and() assigns 8                      |
| 0xE7   | RST 20H           | 16           | 16              | Yes    | rst(value: 0x20) assigns 16          |
| 0xE8   | ADD SP,s8         | 16           | 16              | Yes    | addSigned(to: .SP, cycles: 16)       |
| 0xE9   | JP HL             | 4            | 4               | Yes    | jump(to: .HL) assigns 4              |
| 0xEA   | LD (a16),A        | 16           | 16              | Yes    | loadToMemory(from: .A) assigns 16    |
| 0xEB   | Unused            | -            | -               | -      | unused()                             |
| 0xEC   | Unused            | -            | -               | -      | unused()                             |
| 0xED   | Unused            | -            | -               | -      | unused()                             |
| 0xEE   | XOR A,d8          | 8            | 8               | Yes    | xor() assigns 8                      |
| 0xEF   | RST 28H           | 16           | 16              | Yes    | rst(value: 0x28) assigns 16          |
| 0xF0   | LDH A,(a8)        | 12           | 12              | Yes    | loadFromMemory(to: .A, masked: true) assigns 12 |
| 0xF1   | POP AF            | 12           | 12              | Yes    | pop(register: .AF) assigns 12        |
| 0xF2   | LDH A,(C)         | 8            | 8               | Yes    | loadFromMemory(to: .A, from: .C) assigns 8 |
| 0xF3   | DI                | 4            | 4               | Yes    | DI()                                 |
| 0xF4   | Unused            | -            | -               | -      | unused()                             |
| 0xF5   | PUSH AF           | 16           | 16              | Yes    | push(register: .AF) assigns 16       |
| 0xF6   | OR A,d8           | 8            | 8               | Yes    | or() assigns 8                       |
| 0xF7   | RST 30H           | 16           | 16              | Yes    | rst(value: 0x30) assigns 16          |
| 0xF8   | LD HL,SP+s8       | 12           | 12              | Yes    | addSigned(to: .HL, cycles: 12)       |
| 0xF9   | LD SP,HL          | 8            | 8               | Yes    | load(from: .HL, to: .SP) assigns 8   |
| 0xFA   | LD A,(a16)        | 16           | 16              | Yes    | loadFromMemory(to: .A, masked: false) assigns 16 |
| 0xFB   | EI                | 4            | 4               | Yes    | EI()                                 |
| 0xFC   | Unused            | -            | -               | -      | unused()                             |
| 0xFD   | Unused            | -            | -               | -      | unused()                             |
| 0xFE   | CP A,d8           | 8            | 8               | Yes    | copy() assigns 8                     |
| 0xFF   | RST 38H           | 16           | 16              | Yes    | rst(value: 0x38) assigns 16          |
|----------------------------------------------------------|
| Extended (CB-prefixed) Opcodes                           |
|----------------------------------------------------------|
| CB00   | RLC B              | 8            | 8               | Yes    | rotateLeftCarry(register: .B) assigns 8   |
| CB01   | RLC C              | 8            | 8               | Yes    | rotateLeftCarry(register: .C) assigns 8   |
| CB02   | RLC D              | 8            | 8               | Yes    | rotateLeftCarry(register: .D) assigns 8   |
| CB03   | RLC E              | 8            | 8               | Yes    | rotateLeftCarry(register: .E) assigns 8   |
| CB04   | RLC H              | 8            | 8               | Yes    | rotateLeftCarry(register: .H) assigns 8   |
| CB05   | RLC L              | 8            | 8               | Yes    | rotateLeftCarry(register: .L) assigns 8   |
| CB06   | RLC (HL)           | 16           | 16              | Yes    | rotateLeftCarry(indirect: .HL) assigns 16 |
| CB07   | RLC A              | 8            | 8               | Yes    | rotateLeftCarry(register: .A) assigns 8   |
| CB08   | RRC B              | 8            | 8               | Yes    | rotateRightCarry(register: .B) assigns 8  |
| CB09   | RRC C              | 8            | 8               | Yes    | rotateRightCarry(register: .C) assigns 8  |
| CB0A   | RRC D              | 8            | 8               | Yes    | rotateRightCarry(register: .D) assigns 8  |
| CB0B   | RRC E              | 8            | 8               | Yes    | rotateRightCarry(register: .E) assigns 8  |
| CB0C   | RRC H              | 8            | 8               | Yes    | rotateRightCarry(register: .H) assigns 8  |
| CB0D   | RRC L              | 8            | 8               | Yes    | rotateRightCarry(register: .L) assigns 8  |
| CB0E   | RRC (HL)           | 16           | 16              | Yes    | rotateRightCarry(indirect: .HL) assigns 16|
| CB0F   | RRC A              | 8            | 8               | Yes    | rotateRightCarry(register: .A) assigns 8  |
| CB10   | RL B               | 8            | 8               | Yes    | rotateLeft(register: .B) assigns 8        |
| CB11   | RL C               | 8            | 8               | Yes    | rotateLeft(register: .C) assigns 8        |
| CB12   | RL D               | 8            | 8               | Yes    | rotateLeft(register: .D) assigns 8        |
| CB13   | RL E               | 8            | 8               | Yes    | rotateLeft(register: .E) assigns 8        |
| CB14   | RL H               | 8            | 8               | Yes    | rotateLeft(register: .H) assigns 8        |
| CB15   | RL L               | 8            | 8               | Yes    | rotateLeft(register: .L) assigns 8        |
| CB16   | RL (HL)            | 16           | 16              | Yes    | rotateLeft(indirect: .HL) assigns 16      |
| CB17   | RL A               | 8            | 8               | Yes    | rotateLeft(register: .A) assigns 8        |
| CB18   | RR B               | 8            | 8               | Yes    | rotateRight(register: .B) assigns 8       |
| CB19   | RR C               | 8            | 8               | Yes    | rotateRight(register: .C) assigns 8       |
| CB1A   | RR D               | 8            | 8               | Yes    | rotateRight(register: .D) assigns 8       |
| CB1B   | RR E               | 8            | 8               | Yes    | rotateRight(register: .E) assigns 8       |
| CB1C   | RR H               | 8            | 8               | Yes    | rotateRight(register: .H) assigns 8       |
| CB1D   | RR L               | 8            | 8               | Yes    | rotateRight(register: .L) assigns 8       |
| CB1E   | RR (HL)            | 16           | 16              | Yes    | rotateRight(indirect: .HL) assigns 16     |
| CB1F   | RR A               | 8            | 8               | Yes    | rotateRight(register: .A) assigns 8       |
| CB20   | SLA B              | 8            | 8               | Yes    | shiftLeftArithmatically(register: .B) assigns 8   |
| CB21   | SLA C              | 8            | 8               | Yes    | shiftLeftArithmatically(register: .C) assigns 8   |
| CB22   | SLA D              | 8            | 8               | Yes    | shiftLeftArithmatically(register: .D) assigns 8   |
| CB23   | SLA E              | 8            | 8               | Yes    | shiftLeftArithmatically(register: .E) assigns 8   |
| CB24   | SLA H              | 8            | 8               | Yes    | shiftLeftArithmatically(register: .H) assigns 8   |
| CB25   | SLA L              | 8            | 8               | Yes    | shiftLeftArithmatically(register: .L) assigns 8   |
| CB26   | SLA (HL)           | 16           | 16              | Yes    | shiftLeftArithmatically(indirect: .HL) assigns 16 |
| CB27   | SLA A              | 8            | 8               | Yes    | shiftLeftArithmatically(register: .A) assigns 8   |
| CB28   | SRA B              | 8            | 8               | Yes    | shiftRightArithmatically(register: .B) assigns 8  |
| CB29   | SRA C              | 8            | 8               | Yes    | shiftRightArithmatically(register: .C) assigns 8  |
| CB2A   | SRA D              | 8            | 8               | Yes    | shiftRightArithmatically(register: .D) assigns 8  |
| CB2B   | SRA E              | 8            | 8               | Yes    | shiftRightArithmatically(register: .E) assigns 8  |
| CB2C   | SRA H              | 8            | 8               | Yes    | shiftRightArithmatically(register: .H) assigns 8  |
| CB2D   | SRA L              | 8            | 8               | Yes    | shiftRightArithmatically(register: .L) assigns 8  |
| CB2E   | SRA (HL)           | 16           | 16              | Yes    | shiftRightArithmatically(indirect: .HL) assigns 16|
| CB2F   | SRA A              | 8            | 8               | Yes    | shiftRightArithmatically(register: .A) assigns 8  |
| CB30   | SWAP B             | 8            | 8               | Yes    | swap(register: .B) assigns 8                     |
| CB31   | SWAP C             | 8            | 8               | Yes    | swap(register: .C) assigns 8                     |
| CB32   | SWAP D             | 8            | 8               | Yes    | swap(register: .D) assigns 8                     |
| CB33   | SWAP E             | 8            | 8               | Yes    | swap(register: .E) assigns 8                     |
| CB34   | SWAP H             | 8            | 8               | Yes    | swap(register: .H) assigns 8                     |
| CB35   | SWAP L             | 8            | 8               | Yes    | swap(register: .L) assigns 8                     |
| CB36   | SWAP (HL)          | 16           | 16              | Yes    | swap(indirect: .HL) assigns 16                   |
| CB37   | SWAP A             | 8            | 8               | Yes    | swap(register: .A) assigns 8                     |
| CB38   | SRL B              | 8            | 8               | Yes    | shiftRightLogically(register: .B) assigns 8      |
| CB39   | SRL C              | 8            | 8               | Yes    | shiftRightLogically(register: .C) assigns 8      |
| CB3A   | SRL D              | 8            | 8               | Yes    | shiftRightLogically(register: .D) assigns 8      |
| CB3B   | SRL E              | 8            | 8               | Yes    | shiftRightLogically(register: .E) assigns 8      |
| CB3C   | SRL H              | 8            | 8               | Yes    | shiftRightLogically(register: .H) assigns 8      |
| CB3D   | SRL L              | 8            | 8               | Yes    | shiftRightLogically(register: .L) assigns 8      |
| CB3E   | SRL (HL)           | 16           | 16              | Yes    | shiftRightLogically(indirect: .HL) assigns 16    |
| CB3F   | SRL A              | 8            | 8               | Yes    | shiftRightLogically(register: .A) assigns 8      |
| CB40   | BIT 0,B             | 8            | 8               | Yes    | bit(register: .B, bit: 0) assigns 8              |
| CB41   | BIT 0,C             | 8            | 8               | Yes    | bit(register: .C, bit: 0) assigns 8              |
| CB42   | BIT 0,D             | 8            | 8               | Yes    | bit(register: .D, bit: 0) assigns 8              |
| CB43   | BIT 0,E             | 8            | 8               | Yes    | bit(register: .E, bit: 0) assigns 8              |
| CB44   | BIT 0,H             | 8            | 8               | Yes    | bit(register: .H, bit: 0) assigns 8              |
| CB45   | BIT 0,L             | 8            | 8               | Yes    | bit(register: .L, bit: 0) assigns 8              |
| CB46   | BIT 0,(HL)          | 12           | 12              | Yes    | bit(indirect: .HL, bit: 0) assigns 12            |
| CB47   | BIT 0,A             | 8            | 8               | Yes    | bit(register: .A, bit: 0) assigns 8              |
| CB48   | BIT 1,B             | 8            | 8               | Yes    | bit(register: .B, bit: 1) assigns 8              |
| CB49   | BIT 1,C             | 8            | 8               | Yes    | bit(register: .C, bit: 1) assigns 8              |
| CB4A   | BIT 1,D             | 8            | 8               | Yes    | bit(register: .D, bit: 1) assigns 8              |
| CB4B   | BIT 1,E             | 8            | 8               | Yes    | bit(register: .E, bit: 1) assigns 8              |
| CB4C   | BIT 1,H             | 8            | 8               | Yes    | bit(register: .H, bit: 1) assigns 8              |
| CB4D   | BIT 1,L             | 8            | 8               | Yes    | bit(register: .L, bit: 1) assigns 8              |
| CB4E   | BIT 1,(HL)          | 12           | 12              | Yes    | bit(indirect: .HL, bit: 1) assigns 12            |
| CB4F   | BIT 1,A             | 8            | 8               | Yes    | bit(register: .A, bit: 1) assigns 8              |
| CB50   | BIT 2,B             | 8            | 8               | Yes    | bit(register: .B, bit: 2) assigns 8              |
| CB51   | BIT 2,C             | 8            | 8               | Yes    | bit(register: .C, bit: 2) assigns 8              |
| CB52   | BIT 2,D             | 8            | 8               | Yes    | bit(register: .D, bit: 2) assigns 8              |
| CB53   | BIT 2,E             | 8            | 8               | Yes    | bit(register: .E, bit: 2) assigns 8              |
| CB54   | BIT 2,H             | 8            | 8               | Yes    | bit(register: .H, bit: 2) assigns 8              |
| CB55   | BIT 2,L             | 8            | 8               | Yes    | bit(register: .L, bit: 2) assigns 8              |
| CB56   | BIT 2,(HL)          | 12           | 12              | Yes    | bit(indirect: .HL, bit: 2) assigns 12            |
| CB57   | BIT 2,A             | 8            | 8               | Yes    | bit(register: .A, bit: 2) assigns 8              |
| CB58   | BIT 3,B             | 8            | 8               | Yes    | bit(register: .B, bit: 3) assigns 8              |
| CB59   | BIT 3,C             | 8            | 8               | Yes    | bit(register: .C, bit: 3) assigns 8              |
| CB5A   | BIT 3,D             | 8            | 8               | Yes    | bit(register: .D, bit: 3) assigns 8              |
| CB5B   | BIT 3,E             | 8            | 8               | Yes    | bit(register: .E, bit: 3) assigns 8              |
| CB5C   | BIT 3,H             | 8            | 8               | Yes    | bit(register: .H, bit: 3) assigns 8              |
| CB5D   | BIT 3,L             | 8            | 8               | Yes    | bit(register: .L, bit: 3) assigns 8              |
| CB5E   | BIT 3,(HL)          | 12           | 12              | Yes    | bit(indirect: .HL, bit: 3) assigns 12            |
| CB5F   | BIT 3,A             | 8            | 8               | Yes    | bit(register: .A, bit: 3) assigns 8              |
| CB60   | BIT 4,B             | 8            | 8               | Yes    | bit(register: .B, bit: 4) assigns 8              |
| CB61   | BIT 4,C             | 8            | 8               | Yes    | bit(register: .C, bit: 4) assigns 8              |
| CB62   | BIT 4,D             | 8            | 8               | Yes    | bit(register: .D, bit: 4) assigns 8              |
| CB63   | BIT 4,E             | 8            | 8               | Yes    | bit(register: .E, bit: 4) assigns 8              |
| CB64   | BIT 4,H             | 8            | 8               | Yes    | bit(register: .H, bit: 4) assigns 8              |
| CB65   | BIT 4,L             | 8            | 8               | Yes    | bit(register: .L, bit: 4) assigns 8              |
| CB66   | BIT 4,(HL)          | 12           | 12              | Yes    | bit(indirect: .HL, bit: 4) assigns 12            |
| CB67   | BIT 4,A             | 8            | 8               | Yes    | bit(register: .A, bit: 4) assigns 8              |
| CB68   | BIT 5,B             | 8            | 8               | Yes    | bit(register: .B, bit: 5) assigns 8              |
| CB69   | BIT 5,C             | 8            | 8               | Yes    | bit(register: .C, bit: 5) assigns 8              |
| CB6A   | BIT 5,D             | 8            | 8               | Yes    | bit(register: .D, bit: 5) assigns 8              |
| CB6B   | BIT 5,E             | 8            | 8               | Yes    | bit(register: .E, bit: 5) assigns 8              |
| CB6C   | BIT 5,H             | 8            | 8               | Yes    | bit(register: .H, bit: 5) assigns 8              |
| CB6D   | BIT 5,L             | 8            | 8               | Yes    | bit(register: .L, bit: 5) assigns 8              |
| CB6E   | BIT 5,(HL)          | 12           | 12              | Yes    | bit(indirect: .HL, bit: 5) assigns 12            |
| CB6F   | BIT 5,A             | 8            | 8               | Yes    | bit(register: .A, bit: 5) assigns 8              |
| CB70   | BIT 6,B             | 8            | 8               | Yes    | bit(register: .B, bit: 6) assigns 8              |
| CB71   | BIT 6,C             | 8            | 8               | Yes    | bit(register: .C, bit: 6) assigns 8              |
| CB72   | BIT 6,D             | 8            | 8               | Yes    | bit(register: .D, bit: 6) assigns 8              |
| CB73   | BIT 6,E             | 8            | 8               | Yes    | bit(register: .E, bit: 6) assigns 8              |
| CB74   | BIT 6,H             | 8            | 8               | Yes    | bit(register: .H, bit: 6) assigns 8              |
| CB75   | BIT 6,L             | 8            | 8               | Yes    | bit(register: .L, bit: 6) assigns 8              |
| CB76   | BIT 6,(HL)          | 12           | 12              | Yes    | bit(indirect: .HL, bit: 6) assigns 12            |
| CB77   | BIT 6,A             | 8            | 8               | Yes    | bit(register: .A, bit: 6) assigns 8              |
| CB78   | BIT 7,B             | 8            | 8               | Yes    | bit(register: .B, bit: 7) assigns 8              |
| CB79   | BIT 7,C             | 8            | 8               | Yes    | bit(register: .C, bit: 7) assigns 8              |
| CB7A   | BIT 7,D             | 8            | 8               | Yes    | bit(register: .D, bit: 7) assigns 8              |
| CB7B   | BIT 7,E             | 8            | 8               | Yes    | bit(register: .E, bit: 7) assigns 8              |
| CB7C   | BIT 7,H             | 8            | 8               | Yes    | bit(register: .H, bit: 7) assigns 8              |
| CB7D   | BIT 7,L             | 8            | 8               | Yes    | bit(register: .L, bit: 7) assigns 8              |
| CB7E   | BIT 7,(HL)          | 12           | 12              | Yes    | bit(indirect: .HL, bit: 7) assigns 12            |
| CB7F   | BIT 7,A             | 8            | 8               | Yes    | bit(register: .A, bit: 7) assigns 8              |
| CB80   | RES 0,B             | 8            | 8               | Yes    | set(bit: 0, register: .B, value: false) assigns 8|
| CB81   | RES 0,C             | 8            | 8               | Yes    | set(bit: 0, register: .C, value: false) assigns 8|
| CB82   | RES 0,D             | 8            | 8               | Yes    | set(bit: 0, register: .D, value: false) assigns 8|
| CB83   | RES 0,E             | 8            | 8               | Yes    | set(bit: 0, register: .E, value: false) assigns 8|
| CB84   | RES 0,H             | 8            | 8               | Yes    | set(bit: 0, register: .H, value: false) assigns 8|
| CB85   | RES 0,L             | 8            | 8               | Yes    | set(bit: 0, register: .L, value: false) assigns 8|
| CB86   | RES 0,(HL)          | 16           | 16              | Yes    | set(bit: 0, indirect: .HL, value: false) assigns 16|
| CB87   | RES 0,A             | 8            | 8               | Yes    | set(bit: 0, register: .A, value: false) assigns 8|
| CB88   | RES 1,B             | 8            | 8               | Yes    | set(bit: 1, register: .B, value: false) assigns 8|
| CB89   | RES 1,C             | 8            | 8               | Yes    | set(bit: 1, register: .C, value: false) assigns 8|
| CB8A   | RES 1,D             | 8            | 8               | Yes    | set(bit: 1, register: .D, value: false) assigns 8|
| CB8B   | RES 1,E             | 8            | 8               | Yes    | set(bit: 1, register: .E, value: false) assigns 8|
| CB8C   | RES 1,H             | 8            | 8               | Yes    | set(bit: 1, register: .H, value: false) assigns 8|
| CB8D   | RES 1,L             | 8            | 8               | Yes    | set(bit: 1, register: .L, value: false) assigns 8|
| CB8E   | RES 1,(HL)          | 16           | 16              | Yes    | set(bit: 1, indirect: .HL, value: false) assigns 16|
| CB8F   | RES 1,A             | 8            | 8               | Yes    | set(bit: 1, register: .A, value: false) assigns 8|
| CB90   | RES 2,B             | 8            | 8               | Yes    | set(bit: 2, register: .B, value: false) assigns 8|
| CB91   | RES 2,C             | 8            | 8               | Yes    | set(bit: 2, register: .C, value: false) assigns 8|
| CB92   | RES 2,D             | 8            | 8               | Yes    | set(bit: 2, register: .D, value: false) assigns 8|
| CB93   | RES 2,E             | 8            | 8               | Yes    | set(bit: 2, register: .E, value: false) assigns 8|
| CB94   | RES 2,H             | 8            | 8               | Yes    | set(bit: 2, register: .H, value: false) assigns 8|
| CB95   | RES 2,L             | 8            | 8               | Yes    | set(bit: 2, register: .L, value: false) assigns 8|
| CB96   | RES 2,(HL)          | 16           | 16              | Yes    | set(bit: 2, indirect: .HL, value: false) assigns 16|
| CB97   | RES 2,A             | 8            | 8               | Yes    | set(bit: 2, register: .A, value: false) assigns 8|
| CB98   | RES 3,B             | 8            | 8               | Yes    | set(bit: 3, register: .B, value: false) assigns 8|
| CB99   | RES 3,C             | 8            | 8               | Yes    | set(bit: 3, register: .C, value: false) assigns 8|
| CB9A   | RES 3,D             | 8            | 8               | Yes    | set(bit: 3, register: .D, value: false) assigns 8|
| CB9B   | RES 3,E             | 8            | 8               | Yes    | set(bit: 3, register: .E, value: false) assigns 8|
| CB9C   | RES 3,H             | 8            | 8               | Yes    | set(bit: 3, register: .H, value: false) assigns 8|
| CB9D   | RES 3,L             | 8            | 8               | Yes    | set(bit: 3, register: .L, value: false) assigns 8|
| CB9E   | RES 3,(HL)          | 16           | 16              | Yes    | set(bit: 3, indirect: .HL, value: false) assigns 16|
| CB9F   | RES 3,A             | 8            | 8               | Yes    | set(bit: 3, register: .A, value: false) assigns 8|
| CBA0   | RES 4,B             | 8            | 8               | Yes    | set(bit: 4, register: .B, value: false) assigns 8|
| CBA1   | RES 4,C             | 8            | 8               | Yes    | set(bit: 4, register: .C, value: false) assigns 8|
| CBA2   | RES 4,D             | 8            | 8               | Yes    | set(bit: 4, register: .D, value: false) assigns 8|
| CBA3   | RES 4,E             | 8            | 8               | Yes    | set(bit: 4, register: .E, value: false) assigns 8|
| CBA4   | RES 4,H             | 8            | 8               | Yes    | set(bit: 4, register: .H, value: false) assigns 8|
| CBA5   | RES 4,L             | 8            | 8               | Yes    | set(bit: 4, register: .L, value: false) assigns 8|
| CBA6   | RES 4,(HL)          | 16           | 16              | Yes    | set(bit: 4, indirect: .HL, value: false) assigns 16|
| CBA7   | RES 4,A             | 8            | 8               | Yes    | set(bit: 4, register: .A, value: false) assigns 8|
| CBA8   | RES 5,B             | 8            | 8               | Yes    | set(bit: 5, register: .B, value: false) assigns 8|
| CBA9   | RES 5,C             | 8            | 8               | Yes    | set(bit: 5, register: .C, value: false) assigns 8|
| CBAA   | RES 5,D             | 8            | 8               | Yes    | set(bit: 5, register: .D, value: false) assigns 8|
| CBAB   | RES 5,E             | 8            | 8               | Yes    | set(bit: 5, register: .E, value: false) assigns 8|
| CBAC   | RES 5,H             | 8            | 8               | Yes    | set(bit: 5, register: .H, value: false) assigns 8|
| CBAD   | RES 5,L             | 8            | 8               | Yes    | set(bit: 5, register: .L, value: false) assigns 8|
| CBAE   | RES 5,(HL)          | 16           | 16              | Yes    | set(bit: 5, indirect: .HL, value: false) assigns 16|
| CBAF   | RES 5,A             | 8            | 8               | Yes    | set(bit: 5, register: .A, value: false) assigns 8|
| CBB0   | RES 6,B             | 8            | 8               | Yes    | set(bit: 6, register: .B, value: false) assigns 8|
| CBB1   | RES 6,C             | 8            | 8               | Yes    | set(bit: 6, register: .C, value: false) assigns 8|
| CBB2   | RES 6,D             | 8            | 8               | Yes    | set(bit: 6, register: .D, value: false) assigns 8|
| CBB3   | RES 6,E             | 8            | 8               | Yes    | set(bit: 6, register: .E, value: false) assigns 8|
| CBB4   | RES 6,H             | 8            | 8               | Yes    | set(bit: 6, register: .H, value: false) assigns 8|
| CBB5   | RES 6,L             | 8            | 8               | Yes    | set(bit: 6, register: .L, value: false) assigns 8|
| CBB6   | RES 6,(HL)          | 16           | 16              | Yes    | set(bit: 6, indirect: .HL, value: false) assigns 16|
| CBB7   | RES 6,A             | 8            | 8               | Yes    | set(bit: 6, register: .A, value: false) assigns 8|
| CBB8   | RES 7,B             | 8            | 8               | Yes    | set(bit: 7, register: .B, value: false) assigns 8|
| CBB9   | RES 7,C             | 8            | 8               | Yes    | set(bit: 7, register: .C, value: false) assigns 8|
| CBBA   | RES 7,D             | 8            | 8               | Yes    | set(bit: 7, register: .D, value: false) assigns 8|
| CBBB   | RES 7,E             | 8            | 8               | Yes    | set(bit: 7, register: .E, value: false) assigns 8|
| CBBC   | RES 7,H             | 8            | 8               | Yes    | set(bit: 7, register: .H, value: false) assigns 8|
| CBBD   | RES 7,L             | 8            | 8               | Yes    | set(bit: 7, register: .L, value: false) assigns 8|
| CBBE   | RES 7,(HL)          | 16           | 16              | Yes    | set(bit: 7, indirect: .HL, value: false) assigns 16|
| CBBF   | RES 7,A             | 8            | 8               | Yes    | set(bit: 7, register: .A, value: false) assigns 8|
| CBC0   | SET 0,B             | 8            | 8               | Yes    | set(bit: 0, register: .B, value: true) assigns 8 |
| CBC1   | SET 0,C             | 8            | 8               | Yes    | set(bit: 0, register: .C, value: true) assigns 8 |
| CBC2   | SET 0,D             | 8            | 8               | Yes    | set(bit: 0, register: .D, value: true) assigns 8 |
| CBC3   | SET 0,E             | 8            | 8               | Yes    | set(bit: 0, register: .E, value: true) assigns 8 |
| CBC4   | SET 0,H             | 8            | 8               | Yes    | set(bit: 0, register: .H, value: true) assigns 8 |
| CBC5   | SET 0,L             | 8            | 8               | Yes    | set(bit: 0, register: .L, value: true) assigns 8 |
| CBC6   | SET 0,(HL)          | 16           | 16              | Yes    | set(bit: 0, indirect: .HL, value: true) assigns 16|
| CBC7   | SET 0,A             | 8            | 8               | Yes    | set(bit: 0, register: .A, value: true) assigns 8 |
| CBC8   | SET 1,B             | 8            | 8               | Yes    | set(bit: 1, register: .B, value: true) assigns 8 |
| CBC9   | SET 1,C             | 8            | 8               | Yes    | set(bit: 1, register: .C, value: true) assigns 8 |
| CBCA   | SET 1,D             | 8            | 8               | Yes    | set(bit: 1, register: .D, value: true) assigns 8 |
| CBCB   | SET 1,E             | 8            | 8               | Yes    | set(bit: 1, register: .E, value: true) assigns 8 |
| CBCC   | SET 1,H             | 8            | 8               | Yes    | set(bit: 1, register: .H, value: true) assigns 8 |
| CBCD   | SET 1,L             | 8            | 8               | Yes    | set(bit: 1, register: .L, value: true) assigns 8 |
| CBCE   | SET 1,(HL)          | 16           | 16              | Yes    | set(bit: 1, indirect: .HL, value: true) assigns 16|
| CBCF   | SET 1,A             | 8            | 8               | Yes    | set(bit: 1, register: .A, value: true) assigns 8 |
| ...existing code...
| ...existing code...
| ...existing code...
| ...existing code...
| ...existing code...
| ...existing code...
| ...existing code...
| ...existing code...
| ...existing code...
