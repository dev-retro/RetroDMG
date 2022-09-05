using System;
using System.Data.Common;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Cade.DMG.Core;

public class CPU
{
    private MMU _memory;
    private Registers _registers;
    private bool _extendedOpCodes;
    private bool debug = false;

    public int Cycles;

    private string _logPath;
    private FileStream _logFileStream;

    public CPU(ref MMU memory)
    {
        _memory = memory;
        _registers = new Registers();
        _extendedOpCodes = false;
        Cycles = 0;

        if(!memory.BootromLoaded)
            _registers.PC = 0x100;

        //if (debug)
        //{
        //    _logPath = $"/Users/hevey/Desktop/Logs/PCC-DMG_log-{DateTime.Now:yyyyMMddHHmmss}.txt";

        //    _logFileStream = File.OpenWrite(_logPath);   
        //}
    }

    public void Tick()
    {
        var opcode = _memory.Read(_registers.PC);

        if (_extendedOpCodes)
        {
            _extendedOpCodes = false;
            switch (opcode)
            {
                case 0x11: // RL C
                    var data = (_registers.C << 1) | _registers.F_Carry();

                    _registers.F_Zero(data == 0);
                    _registers.F_Subtraction(false);
                    _registers.F_HalfCarry(false);
                    _registers.F_Carry(data > 0xFF);

                    _registers.C = (byte) data;
                    _registers.PC += 1;
                    Cycles += 8;
                    break;
                // case 0x17: // RL A
                //     var data = (_registers.A << 1) | _registers.F_Carry();
                //
                //     _registers.F_Zero(data == 0);
                //     _registers.F_Subtraction(false);
                //     _registers.F_HalfCarry(false);
                //     _registers.F_Carry(data > 0xFF);
                //     
                //     _registers.A = (byte) data;
                //     _registers.PC += 2;
                //     Cycles += 8;
                //     break;
                case 0x7C: // BIT 7,H
                    var bit = _registers.H >> 7;

                    _registers.F_Subtraction(false);
                    _registers.F_HalfCarry(true);
                    _registers.F_Zero(bit == 0);
                    _registers.PC += 1;
                    break;
                default:
                    throw new NotImplementedException($"OpCode: CB_{opcode} not implemented");
            }
        }
        else
        {
            switch (opcode)
            {
                case 0x00: // NOP
                    Nop();
                    break;
                case 0x01: // LD BC,u16
                    _registers.BC = Load();
                    break;
                case 0x02: // LD (BC),A
                    Load(_registers.A, _registers.BC, 8);
                    break;
                case 0x03: // INC BC
                    _registers.BC = Inc(_registers.BC, 8);
                    break;
                case 0x04: // INC B
                    _registers.B = Inc(_registers.B, 4);
                    break;
                case 0x05: // DEC B
                    _registers.B = Dec(_registers.B, 4);
                    break;
                case 0x06: // LD B,u8
                    _registers.B = Read(8);
                    break;
                case 0x07: // RLCA
                    Rlca();
                    break;
                case 0x08: // LD (u16),SP
                    LoadSp();
                    break;
                case 0x09: // ADD HL,BC
                    _registers.HL = Add(_registers.BC, _registers.HL, 8);
                    break;
                case 0x0A: // LD A,(BC)
                    _registers.A = Load(_registers.BC, 8);
                    break;
                case 0x0B: // DEC BC
                    _registers.BC = Dec(_registers.BC, 8);
                    break;
                case 0x0C: // INC C
                    _registers.C = Inc(_registers.C, 4);
                    break;
                case 0x0D: // DEC C
                    _registers.C = Dec(_registers.C, 4);
                    break;
                case 0x0E: // LD C,u8
                    _registers.C = Read(8);
                    break;
                case 0x0F: // RRCA
                    Rrca();
                    break;
                case 0x10: // Stop 
                    //TODO: This needs more work
                    Stop();
                    break;
                case 0x11: // LD DE,u16
                    _registers.DE = Load();
                    break;
                case 0x12: // LD (DE),A
                    Load(_registers.A, _registers.DE, 8);
                    break;
                case 0x13: // INC DE
                    _registers.DE = Inc(_registers.DE, 8);
                    break;
                case 0x14: // INC D
                    _registers.D = Inc(_registers.D, 4);
                    break;
                case 0x15: // DEC D
                    _registers.D = Dec(_registers.D, 4);
                    break;
                case 0x16: // LD D,u8
                    _registers.D = Read(8);
                    break;
                case 0x17: // RLA
                    Rla();
                    break;
                case 0x18: // JR e
                    Jr();
                    break;
                case 0x19: // ADD HL,DE
                    _registers.HL = Add(_registers.DE, _registers.HL, 8);
                    break;
                case 0x1A: // LD A,(DE)
                    _registers.A = Load(_registers.DE, 8);
                    break;
                case 0x1B: // DEC DE
                    _registers.DE = Dec(_registers.DE, 8);
                    break;
                case 0x1C: // INC E
                    _registers.E = Inc(_registers.E, 4);
                    break;
                case 0x1D: // DEC E
                    _registers.E = Dec(_registers.E, 4);
                    break;
                case 0x1E: // LD E,u8
                    _registers.E = Read(8);
                    break;
                case 0x1F: // RRA
                    Rra();
                    break;
                case 0x20: // JR NZ e
                    JrNz();
                    break;
                case 0x21: // LD HL,u16 --- OK
                    _registers.HL = Load();
                    break;
                case 0x22: // LD (HL+) A
                    LoadHlPlus();
                    break;
                case 0x23: // INC HL
                    _registers.HL = Inc(_registers.HL, 8);
                    break;
                case 0x24: // INC H
                    _registers.H = Inc(_registers.H, 4);
                    break;
                case 0x25: // DEC H
                    _registers.H = Dec(_registers.H, 4);
                    break;
                case 0x26: // LD H, u8
                    _registers.H = Read(8);
                    break;
                case 0x27: // DAA
                    throw new NotImplementedException("DAA Not Implemented");
                case 0x28: // JR Z e
                    JrZ();
                    break;
                case 0x29: // ADD HL,HL
                    _registers.HL = Add(_registers.HL, _registers.HL, 8);
                    break;
                case 0x2A: // LD A,(HL+)
                    LoadFromHlPlus();
                    break;
                case 0x2B: // DEC HL
                    _registers.HL = Dec(_registers.HL, 8);
                    break;
                case 0x2C: // INC L
                    _registers.L = Inc(_registers.L, 4);
                    break;
                case 0x2D: // DEC L
                    _registers.L = Dec(_registers.L, 4);
                    break;
                case 0x2E: // LD E,u8
                    _registers.E = Read(8);
                    break;
                case 0x2F: // CPL
                    Cpl();
                    break;
                case 0x30: // JR NC e
                    JrNc();
                    break;
                case 0x31: // LD SP,u16 --- OK
                    _registers.SP = Load();
                    break;
                case 0x32: // LD (HL-),A
                    LoadHlMinus();
                    break;
                case 0x33: // INC SP
                    _registers.SP = Inc(_registers.SP, 8);
                    break;
                case 0x34: // INC (HL)
                    IncHl();
                    break;
                case 0x35: // DEC (HL)
                    DecHl();
                    break;
                case 0x36: // LD (HL),u8
                    LoadHl();
                    break;
                case 0x37: // SCF
                    Scf();
                    break;
                case 0x38: // JR C e 
                    JrC();
                    break;
                case 0x39: // ADD HL,SP
                    _registers.HL = Add(_registers.HL, _registers.SP, 8);
                    break;
                case 0x3A: // LD A,(HL-)
                    LoadFromHlMinus();
                    break;
                case 0x3B: // DEC SP
                    _registers.SP = Dec(_registers.SP, 8);
                    break;
                case 0x3C: // INC A
                    _registers.A = Inc(_registers.A, 4);
                    break;
                case 0x3D: // DEC A
                    _registers.A = Dec(_registers.A, 4);
                    break;
                case 0x3E: // LD A,u8
                    _registers.A = Read(8);
                    break;
                case 0x3F: // CCF
                    Ccf();
                    break;
                case 0x40: // LD B,B
                    _registers.B = Load(_registers.B, 4);
                    break;
                case 0x41: // LD B,C
                    _registers.B = Load(_registers.C, 4);
                    break;
                case 0x42: // LD B,D
                    _registers.B = Load(_registers.D, 4);
                    break;
                case 0x43: // LD B,E
                    _registers.B = Load(_registers.E, 4);
                    break;
                case 0x44: // LD B,H
                    _registers.B = Load(_registers.H, 4);
                    break;
                case 0x45: // LD B,L
                    _registers.B = Load(_registers.L, 4);
                    break;
                case 0x46: // LD B,(HL)
                    _registers.B = Load(_memory.Read(_registers.HL), 8);
                    break;
                case 0x47: // LD B,A
                    _registers.B = Load(_registers.A, 4);
                    break;
                case 0x48: // LD C,B
                    _registers.C = Load(_registers.B, 4);
                    break;
                case 0x49: // LD C,C
                    _registers.C = Load(_registers.C, 4);
                    break;
                case 0x4A: // LD C,D
                    _registers.C = Load(_registers.D, 4);
                    break;
                case 0x4B: // LD C,E
                    _registers.C = Load(_registers.E, 4);
                    break;
                case 0x4C: // LD C,H
                    _registers.C = Load(_registers.H, 4);
                    break;
                case 0x4D: // LD C,L
                    _registers.C = Load(_registers.L, 4);
                    break;
                case 0x4E: // LD C,(HL)
                    _registers.C = Load(_memory.Read(_registers.HL), 8);
                    break;
                case 0x4F: // LD C,A
                    _registers.C = Load(_registers.A, 4);
                    break;
                case 0x50: // LD D,B
                    _registers.D = Load(_registers.B, 4);
                    break;
                case 0x51: // LD D,C
                    _registers.D = Load(_registers.C, 4);
                    break;
                case 0x52: // LD D,D
                    _registers.D = Load(_registers.D, 4);
                    break;
                case 0x53: // LD D,E
                    _registers.D = Load(_registers.E, 4);
                    break;
                case 0x54: // LD D,H
                    _registers.D = Load(_registers.H, 4);
                    break;
                case 0x55: // LD D,L
                    _registers.D = Load(_registers.L, 4);
                    break;
                case 0x56: // LD D,(HL)
                    _registers.D = Load(_memory.Read(_registers.HL), 8);
                    break;
                case 0x57: // LD D,A
                    _registers.D = Load(_registers.A, 4);
                    break;
                case 0x58: // LD E,B
                    _registers.E = Load(_registers.B, 4);
                    break;
                case 0x59: // LD E,C
                    _registers.E = Load(_registers.B, 4);
                    break;
                case 0x5A: // LD E,D
                    _registers.E = Load(_registers.D, 4);
                    break;
                case 0x5B: // LD E,E
                    _registers.E = Load(_registers.E, 4);
                    break;
                case 0x5C: // LD E,H
                    _registers.E = Load(_registers.H, 4);
                    break;
                case 0x5D: // LD E,L
                    _registers.E = Load(_registers.L, 4);
                    break;
                case 0x5E: // LD E,(HL)
                    _registers.E = Load(_memory.Read(_registers.HL), 8);
                    break;
                case 0x5F: // LD E,A
                    _registers.E = Load(_registers.A, 4);
                    break;
                case 0x60: // LD H,B
                    _registers.H = Load(_registers.B, 4);
                    break;
                case 0x61: // LD H,C
                    _registers.H = Load(_registers.C, 4);
                    break;
                case 0x62: // LD H,D
                    _registers.H = Load(_registers.D, 4);
                    break;
                case 0x63: // LD H,E
                    _registers.H = Load(_registers.E, 4);
                    break;
                case 0x64: // LD H,H
                    _registers.H = Load(_registers.H, 4);
                    break;
                case 0x65: // LD H,L
                    _registers.H = Load(_registers.L, 4);
                    break;
                case 0x66: // LD H,(HL)
                    _registers.H = Load(_memory.Read(_registers.HL), 8);
                    break;
                case 0x67: // LD H,A
                    _registers.H = Load(_registers.A, 4);
                    break;
                case 0x68: // LD L,B
                    _registers.L = Load(_registers.B, 4);
                    break;
                case 0x69: // LD L,C
                    _registers.L = Load(_registers.C, 4);
                    break;
                case 0x6A: // LD L,D
                    _registers.L = Load(_registers.D, 4);
                    break;
                case 0x6B: // LD L,E
                    _registers.L = Load(_registers.E, 4);
                    break;
                case 0x6C: // LD L,H
                    _registers.L = Load(_registers.H, 4);
                    break;
                case 0x6D: // LD L,L
                    _registers.L = Load(_registers.L, 4);
                    break;
                case 0x6E: // LD L,(HL)
                    _registers.L = Load(_memory.Read(_registers.HL), 8);
                    break;
                case 0x6F: // LD L,A
                    _registers.L = Load(_registers.A, 4);
                    break;
                case 0x70: // LD (HL),B
                    _memory.Write(_registers.HL, Load(_registers.B, 8));
                    break;
                case 0x71: // LD (HL),C
                    _memory.Write(_registers.HL, Load(_registers.C, 8));
                    break;
                case 0x72: // LD (HL),D
                    _memory.Write(_registers.HL, Load(_registers.D, 8));
                    break;
                case 0x73: // LD (HL),E
                    _memory.Write(_registers.HL, Load(_registers.E, 8));
                    break;
                case 0x74: // LD (HL),H
                    _memory.Write(_registers.HL, Load(_registers.H, 8));
                    break;
                case 0x75: // LD (HL),L
                    _memory.Write(_registers.HL, Load(_registers.L, 8));
                    break;
                case 0x76: // HALT
                    throw new NotImplementedException();
                    break;
                case 0x77: // LD (HL),A
                    _memory.Write(_registers.HL, Load(_registers.A, 8));
                    break;
                case 0x78: // LD A,B
                    _registers.A = Load(_registers.B, 4);
                    break;
                case 0x79: // LD A,C
                    _registers.A = Load(_registers.C, 4);
                    break;
                case 0x7A: // LD A,D
                    _registers.A = Load(_registers.D, 4);
                    break;
                case 0x7B: // LD A,E
                    _registers.A = Load(_registers.E, 4);
                    break;
                case 0x7C: // LD A,H
                    _registers.A = Load(_registers.H, 4);
                    break;
                case 0x7D: // LD A,L
                    _registers.A = Load(_registers.L, 4);
                    break;
                case 0x7E: // LD A,(HL)
                    _registers.A = Load(_memory.Read(_registers.HL), 8);
                    break;
                case 0x7F: // LD A,A
                    _registers.A = Load(_registers.A, 4);
                    break;
                case 0x80: // ADD A,B
                    _registers.A = Add(_registers.A, _registers.B, 4);
                    break;
                case 0x81: // ADD A,C
                    _registers.A = Add(_registers.A, _registers.C, 4);
                    break;
                case 0x82: // ADD A,D
                    _registers.A = Add(_registers.A, _registers.D, 4);
                    break;
                case 0x83: // ADD A,E
                    _registers.A = Add(_registers.A, _registers.E, 4);
                    break;
                case 0x84: // ADD A,H
                    _registers.A = Add(_registers.A, _registers.H, 4);
                    break;
                case 0x85: // ADD A,L
                    _registers.A = Add(_registers.A, _registers.L, 4);
                    break;
                case 0x86: // ADD A,(HL)
                    _registers.A = Add(_registers.A, _memory.Read(_registers.HL), 8);
                    break;
                case 0x87: // ADD A,A
                    _registers.A = Add(_registers.A, _registers.A, 4);
                    break;
                case 0x88: // ADC A,B
                    _registers.A = AdC(_registers.A, _registers.B, 4);
                    break;
                case 0x89: // ADC A,C
                    _registers.A = AdC(_registers.A, _registers.C, 4);
                    break;
                case 0x8A: // ADC A,D
                    _registers.A = AdC(_registers.A, _registers.D, 4);
                    break;
                case 0x8B: // ADC A,E
                    _registers.A = AdC(_registers.A, _registers.E, 4);
                    break;
                case 0x8C: // ADC A,H
                    _registers.A = AdC(_registers.A, _registers.H, 4);
                    break;
                case 0x8D: // ADC A,L
                    _registers.A = AdC(_registers.A, _registers.L, 4);
                    break;
                case 0x8E: // ADC A,(HL)
                    _registers.A = AdC(_registers.A, _memory.Read(_registers.HL), 8);
                    break;
                case 0x8F: // ADC A,A
                    _registers.A = AdC(_registers.A, _registers.A, 4);
                    break;
                case 0x90: // SUB A,B
                    _registers.A = Sub(_registers.A, _registers.B, 4);
                    break;
                case 0x91: // SUB A,C
                    _registers.A = Sub(_registers.A, _registers.C, 4);
                    break;
                case 0x92: // SUB A,D
                    _registers.A = Sub(_registers.A, _registers.D, 4);
                    break;
                case 0x93: // SUB A,E
                    _registers.A = Sub(_registers.A, _registers.E, 4);
                    break;
                case 0x94: // SUB A,H
                    _registers.A = Sub(_registers.A, _registers.H, 4);
                    break;
                case 0x95: // SUB A,L
                    _registers.A = Sub(_registers.A, _registers.B, 4);
                    break;
                case 0x96: // SUB A,(HL)
                    _registers.A = Sub(_registers.A, _memory.Read(_registers.HL), 8);
                    break;
                case 0x97: // SUB A,A
                    _registers.A = Sub(_registers.A, _registers.A, 4);
                    break;
                case 0x98: // SBC A,B
                    _registers.A = SbC(_registers.A, _registers.B, 4);
                    break;
                case 0x99: // SBC A,C
                    _registers.A = SbC(_registers.A, _registers.C, 4);
                    break;
                case 0x9A: // SBC A,D
                    _registers.A = SbC(_registers.A, _registers.D, 4);
                    break;
                case 0x9B: // SBC A,E
                    _registers.A = SbC(_registers.A, _registers.E, 4);
                    break;
                case 0x9C: // SBC A,H
                    _registers.A = SbC(_registers.A, _registers.H, 4);
                    break;
                case 0x9D: // SBC A,L
                    _registers.A = SbC(_registers.A, _registers.L, 4);
                    break;
                case 0x9E: // SBC A,(HL)
                    _registers.A = SbC(_registers.A, _memory.Read(_registers.HL), 8);
                    break;
                case 0x9F: // SBC A,A
                    _registers.A = SbC(_registers.A, _registers.A, 4);
                    break;
                case 0xA0: // AND A,B
                    _registers.A = And(_registers.A, _registers.B, 4);
                    break;
                case 0xA1: // AND A,C
                    _registers.A = And(_registers.A, _registers.C, 4);
                    break;
                case 0xA2: // AND A,D
                    _registers.A = And(_registers.A, _registers.D, 4);
                    break;
                case 0xA3: // AND A,E
                    _registers.A = And(_registers.A, _registers.E, 4);
                    break;
                case 0xA4: // AND A,H
                    _registers.A = And(_registers.A, _registers.H, 4);
                    break;
                case 0xA5: // AND A,L
                    _registers.A = And(_registers.A, _registers.L, 4);
                    break;
                case 0xA6: // AND A,(HL)
                    _registers.A = And(_registers.A, _memory.Read(_registers.HL), 8);
                    break;
                case 0xA7: // AND A,A
                    _registers.A = And(_registers.A, _registers.A, 4);
                    break;
                case 0xA8: // XOR A,B
                    _registers.A = Xor(_registers.A, _registers.B, 4);
                    break;
                case 0xA9: // XOR A,C
                    _registers.A = Xor(_registers.A, _registers.C, 4);
                    break;
                case 0xAA: // XOR A,D
                    _registers.A = Xor(_registers.A, _registers.D, 4);
                    break;
                case 0xAB: // XOR A,E
                    _registers.A = Xor(_registers.A, _registers.E, 4);
                    break;
                case 0xAC: // XOR A,H
                    _registers.A = Xor(_registers.A, _registers.H, 4);
                    break;
                case 0xAD: // XOR A,L
                    _registers.A = Xor(_registers.A, _registers.L, 4);
                    break;
                case 0xAE: // XOR A,(HL)
                    _registers.A = Xor(_registers.A, _memory.Read(_registers.HL), 8);
                    break;
                case 0xAF: // XOR A,A --- OK
                    _registers.A = Xor(_registers.A, _registers.A, 4);
                    break;
                case 0xB0: // OR A,B
                    _registers.A = Or(_registers.A, _registers.B, 4);
                    break;
                case 0xB1: // OR A,C
                    _registers.A = Or(_registers.A, _registers.C, 4);
                    break;
                case 0xB2: // OR A,D
                    _registers.A = Or(_registers.A, _registers.D, 4);
                    break;
                case 0xB3: // OR A,E
                    _registers.A = Or(_registers.A, _registers.E, 4);
                    break;
                case 0xB4: // OR A,H
                    _registers.A = Or(_registers.A, _registers.H, 4);
                    break;
                case 0xB5: // OR A,L
                    _registers.A = Or(_registers.A, _registers.L, 4);
                    break;
                case 0xB6: // OR A,(HL)
                    _registers.A = Or(_registers.A, _memory.Read(_registers.HL), 8);
                    break;
                case 0xB7: // OR A,A
                    _registers.A = Or(_registers.A, _registers.A, 4);
                    break;
                case 0xB8: // CP A,B
                    _registers.B = Cp(_registers.A, _registers.B, 4);
                    break;
                case 0xB9: // CP A,C
                    _registers.B = Cp(_registers.A, _registers.C, 4);
                    break;
                case 0xBA: // CP A,D
                    _registers.B = Cp(_registers.A, _registers.D, 4);
                    break;
                case 0xBB: // CP A,E
                    _registers.B = Cp(_registers.A, _registers.E, 4);
                    break;
                case 0xBC: // CP A,H
                    _registers.B = Cp(_registers.A, _registers.H, 4);
                    break;
                case 0xBD: // CP A,L
                    _registers.B = Cp(_registers.A, _registers.L, 4);
                    break;
                case 0xBE: // CP A,(HL)
                    _registers.B = Cp(_registers.A, _memory.Read(_registers.HL), 8);
                    break;
                case 0xBF: // CP A,A
                    _registers.B = Cp(_registers.A, _registers.A, 4);
                    break;
                case 0xC0: // RET NZ
                    RetNz();
                    break;
                case 0xC1: // POP BC
                    _registers.BC = Pop();
                    break;
                case 0xC2: // JP NZ,u16
                    JmpNz();
                    break;
                case 0xC3: // JP u16
                    Jmp();
                    break;
                case 0xC4: // CALL NZ,u16
                    CallNz();
                    break;
                case 0xC5: // PUSH BC
                    Push(_registers.BC);
                    break;
                case 0xC6: // ADD A,u8
                    _registers.A = Add(_registers.A, _memory.Read((ushort) (_registers.PC + 1)), 8);
                    _registers.PC += 1;
                    break;
                case 0xC7: // RST 00H
                    Rst(0);
                    break;
                case 0xC8: // RET Z
                    RetZ();
                    break;
                case 0xC9: // RET
                    Ret();
                    break;
                case 0xCA: // JP Z,u16
                    JmpZ();
                    break;
                case 0xCB: // CB PREFIX
                    _extendedOpCodes = true;
                    _registers.PC += 1;
                    Cycles += 4;
                    break;
                case 0xCC: // CALL Z,u16
                    CallZ();
                    break;
                case 0xCD: // CALL u16
                    Call();
                    break;
                case 0xCE: // ADC A,u8
                    _registers.A = AdC(_registers.A, _memory.Read((ushort) (_registers.PC + 1)), 8);
                    _registers.PC += 1;
                    break;
                case 0xCF: // RST 08H
                    Rst(8);
                    break;
                case 0xD0: // RET NC
                    RetNc();
                    break;
                case 0xD1: // POP DE
                    _registers.DE = Pop();
                    break;
                case 0xD2: // JP NC,u16
                    JmpNc();
                    break;
                case 0xD3: // ILLEGAL OpCode
                    throw new NotSupportedException("0xD3 is illegal");
                case 0xD4: // CALL NC,u16
                    CallNc();
                    break;
                case 0xD5: // PUSH DE
                    Push(_registers.DE);
                    break;
                case 0xD6: // SUB A, u8
                    _registers.A = Sub(_registers.A, _memory.Read((ushort) (_registers.PC + 1)), 8);
                    _registers.PC += 1;
                    break;
                case 0xD7: // RST 10H
                    Rst(16);
                    break;
                case 0xD8: // RET C
                    RetC();
                    break;
                case 0xD9: // RETI
                    throw new NotImplementedException("RETI Not implemented");
                case 0xDA: // JP C,u16
                    JmpC();
                    break;
                case 0xDB: // ILLEGAL OpCode
                    throw new NotSupportedException("0xDB is illegal");
                case 0xDC: // CALL C,u16
                    CallC();
                    break;
                case 0xDD: // ILLEGAL OpCode
                    throw new NotImplementedException("0xDD is illegal");
                case 0xDE: // SBC A,u8
                    _registers.A = SbC(_registers.A, _memory.Read((ushort) (_registers.PC + 1)), 8);
                    _registers.PC += 1;
                    break;
                case 0xDF: // RST 18H
                    Rst(24);
                    break;
                case 0xE0: // LD (FF00+u8),A
                    LoadFfu8();
                    break;
                case 0xE1: // POP HL
                    _registers.HL = Pop();
                    break;
                case 0xE2: // LD (FF00+C).A
                    LoadFfC();
                    break;
                case 0xE3: // ILLEGAL OpCode
                    throw new NotSupportedException("0xE3 is illegal");
                case 0xE4: // ILLEGAL OpCode
                    throw new NotSupportedException("0xE4 is illegal");
                case 0xE5: // PUSH HL
                    Push(_registers.HL);
                    break;
                case 0xE6: // AND a,u8
                    _registers.A = And(_registers.A, _memory.Read((ushort) (_registers.PC + 1)), 8);
                    _registers.PC += 1;
                    break;
                case 0xE7: // RST 20H
                    Rst(32);
                    break;
                case 0xE8: // ADD SP,i8
                    AddSP();
                    break;
                case 0xE9: // JP HL
                    JmpHL();
                    break;
                case 0xEA: // LD (u16),A
                    LoadU18A();
                    break;
                case 0xEB: // ILLEGAL OpCode
                    throw new NotSupportedException("0xEB  is illegal");
                case 0xEC: // ILLEGAL OpCode
                    throw new NotSupportedException("0xEC  is illegal");
                case 0xED: // ILLEGAL OpCode
                    throw new NotSupportedException("0xED  is illegal");
                case 0xEE: // XOR A,u8
                    _registers.A = Xor(_registers.A, _memory.Read((ushort) (_registers.PC + 1)), 8);
                    _registers.PC += 1;
                    break;
                case 0xEF: // RST 28H
                    Rst(40);
                    break;
                case 0xF0: // LD A,(FF00+u8)
                    LoadFromFfu8();
                    break;
                case 0xF1: // POP AF
                    _registers.AF = Pop();
                    break;
                case 0xF2: // LD A,(FF00+C)
                    LoadFromFfC();
                    break;
                case 0xF3: // DI
                    throw new NotImplementedException("DI Not implemented");
                case 0xF4: // ILLEGAL OpCode
                    throw new NotSupportedException("0xF4 is illegal");
                case 0xF5: // PUSH AF
                    Push(_registers.AF);
                    break;
                case 0xF6: // OR A,u8
                    _registers.A = Or(_registers.A, _memory.Read((ushort) (_registers.PC + 1)), 8);
                    _registers.PC += 1;
                    break;
                case 0xF7: // RST 30H
                    Rst(48);
                    break;
                case 0xF8: // LD HL,SP+i8
                    LoadHlSpi8();
                    break;
                case 0xF9: // LD HL,SP
                    LoadHlSp();
                    break;
                case 0xFA: // LD A,(u16)
                    LoadAu16();
                    break;
                case 0xFB: // EI
                    throw new NotImplementedException("EI Not Implemented");
                    break;
                case 0xFC: // ILLEGAL OpCode
                    throw new NotSupportedException("0xFC is illegal");
                case 0xFD: // ILLEGAL OpCode
                    throw new NotSupportedException("0xFD is illegal");
                case 0xFE: // CP a,u8
                    _registers.A = Cp(_registers.A, _memory.Read((ushort) (_registers.PC + 1)), 8);
                    _registers.PC += 1;
                    break;
                case 0xFF: // RST 38H
                    Rst(56);
                    break;
            }
        }

        if (debug)
        {
            _logFileStream.WriteAsync(Encoding.Unicode.GetBytes(_registers.ToString()));    
        }

        if (_memory.Read(0xFF02) != 0x81) return;
        
        var character = (char) _memory.Read(0xFF01);
        Console.Write(character);
        _memory.Write(0xFF02, 0x0);
    }

    /// <summary>
    /// Runs the No Operation OpCode
    /// </summary>
    private void Nop()
    {
        _registers.PC += 1;
        Cycles += 4;
    }

    /// <summary>
    /// Runs the Stop Operation OpCode
    /// </summary>
    private void Stop()
    {
        _registers.PC += 2;
        Cycles += 4;
    }

    /// <summary>
    /// Load memory into a register
    /// </summary>
    /// <returns>16bit data to save into the correct 16bit register</returns>
    private ushort Load()
    {
        //TODO: Keeping the old source variable here, need to make sure the new code is correct.
        //var source = (ushort) ((_registers.PC + 2) << 8 | (_registers.PC + 1));
        var source = (ushort) (_memory.Read((ushort) (_registers.PC + 2)) << 8 |
                               _memory.Read((ushort) (_registers.PC + 1)));

        _registers.PC += 3;
        Cycles += 12;
        return source;
    }

    /// <summary>
    /// Load into register from memory location
    /// </summary>
    /// <param name="register">16-bit register that holds location address</param>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    /// <returns>Returned 8-bit data to store</returns>
    private byte Load(ushort register, int cycles)
    {
        Cycles += cycles;
        _registers.PC += 1;
        return _memory.Read(register);
    }

    /// <summary>
    /// Loads byte into memory at location specified
    /// </summary>
    /// <param name="source">Data to be stored</param>
    /// <param name="destination">Location in memory to store data</param>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    private void Load(byte source, ushort destination, int cycles)
    {
        _memory.Write(destination, source);
        _registers.PC += 1;
        Cycles += cycles;
    }

    /// <summary>
    /// Stores from one register into another.
    /// </summary>
    /// <param name="source">source registration</param>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    /// <returns>data to be stored in destination register</returns>
    private byte Load(byte source, int cycles)
    {
        Cycles += cycles;
        _registers.PC += 1;

        return source;
    }

    private void LoadFfu8()
    {
        var data = _memory.Read((ushort) (_registers.PC + 1));

        _memory.Write((ushort) ((0xFF << 8) | data), _registers.A);
        _registers.PC += 2;
        Cycles += 12;
    }

    private void LoadFromFfu8()
    {
        var data = _memory.Read((ushort) (_registers.PC + 1));

        _registers.A = _memory.Read((ushort) ((0xFF << 8) | data));
        _registers.PC += 2;
        Cycles += 12;
    }

    private void LoadFfC()
    {
        _memory.Write((ushort) ((0xFF << 8) | _registers.C), _registers.A);
        _registers.PC += 1;
        Cycles += 8;
    }

    private void LoadFromFfC()
    {
        _registers.A = _memory.Read((ushort) ((0xFF << 8) | _registers.C));
        _registers.PC += 1;
        Cycles += 8;
    }

    /// <summary>
    /// Load memory location from memory and store SP into it contiguosly
    /// </summary>
    private void LoadSp()
    {
        var data = (ushort) (_memory.Read((ushort) (_registers.PC + 2)) << 8 |
                             _memory.Read((ushort) (_registers.PC + 1)));

        _memory.Write(data, (byte) (_registers.SP & 0xFF));
        _memory.Write((ushort) (data + 1), (byte) (_registers.SP >> 8));
        _registers.PC += 3;
        Cycles += 20;
    }

    private void LoadHl()
    {
        var data = (ushort) (_memory.Read((ushort) (_registers.PC + 2)) << 8 |
                             _memory.Read((ushort) (_registers.PC + 1)));
        _registers.HL = data;
        _registers.PC += 2;
        Cycles += 12;
    }

    private void LoadHlSp()
    {
        _registers.SP = _registers.HL;
        _registers.PC += 1;
        Cycles += 8;
    }

    private void LoadHlSpi8()
    {
        var data = _registers.SP + _memory.Read((ushort) (_registers.PC + 1));

        _registers.F_Zero(false);

        _registers.F_Subtraction(false);

        _registers.F_HalfCarry((_registers.SP & 0xF) + (_memory.Read(_registers.PC) & 0xF) > 0xF);

        _registers.F_Carry(data > 0xFF);

        _registers.HL = (ushort) data;
        _registers.PC += 2;
        Cycles += 12;
    }

    private void LoadAu16()
    {
        var data = _memory.Read((ushort) (_registers.PC + 2)) << 8 | _memory.Read((ushort) (_registers.PC + 1));
        _registers.A = _memory.Read((ushort) data);
        _registers.PC += 3;
        Cycles += 16;
    }

    /// <summary>
    /// Write to memory stored in register HL and increment HL from register A
    /// </summary>
    private void LoadHlPlus()
    {
        _memory.Write(_registers.HL, _registers.A);

        _registers.HL = (ushort) (_registers.HL + 1);
        _registers.PC += 1;
        Cycles += 8;
    }

    /// <summary>
    /// Write to register A from memory stored in register HL and increment HL
    /// </summary>
    private void LoadFromHlPlus()
    {
        _registers.A = _memory.Read(_registers.HL);

        _registers.HL = (ushort) (_registers.HL + 1);
        _registers.PC += 1;
        Cycles += 8;
    }

    /// <summary>
    /// Write to memory stored in register HL and decrement HL from register A
    /// </summary>
    private void LoadHlMinus()
    {
        _memory.Write(_registers.HL, _registers.A);

        _registers.HL = (ushort) (_registers.HL - 1);
        _registers.PC += 1;
        Cycles += 8;
    }

    /// <summary>
    /// Write to register A from memory stored in register HL and decrement HL
    /// </summary>
    private void LoadFromHlMinus()
    {
        _registers.A = _memory.Read(_registers.HL);

        _registers.HL = (ushort) (_registers.HL - 1);
        _registers.PC += 1;
        Cycles += 8;
    }

    private void LoadU18A()
    {
        var ldAU16 = _memory.Read((ushort) (_registers.PC + 2)) << 8 | _memory.Read((ushort) (_registers.PC + 1));
        _memory.Write((ushort) ldAU16, _registers.A);
        _registers.PC += 3;
        Cycles += 16;
    }

    /// <summary>
    /// Increments the 16-bit register by 1
    /// </summary>
    /// <param name="register">The 16-bit register to increment</param>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    /// <returns>The incremented 16-bit register data to store</returns>
    private ushort Inc(ushort register, int cycles)
    {
        _registers.PC += 1;
        Cycles += cycles;
        return (ushort) (register + 1);
    }

    /// <summary>
    /// Increments the 8-bit register by 1
    /// </summary>
    /// <param name="register">The 8-bit register to increment</param>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    /// <returns>The incremented 8-bit register data to store</returns>
    private byte Inc(byte register, int cycles)
    {
        var incRegister = register + 1;

        _registers.F_Subtraction(false);

        _registers.F_Zero(incRegister == 0);

        _registers.F_HalfCarry(incRegister > 0xF);

        _registers.PC += 1;
        Cycles += cycles;
        return (byte) incRegister;
    }

    /// <summary>
    /// Read memory location from HL and increment it by 1
    /// </summary>
    private void IncHl()
    {
        var addr = _memory.Read(_registers.HL) + 1;

        _registers.F_Subtraction(false);

        _registers.F_Zero(addr == 0);

        _registers.F_HalfCarry(addr > 0xF);

        _memory.Write(_registers.HL, (byte) addr);

        _registers.PC += 1;
        Cycles += 12;
    }

    /// <summary>
    /// Read memory location from HL and decrement it by 1
    /// </summary>
    private void DecHl()
    {
        var addr = _memory.Read(_registers.HL) - 1;

        _registers.F_Subtraction(true);

        _registers.F_Zero(addr == 0);

        _registers.F_HalfCarry(addr > 0xF);

        _memory.Write(_registers.HL, (byte) addr);

        _registers.PC += 1;
        Cycles += 12;
    }

    /// <summary>
    /// Decrement the 16-bit register by 1
    /// </summary>
    /// <param name="register">The 16-bit register to decrement</param>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    /// <returns>The decremented 16-bit register data to store</returns>
    private ushort Dec(ushort register, int cycles)
    {
        _registers.PC += 1;
        Cycles += cycles;
        return (ushort) (register - 1);
    }

    /// <summary>
    /// Decrements the 8-bit register by 1
    /// </summary>
    /// <param name="register">The 8-bit register to decrement</param>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    /// <returns>The decremented 8-bit register data to store</returns>
    private byte Dec(byte register, int cycles)
    {
        var decRegister = register - 1;

        _registers.F_Subtraction(true);

        _registers.F_Zero(decRegister == 0);

        _registers.F_HalfCarry(decRegister < 0xF);

        _registers.PC += 1;
        Cycles += cycles;
        return (byte) decRegister;
    }

    /// <summary>
    /// Retrieves a byte from memory
    /// </summary>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    /// <returns>The byte from memory</returns>
    private byte Read(int cycles)
    {
        var source = _memory.Read((ushort) (_registers.PC + 1));
        _registers.PC += 2;
        Cycles += cycles;
        return source;
    }

    /// <summary>
    /// Rotates register A left
    /// </summary>
    private void Rlca()
    {
        var rlca = (byte) (_registers.A << 1) | (_registers.A >> 7);

        _registers.F_Zero(false);
        _registers.F_Subtraction(false);
        _registers.F_HalfCarry(false);
        _registers.F_Carry(rlca > 0xFF);

        _registers.A = (byte) rlca;

        Cycles += 4;
    }

    /// <summary>
    /// Rotates register A right
    /// </summary>
    private void Rrca()
    {
        var rrca = (byte) (_registers.A << 7) | (_registers.A >> 1);

        _registers.F_Zero(false);
        _registers.F_Subtraction(false);
        _registers.F_HalfCarry(false);
        _registers.F_Carry(rrca > 0xFF);

        _registers.A = (byte) rrca;

        Cycles += 4;
    }

    /// <summary>
    /// Rotates register A left through the carry flag
    /// </summary>
    private void Rla()
    {
        var rla = (_registers.A << 1) | _registers.F_Carry();

        _registers.F_Zero(false);
        _registers.F_Subtraction(false);
        _registers.F_HalfCarry(false);
        _registers.F_Carry(rla > 0xFF);

        _registers.A = (byte) rla;
        _registers.PC += 1;
        Cycles += 4;
    }

    /// <summary>
    /// Rotates register A right through the carry flag
    /// </summary>
    private void Rra()
    {
        var rra = (_registers.A >> 1) | (_registers.F_Carry() << 7);

        _registers.F_Zero(false);
        _registers.F_Subtraction(false);
        _registers.F_HalfCarry(false);
        _registers.F_Carry(rra > 0xFF);


        _registers.A = (byte) rra;
        _registers.PC += 1;
        Cycles += 4;
    }

    /// <summary>
    /// Adds two items and sets the F register appropriately
    /// </summary>
    /// <param name="item1">First item to add together</param>
    /// <param name="item2">Second item to add together</param>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    /// <returns>The returned data to be stored</returns>
    private ushort Add(ushort item1, ushort item2, int cycles)
    {
        var add = (ushort) (item1 + item2);

        _registers.F_Subtraction(false);
        _registers.F_HalfCarry(add > 0xFFF);
        _registers.F_Carry(add > 0xFFFF);

        _registers.PC += 1;
        Cycles += cycles;
        return add;
    }

    /// <summary>
    /// Adds two 8-bit items and sets the F registers appropriately
    /// </summary>
    /// <param name="item1">First item to add together</param>
    /// <param name="item2">Second item to add together</param>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    /// <returns>The returned data to be stored</returns>
    private byte Add(byte item1, byte item2, int cycles)
    {
        var data = item1 + item2;

        _registers.F_Subtraction(false);

        _registers.F_Zero(data == 0);

        _registers.F_HalfCarry(data > 0xF);

        _registers.F_Carry(data > 0XFF);

        data &= 0xFF;

        _registers.PC += 1;
        Cycles += cycles;

        return (byte) data;
    }

    private void AddSP()
    {
        var data = _registers.SP + (sbyte) _memory.Read(_registers.PC);

        _registers.F_Zero(false);

        _registers.F_Subtraction(false);

        _registers.F_HalfCarry((_registers.SP & 0xF) + (_memory.Read(_registers.PC) & 0xF) > 0xF);

        _registers.F_Carry(data > 0xFF);

        _registers.SP = (ushort) data;
        _registers.PC += 2;
        Cycles += 16;
    }

    /// <summary>
    /// Adds two 8-bit items and Carry and sets the F registers appropriately
    /// </summary>
    /// <param name="item1">First item to add together</param>
    /// <param name="item2">Second item to add together</param>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    /// <returns>The returned data to be stored</returns>
    private byte AdC(byte item1, byte item2, int cycles)
    {
        var data = item1 + item2 + _registers.F_Carry();

        _registers.F_Subtraction(false);

        _registers.F_Zero(data == 0);

        _registers.F_HalfCarry(data > 0xF);

        _registers.F_Carry(data > 0XFF);

        data &= 0xFF;

        _registers.PC += 1;
        Cycles += cycles;

        return (byte) data;
    }

    /// <summary>
    /// Subtracts two 8-bit items and sets the F registers appropriately
    /// </summary>
    /// <param name="item1">First item to subtract together</param>
    /// <param name="item2">Second item to subtract together</param>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    /// <returns>The returned data to be stored</returns>
    private byte Sub(byte item1, byte item2, int cycles)
    {
        var data = item1 - item2;

        _registers.F_Subtraction(true);

        _registers.F_Zero(data == 0);

        _registers.F_HalfCarry((item1 & 0xF - item2 & 0xF) < 0);

        _registers.F_Carry(data < 0);

        data &= 0xFF;

        _registers.PC += 1;
        Cycles += cycles;

        return (byte) data;
    }

    /// <summary>
    /// Subtracts two 8-bit items, carry and sets the F registers appropriately
    /// </summary>
    /// <param name="item1">First item to subtract together</param>
    /// <param name="item2">Second item to subtract together</param>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    /// <returns>The returned data to be stored</returns>
    private byte SbC(byte item1, byte item2, int cycles)
    {
        var data = item1 - item2 - _registers.F_Carry();

        _registers.F_Subtraction(true);

        _registers.F_Zero(data == 0);

        _registers.F_HalfCarry((item1 & 0xF - item2 & 0xF - _registers.F_Carry()) < 0);

        _registers.F_Carry(data < 0);

        data &= 0xFF;

        _registers.PC += 1;
        Cycles += cycles;

        return (byte) data;
    }

    /// <summary>
    /// Ands two 8-bit items and sets the F registers appropriately
    /// </summary>
    /// <param name="item1">First item to And together</param>
    /// <param name="item2">Second item to And together</param>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    /// <returns>The returned data to be stored</returns>
    private byte And(byte item1, byte item2, int cycles)
    {
        var data = item1 & item2;

        _registers.F_Zero(data == 0);

        _registers.F_Subtraction(false);

        _registers.F_HalfCarry(true);

        _registers.F_Carry(false);

        data &= 0xFF;

        _registers.PC += 1;
        Cycles += cycles;

        return (byte) data;
    }

    /// <summary>
    /// XOR two 8-bit items and sets the F registers appropriately
    /// </summary>
    /// <param name="item1">First item to XOR together</param>
    /// <param name="item2">Second item to XOR together</param>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    /// <returns>The returned data to be stored</returns>
    private byte Xor(byte item1, byte item2, int cycles)
    {
        var data = item1 ^ item2;

        _registers.F_Zero(data == 0);

        _registers.F_Subtraction(false);

        _registers.F_HalfCarry(false);

        _registers.F_Carry(false);

        data &= 0xFF;

        _registers.PC += 1;
        Cycles += cycles;

        return (byte) data;
    }

    /// <summary>
    /// OR two 8-bit items and sets the F registers appropriately
    /// </summary>
    /// <param name="item1">First item to OR together</param>
    /// <param name="item2">Second item to OR together</param>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    /// <returns>The returned data to be stored</returns>
    private byte Or(byte item1, byte item2, int cycles)
    {
        var data = item1 | item2;

        _registers.F_Zero(data == 0);

        _registers.F_Subtraction(false);

        _registers.F_HalfCarry(false);

        _registers.F_Carry(false);

        data &= 0xFF;

        _registers.PC += 1;
        Cycles += cycles;

        return (byte) data;
    }

    /// <summary>
    /// Compare two 8-bit items and sets the F registers appropriately
    /// </summary>
    /// <param name="item1">First item to compare together</param>
    /// <param name="item2">Second item to compare together</param>
    /// <param name="cycles">How many T-Cycles the operation will take</param>
    /// <returns>The returned data to be stored</returns>
    private byte Cp(byte item1, byte item2, int cycles)
    {
        var data = item1 - item2;

        _registers.F_Zero(data == 0);

        _registers.F_Subtraction(true);

        _registers.F_HalfCarry((item1 & 0xF) - (item2 & 0xF) < 0);

        _registers.F_Carry(data < 0);

        data &= 0xFF;

        _registers.PC += 1;
        Cycles += cycles;

        return (byte) data;
    }

    /// <summary>
    /// Jump to the relative location specified by the signed location stored in memory
    /// </summary>
    private void Jr()
    {
        var addr = (sbyte) _memory.Read((ushort) (_registers.PC + 1));
        _registers.PC += 2;
        _registers.PC = (ushort) (_registers.PC + addr);
        Cycles += 12;
    }

    /// <summary>
    /// Jump to the relative location specified by the signed location stored in memory if zero flag is not set
    /// </summary>
    private void JrNz()
    {
        var addr = (sbyte) _memory.Read((ushort) (_registers.PC + 1));
        _registers.PC += 2;
        Cycles += 8;
        if (_registers.F_Zero() << 7 == 0)
        {
            _registers.PC = (ushort) (_registers.PC + addr);
            Cycles += 4;
        }
    }

    /// <summary>
    /// Jump to the relative location specified by the signed location stored in memory if zero flag is set
    /// </summary>
    private void JrZ()
    {
        var addr = (sbyte) _memory.Read((ushort) (_registers.PC + 1));
        _registers.PC += 2;
        Cycles += 8;
        if (_registers.F_Zero() << 7 != 0)
        {
            _registers.PC = (ushort) (_registers.PC + addr);
            Cycles += 4;
        }
    }

    /// <summary>
    /// Jump to the relative location specified by the signed location stored in memory if the carry flag is set
    /// </summary>
    private void JrC()
    {
        var addr = (sbyte) _memory.Read((ushort) (_registers.PC + 1));
        _registers.PC += 2;
        Cycles += 8;
        if (_registers.F_Carry() << 7 != 0)
        {
            _registers.PC = (ushort) (_registers.PC + addr);
            Cycles += 4;
        }
    }

    /// <summary>
    /// Jump to the relative location specified by the signed location stored in memory if compare flag is not set
    /// </summary>
    private void JrNc()
    {
        var addr = (sbyte) _memory.Read((ushort) (_registers.PC + 1));
        _registers.PC += 2;
        Cycles += 8;

        if (_registers.F_Carry() << 7 == 0)
        {
            _registers.PC = (ushort) (_registers.PC + addr);
            Cycles += 4;
        }
    }

    /// <summary>
    /// Flips all bits in register A
    /// </summary>
    private void Cpl()
    {
        _registers.A = (byte) ~_registers.A;
        _registers.F_Subtraction(true);
        _registers.F_HalfCarry(true);
        _registers.PC += 1;
        Cycles += 4;
    }

    /// <summary>
    /// Sets Carry Flag and clears Half Carry and Subtraction
    /// </summary>
    private void Scf()
    {
        _registers.F_Subtraction(false);
        _registers.F_HalfCarry(false);
        _registers.F_Carry(true);

        _registers.PC += 1;
        Cycles += 4;
    }

    /// <summary>
    /// Sets Carry Flag if unset and clears Half Carry and Subtraction
    /// </summary>
    private void Ccf()
    {
        _registers.F_Subtraction(false);
        _registers.F_HalfCarry(false);
        _registers.F_Carry(_registers.F_Carry() << 7 == 0);

        _registers.PC += 1;
        Cycles += 4;
    }

    /// <summary>
    /// Return from the stack if F_Zero is not set
    /// </summary>
    private void RetNz()
    {
        if (_registers.F_Zero() << 7 == 0)
        {
            _registers.PC =
                (ushort) (_memory.Read((ushort) (_registers.SP + 1)) << 8 | _memory.Read(_registers.SP));
            _registers.SP += 2;
            Cycles += 20;
        }
        else
        {
            _registers.PC += 1;
            _registers.PC &= 0xFFFF;
            Cycles += 8;
        }
    }

    /// <summary>
    /// Return from the stack if F_Zero is set
    /// </summary>
    private void RetZ()
    {
        if (_registers.F_Zero() << 7 != 0)
        {
            _registers.PC =
                (ushort) (_memory.Read((ushort) (_registers.SP + 1)) << 8 | _memory.Read(_registers.SP));
            _registers.SP += 2;
            Cycles += 20;
        }
        else
        {
            _registers.PC += 1;
            _registers.PC &= 0xFFFF;
            Cycles += 8;
        }
    }

    /// <summary>
    /// Return from the stack
    /// </summary>
    private void Ret()
    {
        _registers.PC = (ushort) (_memory.Read((ushort) (_registers.SP + 1)) << 8 | _memory.Read(_registers.SP));
        _registers.SP += 2;
        Cycles += 16;
    }

    /// <summary>
    /// Return from the stack if F_Carry is not set
    /// </summary>
    private void RetNc()
    {
        if (_registers.F_Carry() << 7 == 0)
        {
            _registers.PC =
                (ushort) (_memory.Read((ushort) (_registers.SP + 1)) << 8 | _memory.Read(_registers.SP));
            _registers.SP += 2;
            Cycles += 20;
        }
        else
        {
            _registers.PC += 1;
            _registers.PC &= 0xFFFF;
            Cycles += 8;
        }
    }

    /// <summary>
    /// Return from the stack if F_Carry is set
    /// </summary>
    private void RetC()
    {
        if (_registers.F_Carry() << 7 != 0)
        {
            _registers.PC =
                (ushort) (_memory.Read((ushort) (_registers.SP + 1)) << 8 | _memory.Read(_registers.SP));
            _registers.SP += 2;
            Cycles += 20;
        }
        else
        {
            _registers.PC += 1;
            _registers.PC &= 0xFFFF;
            Cycles += 8;
        }
    }

    /// <summary>
    /// Pop the stack into a register
    /// </summary>
    /// <returns>The data to store into the correct register</returns>
    private ushort Pop()
    {
        //var data = (ushort) (_memory.Read(_registers.SP + 1 << 8 | _registers.SP));
        var data = (ushort) (_memory.Read((ushort) (_registers.SP + 1)) << 8 | _memory.Read(_registers.SP));
        _registers.SP += 2;
        _registers.PC += 1;
        Cycles += 12;

        return data;
    }

    /// <summary>
    /// Jump to the location specified by the signed location stored in memory if zero flag is not set
    /// </summary>
    private void JmpNz()
    {
        var data = (ushort) (_memory.Read((ushort) (_registers.PC + 2)) << 8 |
                             _memory.Read((ushort) (_registers.PC + 1)));

        if (_registers.F_Zero() << 7 == 0)
        {
            _registers.PC = data;
            Cycles += 16;
        }
        else
        {
            _registers.PC += 3;
            Cycles += 12;
        }
    }

    /// <summary>
    /// Jump to the location specified by the signed location stored in memory if zero flag is set
    /// </summary>
    private void JmpZ()
    {
        var data = (ushort) (_memory.Read((ushort) (_registers.PC + 2)) << 8 |
                             _memory.Read((ushort) (_registers.PC + 1)));

        if (_registers.F_Zero() << 7 != 0)
        {
            _registers.PC = data;
            Cycles += 16;
        }
        else
        {
            _registers.PC += 3;
            Cycles += 12;
        }
    }

    /// <summary>
    /// Jump to the location specified by the signed location stored in memory
    /// </summary>
    private void Jmp()
    {
        var data = (ushort) (_memory.Read((ushort) (_registers.PC + 2)) << 8 |
                             _memory.Read((ushort) (_registers.PC + 1)));

        _registers.PC = data;
        Cycles += 16;
    }

    /// <summary>
    /// Jump to the location specified by the signed location stored in memory if carry flag is not set
    /// </summary>
    private void JmpNc()
    {
        var data = (ushort) (_memory.Read((ushort) (_registers.PC + 2)) << 8 |
                             _memory.Read((ushort) (_registers.PC + 1)));

        if (_registers.F_Carry() << 7 == 0)
        {
            _registers.PC = data;
            Cycles += 16;
        }
        else
        {
            _registers.PC += 3;
            Cycles += 12;
        }
    }

    /// <summary>
    /// Jump to the location specified by the signed location stored in memory if carry flag is set
    /// </summary>
    private void JmpC()
    {
        var data = (ushort) (_memory.Read((ushort) (_registers.PC + 2)) << 8 |
                             _memory.Read((ushort) (_registers.PC + 1)));

        if (_registers.F_Carry() << 7 != 0)
        {
            _registers.PC = data;
            Cycles += 16;
        }
        else
        {
            _registers.PC += 3;
            Cycles += 12;
        }
    }

    private void JmpHL()
    {
        _registers.PC = _registers.HL;
        Cycles += 4;
    }

    /// <summary>
    /// 
    /// </summary>
    private void CallNz()
    {
        var data = (ushort) (_memory.Read((ushort) (_registers.PC + 2)) << 8 |
                             _memory.Read((ushort) (_registers.PC + 1)));
        if (_registers.F_Zero() << 7 == 0)
        {
            _memory.Write((ushort) (_registers.SP - 1), (byte) ((ushort) (_registers.PC + 3) >> 8));
            _memory.Write((ushort) (_registers.SP - 2), (byte) ((ushort) (_registers.PC + 3) & 0xFF));
            _registers.PC = data;
            _registers.SP -= 2;
            Cycles += 24;
        }
        else
        {
            _registers.PC += 3;
            _registers.PC &= 0xFFFF;
            Cycles += 12;
        }
    }

    /// <summary>
    /// 
    /// </summary>
    private void CallZ()
    {
        var data = (ushort) (_memory.Read((ushort) (_registers.PC + 2)) << 8 |
                             _memory.Read((ushort) (_registers.PC + 1)));
        if (_registers.F_Zero() << 7 != 0)
        {
            _memory.Write((ushort) (_registers.SP - 1), (byte) ((ushort) (_registers.PC + 3) >> 8));
            _memory.Write((ushort) (_registers.SP - 2), (byte) ((ushort) (_registers.PC + 3) & 0xFF));
            _registers.PC = data;
            _registers.SP -= 2;
            Cycles += 24;
        }
        else
        {
            _registers.PC += 3;
            _registers.PC &= 0xFFFF;
            Cycles += 12;
        }
    }

    /// <summary>
    /// 
    /// </summary>
    private void Call()
    {
        var location = (ushort) (_memory.Read((ushort) (_registers.PC + 2)) << 8 |
                                 _memory.Read((ushort) (_registers.PC + 1)));

        _memory.Write((ushort) (_registers.SP - 1), (byte) ((ushort) (_registers.PC + 3) >> 8));
        _memory.Write((ushort) (_registers.SP - 2), (byte) ((ushort) (_registers.PC + 3) & 0xFF));

        _registers.PC = location;
        _registers.SP -= 2;
        Cycles += 24;
    }

    /// <summary>
    /// 
    /// </summary>
    private void CallNc()
    {
        var data = (ushort) (_memory.Read((ushort) (_registers.PC + 2)) << 8 |
                             _memory.Read((ushort) (_registers.PC + 1)));
        if (_registers.F_Carry() << 7 == 0)
        {
            _memory.Write((ushort) (_registers.SP - 1), (byte) ((ushort) (_registers.PC + 3) >> 8));
            _memory.Write((ushort) (_registers.SP - 2), (byte) ((ushort) (_registers.PC + 3) & 0xFF));
            _registers.PC = data;
            _registers.SP -= 2;
            Cycles += 24;
        }
        else
        {
            _registers.PC += 3;
            _registers.PC &= 0xFFFF;
            Cycles += 12;
        }
    }

    /// <summary>
    /// 
    /// </summary>
    private void CallC()
    {
        var data = (ushort) (_memory.Read((ushort) (_registers.PC + 2)) << 8 |
                             _memory.Read((ushort) (_registers.PC + 1)));
        if (_registers.F_Carry() << 7 != 0)
        {
            _memory.Write((ushort) (_registers.SP - 1), (byte) ((ushort) (_registers.PC + 3) >> 8));
            _memory.Write((ushort) (_registers.SP - 2), (byte) ((ushort) (_registers.PC + 3) & 0xFF));
            _registers.PC = data;
            _registers.SP -= 2;
            Cycles += 24;
        }
        else
        {
            _registers.PC += 3;
            _registers.PC &= 0xFFFF;
            Cycles += 12;
        }
    }

    /// <summary>
    /// Pop to the stack from a register
    /// </summary>
    private void Push(ushort register)
    {
        _memory.Write((ushort) (_registers.SP - 1), (byte) (register >> 8));
        _memory.Write((ushort) (_registers.SP - 2), (byte) (register & 0xFF));

        _registers.SP -= 2;
        _registers.PC += 1;
        Cycles += 16;
    }

    private void Rst(int pc)
    {
        _memory.Write((ushort) (_registers.SP - 1), (byte) (_registers.PC + 1 >> 8));
        _memory.Write((ushort) (_registers.SP - 2), (byte) (_registers.PC + 1 & 0xFF));

        _registers.SP -= 2;
        _registers.PC = (ushort) pc;
        Cycles += 16;
    }
}