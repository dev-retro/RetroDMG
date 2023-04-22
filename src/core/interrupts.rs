use super::memory::Memory;


enum InterruptType {
    VBlank,
    LCD,
    Timer,
    Serial,
    Joypad
}

struct Interrupts<'a> {
    ime: bool,
    memory: &'a Memory
}

impl<'a> Interrupts<'a> {
    fn write_flag(&mut self, interrupt_type: InterruptType, value: bool) {
        match interrupt_type {
            InterruptType::VBlank => todo!(),
            InterruptType::LCD => todo!(),
            InterruptType::Timer => todo!(),
            InterruptType::Serial => todo!(),
            InterruptType::Joypad => todo!(),
        }
    }
    
    fn write_enable(&mut self, interrupt_type: InterruptType, value: bool) {
        match interrupt_type {
            InterruptType::VBlank => todo!(),
            InterruptType::LCD => todo!(),
            InterruptType::Timer => todo!(),
            InterruptType::Serial => todo!(),
            InterruptType::Joypad => todo!(),
        }
    }
}