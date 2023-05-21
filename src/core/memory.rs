#[derive(Copy, Clone)]
pub struct Memory {
    memory: [u8; 0xFFFF],
    bootrom: [u8; 0x100],
    r#if: u8,
    ie: u8,
    pub bootrom_loaded: bool
}

impl Memory {
    pub fn new() -> Self {
        Self {
            memory: [0; 0xFFFF],
            bootrom: [0; 0x100],
            ie: 0x00,
            r#if: 0x00,
            bootrom_loaded: false
        }
    }

    pub fn write(&mut self, location: u16, value: u8) {
        let location = location as usize;
        if location >= self.memory.len() { }
        else if location == 0xFF02 && value == 0x81  {
            print!("{}", self.memory[0xFF01] as char);
        }
        else if location >= 0xFF04 && location <= 0xFF07  {

        } 
        else if location == 0xFFFF {
            self.ie = value;
        }
        else if location == 0xFF0F {
            self.r#if = value;
        }
        else {
            self.memory[location] = value
        }
    }

    pub fn read(&self, location: u16) -> u8 {
        let location = location as usize;
        if location >= self.memory.len() {
            return 0;
        }

        if location < 0x100 && self.bootrom_loaded {
            return self.bootrom[location];
        }

        if location == 0xFFFF {
            return self.ie;
        }

        if location == 0xFF0F {
            return self.r#if;
        }

        self.memory[location]
    }

    pub fn write_bootrom(&mut self, bootrom: &[u8; 0x100]) {
        let mut counter = 0;

        for x in bootrom {
            self.bootrom[counter] = *x;
            counter += 1;
        }
        self.bootrom_loaded = true;
    }

    pub fn write_game(&mut self, game: &[u8]) {
        let mut counter = 0;

        for x in game {
            self.memory[counter] = *x;
            counter += 1;
        }
    }
}