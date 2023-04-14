#[derive(Copy, Clone)]
pub enum RegisterType8 {
    A,
    B,
    C,
    D,
    E,
    F,
    H,
    L
}

#[derive(Copy, Clone)]
pub enum RegisterType16 {
    AF,
    BC,
    DE,
    HL,
    SP,
    PC
}