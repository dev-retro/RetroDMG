use rustils::parse::boolean::u8_to_bool;
use crate::core::flag_type::FlagType::*;
use crate::core::memory::Memory;
use crate::core::register_type::RegisterType8::*;
use crate::core::register_type::RegisterType16::*;
use crate::core::register_type::{RegisterType16, RegisterType8};
use crate::core::registers::Registers;

struct CPU {
    memory: Memory,
    register: Registers,
    cycles: i32
}


impl CPU {
    fn op_codes(&mut self) {
        let opcode = self.increment_pc();

        match opcode {

            _ => { } //TODO: Throw actual error
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
        sp += 1;
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

    /// Loads r1 into r2
    fn ld_r_r(&mut self, r1: RegisterType8, r2: RegisterType8) {
        self.register.write_8(r2, self.register.read_8(r1));
        self.cycles += 4;
    }

    fn ld_r_n(&mut self, r: RegisterType8) {
        let value = self.increment_pc();
        self.register.write_8(r, value);
        self.cycles += 8;
    }

    fn ld_r_indirect_hl(&mut self, r: RegisterType8) {
        self.register.write_8(r, self.memory.read(self.register.read_16(HL)));
        self.cycles += 8;
    }

    fn ld_indirect_hl_r(&mut self, r: RegisterType8) {
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

        let value: u16 = (lsb as u16) << 8 | msb as u16;

        self.register.write_8(A, self.memory.read(value));
        self.cycles += 16;
    }

    fn ld_indirect_nn_a(&mut self) {
        let lsb = self.increment_pc();
        let msb = self.increment_pc();

        let value: u16 = (lsb as u16) << 8 | msb as u16;

        self.memory.write(value, self.register.read_8(A));
        self.cycles += 16;
    }

    fn ldh_a_indirect_c(&mut self) {
        let lsb = self.register.read_8(C);
        let msb = 0xFF as u8;

        let value: u16 = (lsb as u16) << 8 | msb as u16;

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

        let value: u16 = (lsb as u16) << 8 | msb as u16;

        self.register.write_8(A, self.memory.read(value));
        self.cycles += 12;
    }

    fn ldh_indirect_n_a(&mut self) {
        let lsb = self.increment_pc();
        let msb = 0xFF as u8;

        let location: u16 = (lsb as u16) << 8 | msb as u16;

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

    fn ld_rr_nn(&mut self, r: RegisterType16) {
        let lsb = self.increment_pc();
        let msb = self.increment_pc();

        let value: u16 = (lsb as u16) << 8 | msb as u16;

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

    fn push(&mut self) {
        self.decrement_sp();
        let mut sp = self.register.read_16(SP);
        let bc = self.register.read_16(BC);

        self.memory.write(sp, bc as u8);

        self.decrement_sp();
        sp = self.register.read_16(SP);

        self.memory.write(sp, (bc >> 8) as u8);
        self.decrement_sp();

        self.cycles += 16;

    }

    fn pop(&mut self, r: RegisterType16) {
        let lsb = self.increment_sp();
        let msb = self.increment_sp();

        let value: u16 = (lsb as u16) << 8 | msb as u16;

        self.register.write_16(BC, value);
        self.cycles += 12;
    }

    // 8-bit arithmetic and logical instructions

    fn add_a_r(&mut self, r: RegisterType8) {
        let a = self.register.read_8(A);
        let value = self.register.read_8(r);
        let result = a + value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });

        self.cycles += 4;
    }

    fn add_a_indirect_hl(&mut self) {
        let a = self.register.read_8(A);
        let value = self.memory.read(self.register.read_16(HL));
        let result = a + value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn add_a_n(&mut self) {
        let a = self.register.read_8(A);
        let value = self.increment_pc();
        let result = value + a;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn adc_a_indirect_hl(&mut self) {
        let a = self.register.read_8(A);
        let value = self.memory.read(self.register.read_16(HL));
        let result = a + self.register.read_flag(Carry) + value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn adc_a_n(&mut self) {
        let a = self.register.read_8(A);
        let value = self.increment_pc();
        let result = a + self.register.read_flag(Carry) + value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn sub_a_r(&mut self, r: RegisterType8) {
        let a = self.register.read_8(A);
        let value = self.register.read_8(r);
        let result = a - value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });

        self.cycles += 4;
    }

    fn sub_a_indirect_hl(&mut self) {
        let a = self.register.read_8(A);
        let value = self.memory.read(self.register.read_16(HL));
        let result = a - value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn sub_a_n(&mut self) {
        let a = self.register.read_8(A);
        let value = self.increment_pc();
        let result = a - value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn sbc_a_r(&mut self, r: RegisterType8) {
        let a = self.register.read_8(A);
        let value = self.register.read_8(r);
        let result = a - self.register.read_flag(Carry) - value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });

        self.cycles += 4;
    }

    fn sbc_a_indirect_hl(&mut self) {
        let a = self.register.read_8(A);
        let value = self.memory.read(self.register.read_16(HL));
        let result = a - self.register.read_flag(Carry) - value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn sbc_a_n(&mut self) {
        let a = self.register.read_8(A);
        let value = self.increment_pc();
        let result = a - self.register.read_flag(Carry) - value;

        self.register.write_8(A, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn cp_r(&mut self, r: RegisterType8) {
        let a = self.register.read_8(A);
        let value = self.register.read_8(r);
        let result = a - value;

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });

        self.cycles += 4;
    }

    fn cp_indirect_hl(&mut self) {
        let a = self.register.read_8(A);
        let value = self.memory.read(self.register.read_16(HL));
        let result = a - value;

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn cp_n(&mut self) {
        let a = self.register.read_8(A);
        let value = self.increment_pc();
        let result = a - value;

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(Carry, if result > 0xFF { true } else { false });
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });

        self.cycles += 8;
    }

    fn inc_r(&mut self, r: RegisterType8) {
        let register = self.register.read_8(r);
        let result = register + 1;

        self.register.write_8(r, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });
    }

    fn inc_indirect_hl(&mut self) {
        let value = self.memory.read(self.register.read_16(HL));
        let result = value + 1;

        self.memory.write(self.register.read_16(HL), result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, false);
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });
    }

    fn dec_r(&mut self, r: RegisterType8) {
        let register = self.register.read_8(r);
        let result = register - 1;

        self.register.write_8(r, result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });
    }

    fn dec_indirect_hl(&mut self) {
        let value = self.memory.read(self.register.read_16(HL));
        let result = value - 1;

        self.memory.write(self.register.read_16(HL), result);

        self.register.write_flag(Zero, if result == 0 { true } else { false });
        self.register.write_flag(Subtraction, true);
        self.register.write_flag(HalfCarry, if result > 0xF { true } else { false });
    }

    fn and_a_r(&mut self, r: RegisterType8) {
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

    fn or_a_r(&mut self, r: RegisterType8) {
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

    fn xor_a_r(&mut self, r: RegisterType8) {
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
        if u8_to_bool(self.register.read_flag(Carry)) {
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

        let neg_flag = u8_to_bool(neg_flag);
        let carry_flag = u8_to_bool(carry_flag);
        let halfcarry_flag = u8_to_bool(halfcarry_flag);

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
}