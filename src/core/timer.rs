pub struct Timer {
    div: u16,
    counter: u8,
    modulo: u8,
    controller: u8,
    enable: bool
}

impl Timer {
    pub fn new() -> Self {
        Self {
            div: u16::default(),
            counter: u8::default(),
            modulo: u8::default(),
            controller: u8::default(),
            enable: false
        }
    }

    pub fn read(&mut self, location: usize) -> u8 {
        match location {
            0xFF04 => { (self.div >> 8) as u8 }
            0xFF05 => { self.counter }
            0xFF06 => { self.modulo }
            0xFF07 => { self.controller }
            _ => { panic!("can't read location {}", location) }
        }
    }

    pub fn write(&mut self, location: usize, value: u8) {
        match location {
            0xFF04 => { self.div = 0; }
            0xFF05 => { self.counter = value; }
            0xFF06 => { self.modulo = value; }
            0xFF07 => { self.controller = value; }
            _ => { panic!("can't write to location {}", location)}
        }
    }

    pub fn tick(&mut self) -> bool {
        let (div, did_overflow) = self.div.overflowing_add(1);
        self.div = div;
        let clock_select = match self.controller & 0x3 {
            0b00 => 9,
            0b01 => 3,
            0b10 => 5,
            0b11 => 7,
            _ => panic!("timer doesn't support {}", self.controller)
        };

        let div_bit = self.get_bit(self.div, clock_select);
        let timer_enable = self.controller & 0x4;
        let result = div_bit & (timer_enable != 0);

        if self.enable && !result {
            let (value, did_overflow) = self.counter.overflowing_add(self.counter);
            if did_overflow {
                self.counter = self.modulo;
                return true;
            } else {
                self.counter = value;
            }
        }

        self.enable = result;
        false
    }

    fn get_bit(&mut self, data: u16, bit: u8) -> bool {
        let value = (data >> bit) & 1;

        value != 0
    }
}