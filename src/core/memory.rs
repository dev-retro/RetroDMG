struct Memory {
    memory: [u8; 0xFFFF],
    bootrom: [u8; 0x100],
    bootrom_loaded: bool
}

impl Memory {
    pub fn new() -> Self {
        Self {
            memory: [0; 0xFFFF],
            bootrom: [0; 0x100],
            bootrom_loaded: false
        }
    }

    pub fn write(&mut self, location: usize, value: u8) {
        if location >= self.memory.len() { }
        else {
            self.memory[location] = value
        }
    }

    pub fn read(&self, location: usize) -> u8 {
        if location >= self.memory.len() {
            return 0;
        }

        if location < 0x100 && self.bootrom_loaded {
            return self.bootrom[location];
        }

        self.memory[location]
    }

    pub fn write_bootrom(&mut self, bootrom: [u8; 0x100]) {
        self.bootrom = bootrom;
    }
}