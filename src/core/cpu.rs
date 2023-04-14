use std::fs::{OpenOptions};
use std::io::Write;
use crate::core::flag_type::FlagType;
use crate::core::flag_type::FlagType::*;
use crate::core::memory::Memory;
use crate::core::register_type::RegisterType8::*;
use crate::core::register_type::RegisterType16::*;
use crate::core::register_type::{RegisterType16, RegisterType8};
use crate::core::registers::Registers;

pub struct CPU {
    pub memory: Memory,
    pub register: Registers,
    cycles: i32
}


impl CPU {
    pub fn new() -> Self {
        let mut register = Registers::new();
        let mut memory = Memory::new();

        if memory.bootrom_loaded {
            register.write_16(PC, 0x100);
        }

        Self {
            memory,
            register,
            cycles: 0,
        }
    }

    pub fn tick(&mut self) {
        let mut file = OpenOptions::new()
            .append(true)
            .open("/Users/hevey/Development/PlayCade/debugging/gb.txt")
            .unwrap();

        if let Err(e) = writeln!(file, "{}", format!("A: {:02X} F: {:02X} B: {:02X} C: {:02X} D: {:02X} E: {:02X} H: {:02X} L: {:02X} SP: {:04X} PC: 00:{:04X} ({:02X} {:02X} {:02X} {:02X})",
                 self.register.read_8(A),
                 self.register.read_8(F),
                 self.register.read_8(B),
                 self.register.read_8(C),
                 self.register.read_8(D),
                 self.register.read_8(E),
                 self.register.read_8(H),
                 self.register.read_8(L),
                 self.register.read_16(SP),
                 self.register.read_16(PC),
                 self.memory.read(self.register.read_16(PC)),
                 self.memory.read(self.register.read_16(PC)+1),
                 self.memory.read(self.register.read_16(PC)+2),
                 self.memory.read(self.register.read_16(PC)+3)
            )
        ) {
            eprintln!("Couldn't write to file: {}", e);
        }
        // println!("PC: {:#06x}", self.register.read_16(PC));
        // println!("A: {:02X} F: {:02X} B: {:02X} C: {:02X} D: {:02X} E: {:02X} H: {:02X} L: {:02X} SP: {:04X} PC: 00:{:04X} ({:02X} {:02X} {:02X} {:02X})",
        //          self.register.read_8(A),
        //          self.register.read_8(F),
        //          self.register.read_8(B),
        //          self.register.read_8(C),
        //          self.register.read_8(D),
        //          self.register.read_8(E),
        //          self.register.read_8(H),
        //          self.register.read_8(L),
        //          self.register.read_16(SP),
        //          self.register.read_16(PC),
        //          self.memory.read(self.register.read_16(PC)),
        //          self.memory.read(self.register.read_16(PC)+1),
        //          self.memory.read(self.register.read_16(PC)+2),
        //          self.memory.read(self.register.read_16(PC)+3));
        let opcode = self.increment_pc();


        match opcode {
            0x00 => { self.nop(); }
            0x01 => { self.ld_r16_nn(BC); }
            0x02 => { self.ld_indirect_bc_a(); }
            0x03 => { self.inc_r16(BC); }
            0x04 => { self.inc_r8(B); }
            0x05 => { self.dec_r8(B); }
            0x06 => { self.ld_r8_n(B); }
            0x07 => { panic!("RLCA not implemented"); } //TODO: RLCA
            0x08 => { self.ld_indirect_nn_sp(); }
            0x09 => { self.add_hl_r16(BC); }
            0x0A => { self.ld_a_indirect_bc(); }
            0x0B => { self.dec_r16(BC); }
            0x0C => { self.inc_r8(C); }
            0x0D => { self.dec_r8(C); }
            0x0E => { self.ld_r8_n(C); }
            0x0F => { panic!("RRCA not implemented"); } //TODO: RRCA
            0x10 => { panic!("STOP not implemented"); } //TODO: STOP
            0x11 => { self.ld_r16_nn(DE); }
            0x12 => { self.ld_indirect_de_a(); }
            0x13 => { self.inc_r16(DE); }
            0x14 => { self.inc_r8(D); }
            0x15 => { self.dec_r8(D); }
            0x16 => { self.ld_r8_n(D); }
            0x17 => { panic!("RLA not implemented"); } //TODO: RLA
            0x18 => { self.jr_e(); }
            0x19 => { self.add_hl_r16(DE); }
            0x1A => { self.ld_a_indirect_de(); }
            0x1B => { self.dec_r16(DE); }
            0x1C => { self.inc_r8(E); }
            0x1D => { self.dec_r8(E); }
            0x1E => { self.ld_r8_n(E); }
            0x1F => { panic!("RRA Not implemented")} //TODO: RRA
            0x20 => { self.jr_nf_e(Zero); }
            0x21 => { self.ld_r16_nn(HL); }
            0x22 => { self.ld_indirect_hl_inc_a(); }
            0x23 => { self.inc_r16(HL); }
            0x24 => { self.inc_r8(H); }
            0x25 => { self.dec_r8(H); }
            0x26 => { self.ld_r8_n(H); }
            0x27 => { self.daa(); }
            0x28 => { self.jr_f_e(Zero); }
            0x29 => { self.add_hl_r16(HL); }
            0x2A => { self.ld_a_indirect_hl_inc(); }
            0x2B => { self.dec_r16(HL); }
            0x2C => { self.inc_r8(L); }
            0x2D => { self.dec_r8(L); }
            0x2E => { self.ld_r8_n(L); }
            0x2F => { self.cpl(); }
            0x30 => { self.jr_nf_e(Carry); }
            0x31 => { self.ld_r16_nn(SP); }
            0x32 => { self.ld_indirect_hl_dec_a(); }
            0x33 => { self.inc_r16(SP); }
            0x34 => { self.inc_indirect_hl(); }
            0x35 => { self.dec_indirect_hl(); }
            0x36 => { self.ld_indirect_hl_n(); }
            0x37 => { self.scf(); }
            0x38 => { self.jr_f_e(Carry); }
            0x39 => { self.add_hl_r16(SP); }
            0x3A => { self.ld_a_indirect_hl_dec(); }
            0x3B => { self.dec_r16(SP); }
            0x3C => { self.inc_r8(A); }
            0x3D => { self.dec_r8(A); }
            0x3E => { self.ld_r8_n(A); }
            0x3F => { self.ccf(); }
            0x40 => { self.ld_r8_r8(B, B); }
            0x41 => { self.ld_r8_r8(B, C); }
            0x42 => { self.ld_r8_r8(B, D); }
            0x43 => { self.ld_r8_r8(B, E); }
            0x44 => { self.ld_r8_r8(B, H); }
            0x45 => { self.ld_r8_r8(B, L); }
            0x46 => { self.ld_r8_indirect_hl(B); }
            0x47 => { self.ld_r8_r8(B, A); }
            0x48 => { self.ld_r8_r8(C, B); }
            0x49 => { self.ld_r8_r8(C, C); }
            0x4A => { self.ld_r8_r8(C, D); }
            0x4B => { self.ld_r8_r8(C, E); }
            0x4C => { self.ld_r8_r8(C, H); }
            0x4D => { self.ld_r8_r8(C, L); }
            0x4E => { self.ld_r8_indirect_hl(C); }
            0x4F => { self.ld_r8_r8(C, A); }
            0x50 => { self.ld_r8_r8(D, B); }
            0x51 => { self.ld_r8_r8(D, C); }
            0x52 => { self.ld_r8_r8(D, D); }
            0x53 => { self.ld_r8_r8(D, E); }
            0x54 => { self.ld_r8_r8(D, H); }
            0x55 => { self.ld_r8_r8(D, L); }
            0x56 => { self.ld_r8_indirect_hl(D);}
            0x57 => { self.ld_r8_r8(D, A); }
            0x58 => { self.ld_r8_r8(E, B); }
            0x59 => { self.ld_r8_r8(E, C); }
            0x5A => { self.ld_r8_r8(E, D); }
            0x5B => { self.ld_r8_r8(E, E); }
            0x5C => { self.ld_r8_r8(E, H); }
            0x5D => { self.ld_r8_r8(E, L); }
            0x5E => { self.ld_r8_indirect_hl(E); }
            0x5F => { self.ld_r8_r8(E, A); }
            0x60 => { self.ld_r8_r8(H, B); }
            0x61 => { self.ld_r8_r8(H, C); }
            0x62 => { self.ld_r8_r8(H, D); }
            0x63 => { self.ld_r8_r8(H, E); }
            0x64 => { self.ld_r8_r8(H, H); }
            0x65 => { self.ld_r8_r8(H, L); }
            0x66 => { self.ld_r8_indirect_hl(H); }
            0x67 => { self.ld_r8_r8(H, A); }
            0x68 => { self.ld_r8_r8(L, B); }
            0x69 => { self.ld_r8_r8(L, C); }
            0x6A => { self.ld_r8_r8(L, D); }
            0x6B => { self.ld_r8_r8(L, E); }
            0x6C => { self.ld_r8_r8(L, H); }
            0x6D => { self.ld_r8_r8(L, L); }
            0x6E => { self.ld_r8_indirect_hl(L); }
            0x6F => { self.ld_r8_r8(L, A); }
            0x70 => { self.ld_indirect_hl_r8(B); }
            0x71 => { self.ld_indirect_hl_r8(C); }
            0x72 => { self.ld_indirect_hl_r8(D); }
            0x73 => { self.ld_indirect_hl_r8(E); }
            0x74 => { self.ld_indirect_hl_r8(H); }
            0x75 => { self.ld_indirect_hl_r8(L); }
            0x76 => { panic!("HALT not implemented"); } //TODO: HALT
            0x77 => { self.ld_indirect_hl_r8(A); }
            0x78 => { self.ld_r8_r8(A, B); }
            0x79 => { self.ld_r8_r8(A, C); }
            0x7A => { self.ld_r8_r8(A, D); }
            0x7B => { self.ld_r8_r8(A, E); }
            0x7C => { self.ld_r8_r8(A, H); }
            0x7D => { self.ld_r8_r8(A, L); }
            0x7E => { self.ld_r8_indirect_hl(A); }
            0x7F => { self.ld_r8_r8(A, A); }
            0x80 => { self.add_a_r8(B); }
            0x81 => { self.add_a_r8(C); }
            0x82 => { self.add_a_r8(D); }
            0x83 => { self.add_a_r8(E); }
            0x84 => { self.add_a_r8(H); }
            0x85 => { self.add_a_r8(L); }
            0x86 => { self.add_a_indirect_hl(); }
            0x87 => { self.add_a_r8(A); }
            0x88 => { self.adc_a_r8(B); }
            0x89 => { self.adc_a_r8(C); }
            0x8A => { self.adc_a_r8(D); }
            0x8B => { self.adc_a_r8(E); }
            0x8C => { self.adc_a_r8(H); }
            0x8D => { self.adc_a_r8(L); }
            0x8E => { self.adc_a_indirect_hl(); }
            0x8F => { self.adc_a_r8(A); }
            0x90 => { self.sub_a_r8(B); }
            0x91 => { self.sub_a_r8(C); }
            0x92 => { self.sub_a_r8(D); }
            0x93 => { self.sub_a_r8(E); }
            0x94 => { self.sub_a_r8(H); }
            0x95 => { self.sub_a_r8(L); }
            0x96 => { self.sub_a_indirect_hl(); }
            0x97 => { self.sub_a_r8(A); }
            0x98 => { self.sbc_a_r8(B); }
            0x99 => { self.sbc_a_r8(C); }
            0x9A => { self.sbc_a_r8(D); }
            0x9B => { self.sbc_a_r8(E); }
            0x9C => { self.sbc_a_r8(H); }
            0x9D => { self.sbc_a_r8(L); }
            0x9E => { self.sbc_a_indirect_hl(); }
            0x9F => { self.sbc_a_r8(A); }
            0xA0 => { self.and_a_r8(B); }
            0xA1 => { self.and_a_r8(C); }
            0xA2 => { self.and_a_r8(D); }
            0xA3 => { self.and_a_r8(E); }
            0xA4 => { self.and_a_r8(H); }
            0xA5 => { self.and_a_r8(L); }
            0xA6 => { self.and_a_indirect_hl(); }
            0xA7 => { self.and_a_r8(A); }
            0xA8 => { self.xor_a_r8(B); }
            0xA9 => { self.xor_a_r8(C); }
            0xAA => { self.xor_a_r8(D); }
            0xAB => { self.xor_a_r8(E); }
            0xAC => { self.xor_a_r8(H); }
            0xAD => { self.xor_a_r8(L); }
            0xAE => { self.xor_a_indirect_hl(); }
            0xAF => { self.xor_a_r8(A); }
            0xB0 => { self.or_a_r8(B); }
            0xB1 => { self.or_a_r8(C); }
            0xB2 => { self.or_a_r8(D); }
            0xB3 => { self.or_a_r8(E); }
            0xB4 => { self.or_a_r8(H); }
            0xB5 => { self.or_a_r8(L); }
            0xB6 => { self.or_a_indirect_hl();}
            0xB7 => { self.or_a_r8(A); }
            0xB8 => { self.cp_r8(B); }
            0xB9 => { self.cp_r8(C); }
            0xBA => { self.cp_r8(D); }
            0xBB => { self.cp_r8(E); }
            0xBC => { self.cp_r8(H); }
            0xBD => { self.cp_r8(L); }
            0xBE => { self.cp_indirect_hl(); }
            0xBF => { self.cp_r8(A); }
            0xC0 => { self.ret_nf(Zero); }
            0xC1 => { self.pop(BC); }
            0xC2 => { self.jp_nf_nn(Zero); }
            0xC3 => { self.jp_nn(); }
            0xC4 => { self.call_nf_nn(Zero); }
            0xC5 => { self.push(BC); }
            0xC6 => { self.add_a_n(); }
            0xC7 => { self.rst(0x00); }
            0xC8 => { self.ret_f(Zero); }
            0xC9 => { self.ret(); }
            0xCA => { self.jp_f_nn(Zero); }
            0xCB => { panic!("CB op not implemented"); } //TODO: CB op
            0xCC => { self.call_f_nn(Zero); }
            0xCD => { self.call_nn(); }
            0xCE => { self.adc_a_n(); }
            0xCF => { self.rst(0x08); }
            0xD0 => { self.ret_nf(Carry); }
            0xD1 => { self.pop(DE); }
            0xD2 => { self.jp_nf_nn(Carry); }
            0xD3 => { } // NOT USED
            0xD4 => { self.call_nf_nn(Carry); }
            0xD5 => { self.push(DE); }
            0xD6 => { self.sub_a_n(); }
            0xD7 => { self.rst(0x10); }
            0xD8 => { self.ret_f(Carry); }
            0xD9 => { self.reti();}
            0xDA => { self.jp_f_nn(Carry); }
            0xDB => { } // NOT USED
            0xDC => { self.call_f_nn(Carry); }
            0xDD => { } // NOT USED
            0xDE => { self.sbc_a_n(); }
            0xDF => { self.rst(0x18); }
            0xE0 => { self.ldh_indirect_n_a(); }
            0xE1 => { self.pop(HL); }
            0xE2 => { self.ldh_indirect_c_a(); }
            0xE3 => { } // NOT USED
            0xE4 => { } // NOT USED
            0xE5 => { self.push(HL); }
            0xE6 => { self.and_a_n(); }
            0xE7 => { self.rst(0x20); }
            0xE8 => { panic!("SP, e not implemented"); } //TODO: ADD SP, e
            0xE9 => { self.jp_hl(); }
            0xEA => { self.ld_indirect_nn_a(); }
            0xEB => { } // NOT USED
            0xEC => { } // NOT USED
            0xED => { } // NOT USED
            0xEE => { self.xor_a_n(); }
            0xEF => { self.rst(0x28); }
            0xF0 => { self.ldh_a_indirect_n(); }
            0xF1 => { self.pop(AF); }
            0xF2 => { self.ldh_a_indirect_c(); }
            0xF3 => { self.di(); }
            0xF4 => { } // NOT USED
            0xF5 => { self.push(AF); }
            0xF6 => { self.or_a_n(); }
            0xF7 => { self.rst(0x30); }
            0xF8 => { panic!("LD, SP+e not implemented") } //TODO: LD, SP+e
            0xF9 => { self.ld_sp_hl(); }
            0xFA => { self.ld_a_indirect_nn(); }
            0xFB => { self.ei(); }
            0xFC => { } // NOT USED
            0xFD => { } // NOT USED
            0xFE => { self.cp_n(); }
            0xFF => { self.rst(0x38); }
            _ => {
                let msg = format!("opcode: {}, not implemented", opcode);
                panic!(r"{}", msg);
            }
        }
    }

    fn increment_pc(&mut self) -> u8 {
        let mut pc = self.register.read_16(PC);
        let value = self.memory.read(pc);
        pc += 1;
        self.register.write_16(PC, pc);

        value
    }

    fn increment_hl(&mut self) -> u8 {
        let mut hl = self.register.read_16(HL);
        let value = self.memory.read(hl);
        hl += 1;
        self.register.write_16(HL, hl);

        value
    }

    fn decrement_hl(&mut self) -> u8 {
        let mut hl = self.register.read_16(HL);
        let value = self.memory.read(hl);
        hl -= 1;
        self.register.write_16(HL, hl);

        value
    }

    fn increment_sp(&mut self) -> u8 {
        let mut sp = self.register.read_16(SP);
        let value = self.memory.read(sp);
        sp = sp.wrapping_add(1);
        self.register.write_16(SP, sp);

        value
    }

    fn decrement_sp(&mut self) -> u8 {
        let mut sp = self.register.read_16(SP);
        let value = self.memory.read(sp);
        sp -= 1;
        self.register.write_16(SP, sp);

        value
    }

    /// Loads r2 into r1
    fn ld_r8_r8(&mut self, r1: RegisterType8, r2: RegisterType8) {
        self.register.write_8(r1, self.register.read_8(r2));
        self.cycles += 4;
    }

    fn ld_r8_n(&mut self, r: RegisterType8) {
        let value = self.increment_pc();
        self.register.write_8(r, value);
        self.cycles += 8;
    }

    fn ld_r8_indirect_hl(&mut self, r: RegisterType8) {
        self.register.write_8(r, self.memory.read(self.register.read_16(HL)));
        self.cycles += 8;
    }

    fn ld_indirect_hl_r8(&mut self, r: RegisterType8) {
        self.memory.write(self.register.read_16(HL), self.register.read_8(r));
        self.cycles += 8;
    }

    fn ld_indirect_hl_n(&mut self) {
        let value = self.increment_pc();
        self.memory.write(self.register.read_16(HL), value);
        self.cycles += 12;
    }

    fn ld_a_indirect_bc(&mut self) {
        let value = self.memory.read(self.register.read_16(BC));
        self.register.write_8(A, value);
        self.cycles += 8;
    }

    fn ld_a_indirect_de(&mut self) {
        let value = self.memory.read(self.register.read_16(DE));
        self.register.write_8(A, value);
        self.cycles += 8;
    }

    fn ld_indirect_bc_a(&mut self) {
        let value = self.register.read_8(A);
        self.memory.write(self.register.read_16(BC), value);
        self.cycles += 8;
    }

    fn ld_indirect_de_a(&mut self) {
        let value = self.register.read_8(A);
        self.memory.write(self.register.read_16(DE), value);
        self.cycles += 8;
    }

    fn ld_a_indirect_nn(&mut self) {
        let lsb = self.increment_pc();
        let msb = self.increment_pc();

        let value: u16 = (msb as u16) << 8 | lsb as u16;

        self.register.write_8(A, self.memory.read(value));
        self.cycles += 16;
    }

    fn ld_indirect_nn_a(&mut self) {
        let lsb = self.increment_pc();
        let msb = self.increment_pc();

        let value: u16 = (msb as u16) << 8 | lsb as u16;

        self.memory.write(value, self.register.read_8(A));
        self.cycles += 16;
    }

    fn ldh_a_indirect_c(&mut self) {
        let lsb = self.register.read_8(C);
        let msb = 0xFF as u8;

        let value: u16 = (msb as u16) << 8 | lsb as u16;

        self.register.write_8(A, self.memory.read(value));
        self.cycles += 8;
    }

    fn ldh_indirect_c_a(&mut self) {
        let lsb = self.register.read_8(C);
        let msb = 0xFF as u8;

        let location: u16 = (lsb as u16) << 8 | msb as u16;

        self.memory.write(location, self.register.read_8(A));
        self.cycles += 8;
    }

    fn ldh_a_indirect_n(&mut self) {
        let lsb = self.increment_pc();
        let msb = 0xFF as u8;

        let value: u16 = (msb as u16) << 8 | lsb as u16;

        self.register.write_8(A, self.memory.read(value));
        self.cycles += 12;
    }

    fn ldh_indirect_n_a(&mut self) {
        let lsb = self.increment_pc();
        let msb = 0xFF as u8;

        let location: u16 = (msb as u16) << 8 | lsb as u16;

        self.memory.write(location, self.register.read_8(A));
        self.cycles += 12;
    }

    fn ld_a_indirect_hl_dec(&mut self) {
        let value = self.decrement_hl();

        self.register.write_8(A, value);
        self.cycles += 8;
    }

    fn ld_indirect_hl_dec_a(&mut self) {
        let value = self.register.read_8(A);

        self.memory.write(self.register.read_16(HL), value);

        self.decrement_hl();
        self.cycles += 8;
    }

    fn ld_a_indirect_hl_inc(&mut self) {
        let value = self.increment_hl();

        self.register.write_8(A, value);
        self.cycles += 8;
    }

    fn ld_indirect_hl_inc_a(&mut self) {
        let value = self.register.read_8(A);

        self.memory.write(self.register.read_16(HL), value);

        self.increment_hl();
        self.cycles += 8;
    }

    // 16-bit Load instructions

    fn ld_r16_nn(&mut self, r: RegisterType16) {
        let lsb = self.increment_pc();
        let msb = self.increment_pc();

        let value: u16 = (msb as u16) << 8 | lsb as u16;

        self.register.write_16(r, value);

        self.cycles += 12;
    }

    fn ld_indirect_nn_sp(&mut self) {
        let lsb = self.increment_pc();
        let msb = self.increment_pc();
        let sp = self.register.read_16(SP);

        let mut location: u16 = (lsb as u16) << 8 | msb as u16;

        self.memory.write(location, (sp >> 8) as u8);
        location += 1;
        self.memory.write(location, sp as u8);

        self.cycles += 20;
    }

    fn ld_sp_hl(&mut self) {
        self.register.write_16(SP, self.register.read_16(HL));

        self.cycles += 8;
    }

    fn push(&mut self, r: RegisterType16) {
        self.decrement_sp();
        let mut sp = self.register.read_16(SP);
        let reg = self.register.read_16(r);

        self.memory.write(sp, (reg >> 8) as u8);

        self.decrement_sp();
        sp = self.register.read_16(SP);

        self.memory.write(sp, reg as u8);

        self.cycles += 16;

    }

    fn pop(&mut self, r: RegisterType16) {
        let lsb = self.increment_sp();
        let msb = self.increment_sp();

        let value: u16 = (msb as u16) << 8 | lsb as u16;

        self.register.write_16(r, value);
        self.cycles += 12;
    }

    // 8-bit arithmetic and logical instructions

    fn add_a_r8(&mut self, r: RegisterType8) {
        let a = self.register.read_8(A);
        let register = self.register.read_8(r);
        let result = a.wrapping_add(register);

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });

        self.cycles += 4;
    }

    fn add_a_indirect_hl(&mut self) {
        let a = self.register.read_8(A);
        let register = self.memory.read(self.register.read_16(HL));
        let result = a.wrapping_add(register);

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn add_a_n(&mut self) {
        let a = self.register.read_8(A);
        let register = self.increment_pc();
        let result = register.wrapping_add(a);

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(Carry, if result as u16 > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if (result & 0xf) + (1 & 0xf) > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn add_hl_r16(&mut self, r: RegisterType16) {
        let hl = self.register.read_16(HL);
        let register = self.register.read_16(r);
        let result = hl.wrapping_add(register);

        self.register.write_16(HL, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });

        self.cycles += 4;
    }

    fn adc_a_r8(&mut self, r: RegisterType8) {
        let a = self.register.read_8(A);
        let register = self.register.read_8(r);
        let carry = if self.register.read_flag(Carry) { 1 } else { 0 };
        let result = a.wrapping_add(carry).wrapping_add(register);

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });

        self.cycles += 4;
    }

    fn adc_a_indirect_hl(&mut self) {
        let a = self.register.read_8(A);
        let register = self.memory.read(self.register.read_16(HL));
        let carry = if self.register.read_flag(Carry) { 1 } else { 0 };
        let result = a.wrapping_add(register).wrapping_add(carry);

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn adc_a_n(&mut self) {
        let a = self.register.read_8(A);
        let register = self.increment_pc();
        let carry = if self.register.read_flag(Carry) { 1 } else { 0 };
        let result = a.wrapping_add(register).wrapping_add(carry);

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn sub_a_r8(&mut self, r: RegisterType8) {
        let a = self.register.read_8(A);
        let register = self.register.read_8(r);
        let result = a.wrapping_sub(register);

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });

        self.cycles += 4;
    }

    fn sub_a_indirect_hl(&mut self) {
        let a = self.register.read_8(A);
        let register = self.memory.read(self.register.read_16(HL));
        let result = a.wrapping_sub(register);

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn sub_a_n(&mut self) {
        let a = self.register.read_8(A);
        let register = self.increment_pc();
        let result = a.wrapping_sub(register);

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn sbc_a_r8(&mut self, r: RegisterType8) {
        let a = self.register.read_8(A);
        let register = self.register.read_8(r);
        let carry = if self.register.read_flag(Carry) { 1 } else { 0 };
        let result = a.wrapping_sub(carry).wrapping_sub(register);

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });

        self.cycles += 4;
    }

    fn sbc_a_indirect_hl(&mut self) {
        let a = self.register.read_8(A);
        let register = self.memory.read(self.register.read_16(HL));
        let carry = if self.register.read_flag(Carry) { 1 } else { 0 };
        let result = a.wrapping_sub(carry).wrapping_sub(register);

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn sbc_a_n(&mut self) {
        let a = self.register.read_8(A);
        let register = self.increment_pc();
        let carry = if self.register.read_flag(Carry) { 1 } else { 0 };
        let result = a.wrapping_sub(carry).wrapping_sub(register);

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn cp_r8(&mut self, r: RegisterType8) {
        let a = self.register.read_8(A);
        let register = self.register.read_8(r);
        let result = a.wrapping_sub(register);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });

        self.cycles += 4;
    }

    fn cp_indirect_hl(&mut self) {
        let a = self.register.read_8(A);
        let register = self.memory.read(self.register.read_16(HL));
        let result = a.wrapping_sub(register);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn cp_n(&mut self) {
        let a = self.register.read_8(A);
        let register = self.increment_pc();
        let result = a.wrapping_sub(register);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn inc_r8(&mut self, r: RegisterType8) {
        let register = self.register.read_8(r);
        let result = register.wrapping_add(1);

        self.register.write_8(r, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });
    }

    fn inc_r16(&mut self, r: RegisterType16) {
        let register = self.register.read_16(r);
        let result = register + 1;

        self.register.write_16(r, result);

        // self.register.write_flag(Zero, if result == 0 { true } else { false });
        // self.register.write_flag(Subtraction, false);
        // self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });
        // self.register.write_flag(Carry, if (register & 0xff) + (1 & 0xff) > 0xFF { true } else { false }); //TODO: confirm this is right

        self.cycles += 8;
    }

    fn inc_indirect_hl(&mut self) {
        let register = self.memory.read(self.register.read_16(HL));
        let result = register + 1;

        self.memory.write(self.register.read_16(HL), result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });
    }

    fn dec_r8(&mut self, r: RegisterType8) {
        let register = self.register.read_8(r);
        let result = register - 1;

        self.register.write_8(r, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(HalfCarry, if (register & 0xf) < (result & 0xf) { true } else { false });
    }

    fn dec_r16(&mut self, r: RegisterType16) {
        let register = self.register.read_16(r);
        let result = register - 1;

        self.register.write_16(r, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });
        //TODO: does Carry flag need to be set here?
    }

    fn dec_indirect_hl(&mut self) {
        let register = self.memory.read(self.register.read_16(HL));
        let result = register - 1;

        self.memory.write(self.register.read_16(HL), result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(HalfCarry, if (register & 0xf) + (1 & 0xf) > 0xF { true } else { false });
    }

    fn and_a_r8(&mut self, r: RegisterType8) {
        let a = self.register.read_8(A);
        let reg = self.register.read_8(r);
        let result = a & reg;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(HalfCarry, true);
        self.register.write_flag(Carry, false);

        self.cycles += 4;
    }

    fn and_a_indirect_hl(&mut self) {
        let a = self.register.read_8(A);
        let value = self.memory.read(self.register.read_16(HL));
        let result = a & value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(HalfCarry, true);
        self.register.write_flag(Carry, false);

        self.cycles += 8;
    }

    fn and_a_n(&mut self) {
        let a = self.register.read_8(A);
        let value = self.increment_pc();
        let result = a & value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(HalfCarry, true);
        self.register.write_flag(Carry, false);

        self.cycles += 8;
    }

    fn or_a_r8(&mut self, r: RegisterType8) {
        let a = self.register.read_8(A);
        let value = self.register.read_8(r);
        let result = a | value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(HalfCarry, false);
        self.register.write_flag(Carry, false);

        self.cycles += 4;
    }

    fn or_a_indirect_hl(&mut self) {
        let a = self.register.read_8(A);
        let value = self.memory.read(self.register.read_16(HL));
        let result = a | value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(HalfCarry, false);
        self.register.write_flag(Carry, false);

        self.cycles += 8;
    }

    fn or_a_n(&mut self) {
        let a = self.register.read_8(A);
        let value = self.increment_pc();
        let result = a | value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(HalfCarry, false);
        self.register.write_flag(Carry, false);

        self.cycles += 8;
    }

    fn xor_a_r8(&mut self, r: RegisterType8) {
        let a = self.register.read_8(A);
        let value = self.register.read_8(r);
        let result = a ^ value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(HalfCarry, false);
        self.register.write_flag(Carry, false);

        self.cycles += 4;
    }

    fn xor_a_indirect_hl(&mut self) {
        let a = self.register.read_8(A);
        let value = self.memory.read(self.register.read_16(HL));
        let result = a ^ value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(HalfCarry, false);
        self.register.write_flag(Carry, false);

        self.cycles += 8;
    }

    fn xor_a_n(&mut self) {
        let a = self.register.read_8(A);
        let value = self.increment_pc();
        let result = a ^ value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(HalfCarry, false);
        self.register.write_flag(Carry, false);

        self.cycles += 8;
    }

    fn ccf(&mut self) {
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(HalfCarry, false);

        if self.register.read_flag(Carry) {
            self.register.write_flag(Carry, false);
        } else {
            self.register.write_flag(Carry, true);
        }

        self.cycles += 4;
    }

    fn scf(&mut self) {
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(HalfCarry, false);
        self.register.write_flag(Carry, true);

        self.cycles += 4;
    }


    fn daa(&mut self) {
        let neg_flag = self.register.read_flag(Subtraction);
        let carry_flag = self.register.read_flag(Carry);
        let halfcarry_flag = self.register.read_flag(HalfCarry);

        let mut carry = false;

        if !neg_flag {
            if carry_flag || self.register.read_8(A) > 0x99 {
                self.register.write_8(A, self.register.read_8(A) + 0x60);
                carry = true;
            }
            if halfcarry_flag || self.register.read_8(A) & 0x0F > 0x09 {
                self.register.write_8(A, self.register.read_8(A) + 0x06);
            }
        } else if carry_flag {
            carry = true;
            self.register.write_8(A, if halfcarry_flag { self.register.read_8(A) + 0x9a } else { self.register.read_8(A) + 0xa0 });
        } else if halfcarry_flag {
            self.register.write_8(A, self.register.read_8(A) + 0xfa);
        }

        self.register.write_flag(Zero, self.register.read_8(A) == 0);
        self.register.write_flag(HalfCarry, false);
        self.register.write_flag(Carry, carry);

        self.cycles += 4;
    }

    fn cpl(&mut self) {
        self.register.write_8(A, !self.register.read_8(A));

        self.register.write_flag(Subtraction, true);
        self.register.write_flag(HalfCarry, true);
    }


    fn jp_nn(&mut self) {
        let lsb = self.increment_pc();
        let msb = self.increment_pc();

        let value: u16 = (msb as u16) << 8 | lsb as u16;

        self.register.write_16(PC, value);

        self.cycles += 16;
    }

    fn jp_hl(&mut self) {
        self.register.write_16(PC, self.register.read_16(HL));

        self.cycles += 4;
    }

    fn jp_f_nn(&mut self, flag: FlagType) {
        let lsb = self.increment_pc();
        let msb = self.increment_pc();

        let value: u16 = (msb as u16) << 8 | lsb as u16;

        if self.register.read_flag(flag) {
            self.register.write_16(PC, value);
            self.cycles += 16;
        } else {
            self.cycles += 12;
        }
    }

    fn jp_nf_nn(&mut self, flag: FlagType) {
        let lsb = self.increment_pc();
        let msb = self.increment_pc();

        let value: u16 = (msb as u16) << 8 | lsb as u16;

        if !self.register.read_flag(flag) {
            self.register.write_16(PC, value);
            self.cycles += 16;
        } else {
            self.cycles += 12;
        }
    }

    fn jr_e(&mut self) {
        let address = self.increment_pc() as i8;
        let e = address as i16;

        self.register.write_16(PC, self.register.read_16(PC).wrapping_add_signed(e));

        self.cycles += 12;
    }

    fn jr_f_e(&mut self, flag: FlagType) {
        let address = self.increment_pc() as i8;
        let e = address as i16;

        if self.register.read_flag(flag) {
            self.register.write_16(PC, self.register.read_16(PC).wrapping_add_signed(e));
            self.cycles += 12;
        } else {
            self.cycles += 8;
        }
    }

    fn jr_nf_e(&mut self, flag: FlagType) {
        let address = self.increment_pc() as i8;
        let e = address as i16;

        if !self.register.read_flag(flag) {
            self.register.write_16(PC, (self.register.read_16(PC).wrapping_add_signed(e)));
            self.cycles += 12;
        } else {
            self.cycles += 8;
        }
    }

    fn call_nn(&mut self) {
        let lsb = self.increment_pc();
        let msb = self.increment_pc();

        let value: u16 = (msb as u16) << 8 | lsb as u16;
        let pc = self.register.read_16(PC);
        let pc_msb = (pc >> 8 as u8) as u8;
        let pc_lsb = pc as u8;

        self.decrement_sp();
        self.memory.write(self.register.read_16(SP), pc_msb);
        self.decrement_sp();
        self.memory.write(self.register.read_16(SP), pc_lsb);

        self.register.write_16(PC, value);

        self.cycles += 24;
    }

    fn call_f_nn(&mut self, flag: FlagType) {
        let lsb = self.increment_pc();
        let msb = self.increment_pc();

        let value: u16 = (msb as u16) << 8 | lsb as u16;

        if self.register.read_flag(flag) {
            self.decrement_sp();
            self.memory.write(self.register.read_16(SP), msb);
            self.decrement_sp();
            self.memory.write(self.register.read_16(SP), lsb);

            self.register.write_16(PC, value);
            self.cycles += 24;
        } else {
            self.cycles += 12;
        }
    }

    fn call_nf_nn(&mut self, flag: FlagType) {
        let lsb = self.increment_pc();
        let msb = self.increment_pc();

        let value: u16 = (msb as u16) << 8 | lsb as u16;

        if !self.register.read_flag(flag) {
            self.decrement_sp();
            self.memory.write(self.register.read_16(SP), msb);
            self.decrement_sp();
            self.memory.write(self.register.read_16(SP), lsb);

            self.register.write_16(PC, value);
            self.cycles += 24;
        } else {
            self.cycles += 12;
        }
    }

    fn ret(&mut self) {
        let lsb = self.increment_sp();
        let msb = self.increment_sp();

        let value: u16 = (msb as u16) << 8 | lsb as u16;

        self.register.write_16(PC, value);

        self.cycles += 16;
    }

    fn ret_f(&mut self, flag: FlagType) {

        if self.register.read_flag(flag) {
            let lsb = self.increment_sp();
            let msb = self.increment_sp();

            let value: u16 = (msb as u16) << 8 | lsb as u16;

            self.register.write_16(PC, value);

            self.cycles += 20;
        } else {
            self.cycles += 8;
        }
    }

    fn ret_nf(&mut self, flag: FlagType) {

        if !self.register.read_flag(flag) {
            let lsb = self.increment_sp();
            let msb = self.increment_sp();

            let value: u16 = (msb as u16) << 8 | lsb as u16;

            self.register.write_16(PC, value);

            self.cycles += 20;
        } else {
            self.cycles += 8;
        }
    }

    fn reti(&mut self) {
        let lsb = self.increment_sp();
        let msb = self.increment_sp();

        let value: u16 = (msb as u16) << 8 | lsb as u16;

        self.register.write_16(PC, value);
        self.register.set_ime(true);

        self.cycles += 16;
    }

    fn rst(&mut self, pc: u8) {
        let lsb = (self.register.read_16(PC) >> 8) as u8;
        let msb = (self.register.read_16(PC)) as u8;

        self.decrement_sp();
        self.memory.write(self.register.read_16(SP), msb);
        self.decrement_sp();
        self.memory.write(self.register.read_16(SP), lsb);

        self.register.write_16(PC, (pc as u16) << 8 | 0x00 as u16);

        self.cycles += 16;
    }

    fn di(&mut self) {
        self.register.set_ime(false);
        self.cycles += 4;
    }

    fn ei(&mut self) {
        self.register.set_ime(true);
        self.cycles += 4;
    }

    fn nop(&mut self) {
        self.cycles += 4;
    }
}