use crate::core::cpu::CPU;
use crate::core::memory::Memory;

pub mod memory;
pub mod registers;
pub mod register_type;
pub mod flag_type;
pub mod cpu;

pub struct Core {
    pub cpu: CPU
}

impl Core {
    pub fn new() -> Self {
        Self {
            cpu: CPU::new()
        }
    }

    pub fn loadGame(mut self, game: &[u8]) {
        self.cpu.memory.write_game(game);
    }

    pub fn tick(mut self) {
        self.cpu.tick();
    }
}