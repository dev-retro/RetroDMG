use crate::core::register_type;
use crate::core::register_type::RegisterType;

struct Registers {
    af: u16,
    bc: u16,
    de: u16,
    hl: u16,
    sp: u16,
    pc: u16
}

impl Registers {
    pub fn new() -> Self {
        Self {
            af: 0x0000,
            bc: 0x0000,
            de: 0x0000,
            hl: 0x0000,
            sp: 0x0000,
            pc: 0x0000
        }
    }

    pub fn set(&mut self, register: RegisterType, value: u16, ) {
        match register {
            RegisterType::AF => { self.af = value; }
            RegisterType::BC => { self.bc = value; }
            RegisterType::DE => { self.de = value; }
            RegisterType::HL => { self.hl = value; }
            RegisterType::SP => { self.sp = value; }
        }
    }

    pub fn get(self, register: RegisterType) -> u16 {
        match register {
            RegisterType::AF => { self.af }
            RegisterType::BC => { self.bc }
            RegisterType::DE => { self.de }
            RegisterType::HL => { self.hl }
            RegisterType::SP => { self.sp }
        }
    }

    pub fn set_lower(&mut self, register: RegisterType, value: u8) {
        match register {
            RegisterType::AF => { self.af = value as u16 }
            RegisterType::BC => { self.bc = value as u16 }
            RegisterType::DE => { self.de = value as u16 }
            RegisterType::HL => { self.hl = value as u16 }
            RegisterType::SP => { self.sp = value as u16 }
        }
    }

    pub fn set_higher(&mut self, register: RegisterType, value: u8) {
        match register {
            RegisterType::AF => { self.af = (value >> 8) as u16 }
            RegisterType::BC => { self.bc = (value >> 8) as u16 }
            RegisterType::DE => { self.de = (value >> 8) as u16 }
            RegisterType::HL => { self.hl = (value >> 8) as u16 }
            RegisterType::SP => { self.sp = (value >> 8) as u16 }
        }
    }

    pub fn get_lower(self, register: RegisterType) -> u8 {
        match register {
            RegisterType::AF => { self.af as u8 }
            RegisterType::BC => { self.bc as u8 }
            RegisterType::DE => { self.de as u8 }
            RegisterType::HL => { self.hl as u8 }
            RegisterType::SP => { self.sp as u8 }
        }
    }

    pub fn get_higher(self, register: RegisterType) -> u8 {
        match register {
            RegisterType::AF => { (self.af << 8) as u8 }
            RegisterType::BC => { (self.bc << 8) as u8 }
            RegisterType::DE => { (self.de << 8) as u8 }
            RegisterType::HL => { (self.hl << 8) as u8 }
            RegisterType::SP => { (self.sp << 8) as u8 }
        }
    }
}