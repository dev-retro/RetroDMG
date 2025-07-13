# Deep Review: Stack Operations Implementation

Date: 2025-07-13
File: Sources/RetroDMG/CPU.swift
Reference: Pandocs (Game Boy CPU specification)

---

## Stack Operations (PUSH, POP, CALL, RET, RST)

### Pandocs Reference
- **PUSH/POP**: Stack pointer (SP) is decremented/incremented by 2. PUSH stores register pair (AF, BC, DE, HL) to stack. POP loads from stack to register pair. AF masking required (lower nibble of F always zero).
- **CALL/RET/RETI**: CALL pushes current PC to stack, then jumps to address. RET/RETI pops address from stack to PC. RETI also sets IME.
- **RST**: Pushes PC to stack, jumps to fixed address.
- **SP Masking**: AF register must mask lower nibble of F on POP.
- **Cycle Timing**: PUSH/POP (16/12 cycles), CALL/RET/RETI (24/16 cycles), RST (16 cycles).

---

## Implementation Review

### PUSH
```swift
func push(register: RegisterType16) {
    let value = registers.read(register: register)
    decrement(register: .SP, partOfOtherOpCode: true)
    bus.write(location: registers.read(register: .SP), value: UInt8(value >> 8))
    decrement(register: .SP, partOfOtherOpCode: true)
    bus.write(location: registers.read(register: .SP), value: UInt8(truncatingIfNeeded: register == .AF ? value & 0xF0 : value ))
    cycles = cycles.addingReportingOverflow(16).partialValue
}
```
- SP decremented by 2, high/low bytes written in correct order.
- AF masking applied for lower nibble of F.
- Cycle count matches Pandocs.

### POP
```swift
func pop(register: RegisterType16) {
    var lsb = returnAndIncrement(indirect: .SP)
    let msb = returnAndIncrement(indirect: .SP)
    if register == .AF {
        lsb = lsb & 0xF0
    }
    let value = UInt16(msb) << 8 | UInt16(lsb);
    registers.write(register: register, value: value)
    cycles = cycles.addingReportingOverflow(12).partialValue
}
```
- SP incremented by 2, high/low bytes read in correct order.
- AF masking applied for lower nibble of F.
- Cycle count matches Pandocs.

### CALL
```swift
func call() {
    let lsb = returnAndIncrement(indirect: .PC)
    let msb = returnAndIncrement(indirect: .PC)
    let value = UInt16(msb) << 8 | UInt16(lsb)
    let pc = registers.read(register: .PC)
    let pcMsb = UInt8(pc >> 8)
    let pcLsb = UInt8(truncatingIfNeeded: pc)
    decrement(register: .SP, partOfOtherOpCode: true)
    bus.write(location: registers.read(register: .SP), value: pcMsb)
    decrement(register: .SP, partOfOtherOpCode: true)
    bus.write(location: registers.read(register: .SP), value: pcLsb)
    registers.write(register: .PC, value: value)
    cycles = cycles.addingReportingOverflow(24).partialValue
}
```
- PC pushed to stack (high/low bytes), SP decremented by 2.
- Jumps to target address.
- Cycle count matches Pandocs.

### RET/RETI
```swift
func ret() { ... }
func reti() { ... }
```
- RET/RETI pop address from stack to PC (high/low bytes).
- RETI sets IME.
- Cycle counts match Pandocs (RET: 16, RETI: 16).

### RST
```swift
func rst(value: UInt8) { ... }
```
- PC pushed to stack, jumps to fixed address.
- Cycle count matches Pandocs (16).

### Edge Cases & Masking
- AF register masking is correctly applied on POP and PUSH.
- All register pairs supported.
- Indirect addressing and stack pointer manipulation match Pandocs.

### Cycle Timing
- All stack operations use correct cycle counts per Pandocs.

### Discrepancies / TODOs
- No discrepancies found. All stack operations, masking, and cycle timing match Pandocs.
- Recommend further unit tests for edge cases (AF masking, stack overflow/underflow).

---

## Conclusion
Your stack operations implementation matches Pandocs for PUSH, POP, CALL, RET, RETI, and RST. All masking, register pair handling, and cycle timing are correct. No discrepancies found.

Reviewed by: GitHub Copilot
Date: 2025-07-13
