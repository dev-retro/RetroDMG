////
////  PPUTest.swift
////
////
////  Created by Glenn Hevey on 4/1/2024.
////
//
//import Foundation
//
//public struct PPU {
//    var memory = [UInt8](repeating: 0, count: 0x2000) //TODO: pass in from bus
//    var viewPort = [Int](repeating: 0, count: 0x1680) //TODO: pass in from bus
//    var oam = [UInt8](repeating: 0, count: 0x280) //TODO: pass in from bus
//    var scx = UInt8() //TODO: pass in from bus
//    var scy = UInt8() //TODO: pass in from bus
//    var wx = UInt8() //TODO: pass in from bus
//    var wy = UInt8() //TODO: pass in from bus
//    var ly: UInt8 = 0
//    var mode: PPUMode = .OAM
//    
//    private var temporaryViewPort = [Int](repeating: 0, count: 0x1680)
//    private var cycles: UInt16 = 0
//    private var drawn = false
//    private var drawEnd = 252
//    
//    var control = UInt8()
//    private var status = UInt8()
//    
//    public mutating func updateGraphics(cycles: UInt16) {
//        if !read(flag: .LCDDisplayEnable) {
//            ly = 0
//            mode = .HorizontalBlank
//        } else {
//            self.cycles += cycles
//            if ly == 144 {
//                mode = .VerticalBlank
//                viewPort = temporaryViewPort
//            } else if ly > 153 {
//                mode = .OAM
//                ly = 0
//                temporaryViewPort.removeAll(keepingCapacity: true)
//            }
//            
//            if self.cycles >= 0 && self.cycles < 80 {
//                mode = .OAM
//                
//            } else if self.cycles >= 80 && self.cycles < drawEnd {
//                mode = .Draw
//                if !drawn {
//                    var x = 0
//                    let remove = Int(scx % 8)
//                    drawEnd += remove
//                    
//                    for pixel in stride(from: 0, to: 160, by: 8) {
//                        
//                        var fetcherX = x + (Int(scx) / 8) & 0x1F
//                        var fetcherY = (Int(ly) + Int(scy)) & 0xFF
//                        
//                        var tilemapAddress = x + ((fetcherY / 8) * 0x20)
//                        
//                        var tileNo = memory[Int(tilemapAddress)]
//                        
//                        var tileLocation = read(flag: .TileDataSelect) ? Int(tileNo) * 16 : 0x1000 + Int(Int8(bitPattern: tileNo)) * 16
//                        tileLocation += (2 * (fetcherY % 8))
//                        
//                        
//                        let byte1 = memory[Int(tileLocation)]
//                        let byte2 = memory[Int(tileLocation + 0x1)]
//                        var tile = createRow(byte1: byte1, byte2: byte2)
//                        
//                        if x == 0 {
//                            tile.removeSubrange(0..<remove)
//                        }
//                        
//                        temporaryViewPort.append(contentsOf: tile)
//                        x += 1
//                        
//                    }
//                    drawn = true
//                } else if self.cycles >= drawEnd && self.cycles < 456 {
//                    mode = .HorizontalBlank
//                } else {
//                    ly += 1
//                    self.cycles = 0
//                    drawEnd = 252
//                    drawn = false
//                }
//            } else {
//                if self.cycles >= 456 {
//                    ly += 1
//                    self.cycles = 0
//                }
//            }
//        }
//    }
//        
//    func createRow(byte1: UInt8, byte2: UInt8) -> [Int] {
//        var colourIds = [Int](repeating: 0, count: 8)
//        
//        for bit in 0..<8 {
//            let msb = byte2.get(bit: UInt8(bit))
//            let lsb = byte1.get(bit: UInt8(bit))
//            
//            if msb {
//                if lsb {
//                    colourIds[7-bit] = 3
//                } else {
//                    colourIds[7-bit] = 2
//                }
//            } else {
//                if lsb {
//                    colourIds[7-bit] = 1
//                } else {
//                    colourIds[7-bit] = 0
//                }
//            }
//        }
//        
//        return colourIds
//    }
//        
//    public mutating func write(flag: PPURegisterType, set: Bool) {
//        switch flag {
//        case .LCDDisplayEnable:
//            let mask: UInt8 = 0b10000000
//            
//            if set {
//                control |= mask
//            } else {
//                control &= mask ^ 0xFF
//            }
//        case .WindowTileMapSelect:
//            let mask: UInt8 = 0b01000000
//            
//            if set {
//                control |= mask
//            } else {
//                control &= mask ^ 0xFF
//            }
//        case .WindowDisplayEnable:
//            let mask: UInt8 = 0b00100000
//            
//            if set {
//                control |= mask
//            } else {
//                control &= mask ^ 0xFF
//            }
//        case .TileDataSelect:
//            let mask: UInt8 = 0b00010000
//            
//            if set {
//                control |= mask
//            } else {
//                control &= mask ^ 0xFF
//            }
//        case .BGTileMapSelect:
//            let mask: UInt8 = 0b00001000
//            
//            if set {
//                control |= mask
//            } else {
//                control &= mask ^ 0xFF
//            }
//        case .SpriteSize:
//            let mask: UInt8 = 0b00000100
//            
//            if set {
//                control |= mask
//            } else {
//                control &= mask ^ 0xFF
//            }
//        case .SpriteEnable:
//            let mask: UInt8 = 0b00000010
//            
//            if set {
//                control |= mask
//            } else {
//                control &= mask ^ 0xFF
//            }
//        case .BGWindowEnable:
//            let mask: UInt8 = 0b00000001
//            
//            if set {
//                control |= mask
//            } else {
//                control &= mask ^ 0xFF
//            }
//        case .LYCLYInterruptEnable:
//            let mask: UInt8 = 0b01000000
//            
//            if set {
//                status |= mask
//            } else {
//                status &= mask ^ 0xFF
//            }
//            
//        case .Mode2InterruptEnable:
//            let mask: UInt8 = 0b00100000
//            
//            if set {
//                status |= mask
//            } else {
//                status &= mask ^ 0xFF
//            }
//        case .Mode1InterruptEnable:
//            let mask: UInt8 = 0b00010000
//            
//            if set {
//                status |= mask
//            } else {
//                status &= mask ^ 0xFF
//            }
//        case .Mode0InterruptEnable:
//            let mask: UInt8 = 0b00001000
//            
//            if set {
//                status |= mask
//            } else {
//                status &= mask ^ 0xFF
//            }
//        case .CoincidenceFlag:
//            let mask: UInt8 = 0b00000100
//            
//            if set {
//                status |= mask
//            } else {
//                status &= mask ^ 0xFF
//            }
//        }
//    }
//        
//    public func read(flag: PPURegisterType) -> Bool {
//        switch flag {
//        case .LCDDisplayEnable:
//            let mask: UInt8 = 0b10000000
//            return control & mask == mask
//        case .WindowTileMapSelect:
//            let mask: UInt8 = 0b01000000
//            return control & mask == mask
//        case .WindowDisplayEnable:
//            let mask: UInt8 = 0b00100000
//            return control & mask == mask
//        case .TileDataSelect:
//            let mask: UInt8 = 0b00010000
//            return control & mask == mask
//        case .BGTileMapSelect:
//            let mask: UInt8 = 0b00001000
//            return control & mask == mask
//        case .SpriteSize:
//            let mask: UInt8 = 0b00000100
//            return control & mask == mask
//        case .SpriteEnable:
//            let mask: UInt8 = 0b00000010
//            return control & mask == mask
//        case .BGWindowEnable:
//            let mask: UInt8 = 0b00000001
//            return control & mask == mask
//        case .LYCLYInterruptEnable:
//            let mask: UInt8 = 0b01000000
//            
//            return status & mask == mask
//        case .Mode2InterruptEnable:
//            let mask: UInt8 = 0b00100000
//            return status & mask == mask
//        case .Mode1InterruptEnable:
//            let mask: UInt8 = 0b00010000
//            return status & mask == mask
//        case .Mode0InterruptEnable:
//            let mask: UInt8 = 0b00001000
//            return status & mask == mask
//        case .CoincidenceFlag:
//            let mask: UInt8 = 0b00000100
//            return status & mask == mask
//        }
//    }
//}
//
//enum AddressMethod {
//    case m8000
//    case m9000
//}
//
//enum Palette {
//    case white
//    case light
//    case dark
//    case black
//}
//
//enum PPUMode {
//    case HorizontalBlank
//    case VerticalBlank
//    case OAM
//    case Draw
//}
//
//public enum PPURegisterType {
//    case LCDDisplayEnable
//    case WindowTileMapSelect
//    case WindowDisplayEnable
//    case TileDataSelect
//    case BGTileMapSelect
//    case SpriteSize
//    case SpriteEnable
//    case BGWindowEnable
//    
//    case LYCLYInterruptEnable
//    case Mode2InterruptEnable
//    case Mode1InterruptEnable
//    case Mode0InterruptEnable
//    case CoincidenceFlag
//}
