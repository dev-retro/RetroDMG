class PPUNew {
    var tileData: [UInt8]

    // Registers
    var control: UInt8
    var status: UInt8
    var ly: UInt8
    var lyc: UInt8
    var scy: UInt8
    var scx: UInt8
    var wy: UInt8
    var wx: UInt8
    var bgp: UInt8
    var obp0: UInt8
    var obp1: UInt8

    private var cycles: UInt16
    private var mode3End: UInt16

    init() {
        tileData = [UInt8](repeating: 0, count: 0x1800)
        control = 0x00
        status = 0x00
        ly = 0x00
        lyc = 0x00
        scy = 0x00
        scx = 0x00
        wy = 0x00
        wx = 0x00
        bgp = 0x00
        obp0 = 0x00
        obp1 = 0x00

        cycles = 0x0000
        mode3End = 251
    }
    
    public func write(flag: PPURegisterType, set: Bool) {
        switch flag {
        case .LCDEnable:
            control.set(bit: 7, value: set)
        case .WindowTileMapSelect:
            control.set(bit: 6, value: set)
        case .WindowDisplayEnable:
            control.set(bit: 5, value: set)
        case .TileDataSelect:
            control.set(bit: 4, value: set)
        case .BGTileMapSelect:
            control.set(bit: 3, value: set)
        case .OBJSize:
            control.set(bit: 2, value: set)
        case .OBJEnable:
            control.set(bit: 1, value: set)
        case .BGWindowEnable:
            control.set(bit: 0, value: set)
        case .LYCLYInterruptEnable:
            status.set(bit: 6, value: set)
        case .Mode2InterruptEnable:
            status.set(bit: 5, value: set)
        case .Mode1InterruptEnable:
            status.set(bit: 4, value: set)
        case .Mode0InterruptEnable:
            status.set(bit: 3, value: set)
        case .CoincidenceFlag:
            status.set(bit: 2, value: set)
        case .Mode0:
            if set {
                status.set(bit: 0, value: false)
                status.set(bit: 1, value: false)
            }
        case .Mode1:
            if set {
                status.set(bit: 0, value: true)
                status.set(bit: 1, value: false)
            }
        case .Mode2:
            if set {
                status.set(bit: 0, value: false)
                status.set(bit: 1, value: true)
            }
        case .Mode3:
            if set {
                status.set(bit: 0, value: true)
                status.set(bit: 1, value: true)
            }
        }
    }
    
    public func read(flag: PPURegisterType) -> Bool {
        switch flag {
        case .LCDEnable:
            return control.get(bit: 7)
        case .WindowTileMapSelect:
            return control.get(bit: 6)
        case .WindowDisplayEnable:
            return control.get(bit: 5)
        case .TileDataSelect:
            return control.get(bit: 4)
        case .BGTileMapSelect:
            return control.get(bit: 3)
        case .OBJSize:
            return control.get(bit: 2)
        case .OBJEnable:
            return control.get(bit: 1)
        case .BGWindowEnable:
            return control.get(bit: 0)
            
        case .LYCLYInterruptEnable:
            return status.get(bit: 6)
        case .Mode2InterruptEnable:
            return status.get(bit: 5)
        case .Mode1InterruptEnable:
            return status.get(bit: 4)
        case .Mode0InterruptEnable:
            return status.get(bit: 3)
        case .CoincidenceFlag:
            return status.get(bit: 2)
        case .Mode0:
            return !status.get(bit: 0) && !status.get(bit: 1)
        case .Mode1:
            return status.get(bit: 0) && !status.get(bit: 1)
        case .Mode2:
            return !status.get(bit: 0) && status.get(bit: 1)
        case .Mode3:
            return status.get(bit: 0) && status.get(bit: 1)
        }
    }

    public func step(cycles: UInt16) {
        self.cycles += cycles
        if ly == 144 && !read(flag: .Mode1) {
            write(flag: .Mode1, set: true)
        } else if ly == 154 {
            ly = 0
            write(flag: .Mode2, set: false)
        }

        if !read(flag: .Mode1) {
            if self.cycles >= 0 && self.cycles < 80 {
                write(flag: .Mode2, set: true)
            } else if self.cycles >= 80 && self.cycles < mode3End {
                write(flag: .Mode3, set: true)
            } else if self.cycles >= mode3End && self.cycles < 456 {
                write(flag: .Mode0, set: true)
            } else {
                self.cycles -= 456
                ly += 1
            }
        } else if self.cycles >= 456 {
            self.cycles -= 456
            if self.cycles > 0 {
                let carryOverCycles = self.cycles
                self.cycles = 0

                step(cycles: carryOverCycles)
            }
            ly += 1
        }

    }
}

public enum PPURegisterType {
    // Control
    case LCDEnable
    case WindowTileMapSelect
    case WindowDisplayEnable
    case TileDataSelect
    case BGTileMapSelect
    case OBJSize
    case OBJEnable
    case BGWindowEnable

    // Status
    case LYCLYInterruptEnable
    case Mode2InterruptEnable
    case Mode1InterruptEnable
    case Mode0InterruptEnable
    case CoincidenceFlag
    case Mode0
    case Mode1
    case Mode2
    case Mode3
}

enum Shade: Int {
    case White = 0
    case LightGray = 1
    case DarkGray = 2
    case Black = 3
}