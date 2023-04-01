use crate::core::flag_type::FlagType;
use crate::core::register_type::{RegisterType16, RegisterType8};

pub struct Registers {
    a: u8,
    b: u8,
    c: u8,
    d: u8,
    e: u8,
    f: u8,
    h: u8,
    l: u8,
    sp: u16,
    pc: u16,
    ime: bool
}

impl Registers {
    pub fn new() -> Self {
        Self {
            a: 0x00,
            b: 0x00,
            c: 0x00,
            d: 0x00,
            e: 0x00,
            f: 0x00,
            h: 0x00,
            l: 0x00,
            sp: 0x0000,
            pc: 0x0000,
            ime: false
        }
    }

    pub fn write_8(&mut self, register: RegisterType8, value: u8) {
        match register {
            RegisterType8::A => { self.a = value }
            RegisterType8::B => { self.b = value }
            RegisterType8::C => { self.c = value }
            RegisterType8::D => { self.d = value }
            RegisterType8::E => { self.e = value }
            RegisterType8::H => { self.h = value }
            RegisterType8::L => { self.l = value }
        }
    }

    pub fn write_16(&mut self, register: RegisterType16, value: u16) {
        match register {
            RegisterType16::AF => {
                self.a = (value >> 8) as u8;
                self.f = value as u8;
            }
            RegisterType16::BC => {
                self.b = (value >> 8) as u8;
                self.c = value as u8;
            }
            RegisterType16::DE => {
                self.d = (value >> 8) as u8;
                self.e = value as u8;
            }
            RegisterType16::HL => {
                self.h = (value >> 8) as u8;
                self.l = value as u8;
            }
            RegisterType16::SP => { self.sp = value; }
            RegisterType16::PC => { self.pc = value; }
        }
    }

    pub fn read_8(&self, register: RegisterType8) -> u8 {
        match register {
            RegisterType8::A => { self.a }
            RegisterType8::B => { self.b }
            RegisterType8::C => { self.c }
            RegisterType8::D => { self.d }
            RegisterType8::E => { self.e }
            RegisterType8::H => { self.h }
            RegisterType8::L => { self.l }
        }
    }

    pub fn read_16(&self, register: RegisterType16) -> u16 {
        match register {
            RegisterType16::AF => {
                let value: u16 = (self.a as u16) << 8 | self.f as u16;
                value
            }
            RegisterType16::BC => {
                let value: u16 = (self.b as u16) << 8 | self.c as u16;
                value
            }
            RegisterType16::DE => {
                let value: u16 = (self.d as u16) << 8 | self.e as u16;
                value
            }
            RegisterType16::HL => {
                let value: u16 = (self.h as u16) << 8 | self.l as u16;
                value
            }
            RegisterType16::SP => { self.sp }
            RegisterType16::PC => { self.pc }
        }
    }

    pub fn write_flag(&mut self, flag: FlagType, set: bool) {
        match flag {
            FlagType::Zero => {
                let bit: i32 = 8 % 8;
                let mask: u8 = 1 << bit;

                let mut value = self.f;

                if set {
                    value |= mask;
                    self.f = value;
                } else {
                    value &= !mask;
                    self.f = value;
                }
            }
            FlagType::Subtraction => {
                let bit: i32 = 7 % 8;
                let mask: u8 = 1 << bit;

                let mut value = self.f;

                if set {
                    value |= mask;
                    self.f = value;
                } else {
                    value &= !mask;
                    self.f = value;
                }
            }
            FlagType::HalfCarry => {
                let bit: i32 = 6 % 8;
                let mask: u8 = 1 << bit;

                let mut value = self.f;

                if set {
                    value |= mask;
                    self.f = value;
                } else {
                    value &= !mask;
                    self.f = value;
                }
            }
            FlagType::Carry => {
                let bit: i32 = 5 % 8;
                let mask: u8 = 1 << bit;

                let mut value = self.f;

                if set {
                    value |= mask;
                    self.f = value;
                } else {
                    value &= !mask;
                    self.f = value;
                }
            }
        }
    }

    pub fn read_flag(&self, flag: FlagType) -> u8 {
        match flag {
            FlagType::Zero => {
                let bit: i32 = 8 % 8;
                let mask: u8 = 1 << bit;
                let value: u8 = (self.f & mask) >> bit;

                value
            }
            FlagType::Subtraction => {
                let bit: i32 = 7 % 8;
                let mask: u8 = 1 << bit;
                let value: u8 = (self.f & mask) >> bit;

                value
            }
            FlagType::HalfCarry => {
                let bit: i32 = 6 % 8;
                let mask: u8 = 1 << bit;
                let value: u8 = (self.f & mask) >> bit;

                value
            }
            FlagType::Carry => {
                let bit: i32 = 5 % 8;
                let mask: u8 = 1 << bit;
                let value: u8 = (self.f & mask) >> bit;

                value
            }
        }
    }

    pub fn set_ime(&mut self, value: bool) {
        self.ime = value;
    }
}