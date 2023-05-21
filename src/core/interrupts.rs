pub enum InterruptType {
    VBlank,
    LCD,
    Timer,
    Serial,
    Joypad
}

pub struct Interrupts {
    ime: bool,

}

impl Interrupts {

    pub fn new() -> Self {
        Self {
            ime: false
        }
    }

    pub fn write(&mut self, interrupt_type: InterruptType, value: bool) {
        match interrupt_type {
            InterruptType::VBlank => todo!(),
            InterruptType::LCD => todo!(),
            InterruptType::Timer => { } //TODO: stubbed out for now. Will handle.
            InterruptType::Serial => todo!(),
            InterruptType::Joypad => todo!(),
        }
    }
}