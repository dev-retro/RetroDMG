struct Memory {
    memory: [u8; 0xFFFF]
}

impl Memory {
    pub fn new() -> Self {
        Self {
            memory: [0; 0xFFFF]
        }
    }

    pub fn write(&mut self, location: usize, value: u8) {
        self.memory[location] = value
    }

    pub fn read(self, location: usize) -> u8 {
        let value = self.memory[location];
        value
    }
}