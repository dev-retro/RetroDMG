import Foundation
import RetroKit

// FFI surface for C-compatible consumers.
// Exposes a minimal, stable API to create/destroy emulator instances,
// load ROMs, control execution, set inputs, configure BIOS, and access frame data.

private final class InstanceStore {
    static let shared = InstanceStore()

    private var nextHandle: UInt64 = 1
    private var instances: [UInt64: RetroDMG] = [:]
    private let queue = DispatchQueue(label: "retro.dmg.ffi.instances")

    func create() -> UInt64 {
        queue.sync {
            let handle = nextHandle
            nextHandle &+= 1
            instances[handle] = RetroDMG()
            return handle
        }
    }

    func destroy(_ handle: UInt64) {
        queue.sync {
            instances.removeValue(forKey: handle)
        }
    }

    func get(_ handle: UInt64) -> RetroDMG? {
        queue.sync { instances[handle] }
    }
}

@inline(__always)
private func boolToInt32(_ v: Bool) -> Int32 { v ? 1 : 0 }

// MARK: - Memory helpers

@_cdecl("retrodmg_string_free")
public func retrodmg_string_free(_ ptr: UnsafeMutablePointer<CChar>?) {
    if let p = ptr { free(p) }
}

@_cdecl("retrodmg_buffer_free")
public func retrodmg_buffer_free(_ ptr: UnsafeMutableRawPointer?) {
    if let p = ptr { free(p) }
}

private func strdupSwift(_ s: String) -> UnsafeMutablePointer<CChar>? {
    // Include NUL terminator
    let utf8 = s.utf8
    let count = utf8.count + 1
    guard let buf = malloc(count)?.assumingMemoryBound(to: CChar.self) else { return nil }
    var index = 0
    for byte in utf8 {
        buf[index] = CChar(bitPattern: byte)
        index += 1
    }
    buf[index] = 0
    return buf
}

// MARK: - Lifecycle

@_cdecl("retrodmg_create")
public func retrodmg_create() -> UInt64 {
    return InstanceStore.shared.create()
}

@_cdecl("retrodmg_destroy")
public func retrodmg_destroy(_ handle: UInt64) {
    InstanceStore.shared.destroy(handle)
}

// MARK: - Metadata

@_cdecl("retrodmg_name")
public func retrodmg_name(_ handle: UInt64) -> UnsafeMutablePointer<CChar>? {
    guard let inst = InstanceStore.shared.get(handle) else { return nil }
    return strdupSwift(inst.name)
}

@_cdecl("retrodmg_description")
public func retrodmg_description(_ handle: UInt64) -> UnsafeMutablePointer<CChar>? {
    guard let inst = InstanceStore.shared.get(handle) else { return nil }
    return strdupSwift(inst.description)
}

@_cdecl("retrodmg_release_year")
public func retrodmg_release_year(_ handle: UInt64) -> Int32 {
    guard let inst = InstanceStore.shared.get(handle) else { return -1 }
    return Int32(inst.releaseDate)
}

// MARK: - Control

@_cdecl("retrodmg_start")
public func retrodmg_start(_ handle: UInt64) -> Int32 {
    guard let inst = InstanceStore.shared.get(handle) else { return 0 }
    return boolToInt32(inst.start())
}

@_cdecl("retrodmg_pause")
public func retrodmg_pause(_ handle: UInt64) -> Int32 {
    guard let inst = InstanceStore.shared.get(handle) else { return 0 }
    return boolToInt32(inst.pause())
}

@_cdecl("retrodmg_stop")
public func retrodmg_stop(_ handle: UInt64) -> Int32 {
    guard let inst = InstanceStore.shared.get(handle) else { return 0 }
    return boolToInt32(inst.stop())
}

// MARK: - ROM / Settings / Save Data

@_cdecl("retrodmg_load_rom")
public func retrodmg_load_rom(_ handle: UInt64, _ data: UnsafePointer<UInt8>?, _ length: Int) {
    guard let inst = InstanceStore.shared.get(handle), let data, length > 0 else { return }
    let buffer = UnsafeBufferPointer(start: data, count: length)
    inst.load(file: Array(buffer))
}

@_cdecl("retrodmg_set_bios")
public func retrodmg_set_bios(_ handle: UInt64, _ data: UnsafePointer<UInt8>?, _ length: Int) {
    guard let inst = InstanceStore.shared.get(handle) else { return }
    let settings = DMGSettings()
    if let data, length > 0 {
        let buffer = UnsafeBufferPointer(start: data, count: length)
        settings.bioSetting.value = Array(buffer)
    } else {
        settings.bioSetting.value = nil
    }
    inst.update(settings: settings)
}

@_cdecl("retrodmg_load_save_data")
public func retrodmg_load_save_data(_ handle: UInt64, _ data: UnsafePointer<UInt8>?, _ length: Int) {
    guard let inst = InstanceStore.shared.get(handle) else { return }
    if let data, length > 0 {
        let buffer = UnsafeBufferPointer(start: data, count: length)
        let saveData = Data(buffer: buffer)
        inst.loadSaveData(saveData)
    } else {
        inst.loadSaveData(nil)
    }
}

@_cdecl("retrodmg_get_save_data")
public func retrodmg_get_save_data(_ handle: UInt64, _ outPtr: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>?, _ outLen: UnsafeMutablePointer<Int>?) -> Int32 {
    guard let inst = InstanceStore.shared.get(handle), let outPtr, let outLen else { return 0 }
    guard let info = inst.getSaveDataWithInfo(), let data = info["saveData"] as? Data else {
        outPtr.pointee = nil
        outLen.pointee = 0
        return 0
    }
    let count = data.count
    guard let buf = malloc(count)?.assumingMemoryBound(to: UInt8.self) else {
        outPtr.pointee = nil
        outLen.pointee = 0
        return 0
    }
    _ = data.copyBytes(to: buf, count: count)
    outPtr.pointee = buf
    outLen.pointee = count
    return 1
}

// MARK: - Inputs

@_cdecl("retrodmg_input_count")
public func retrodmg_input_count(_ handle: UInt64) -> Int32 {
    guard let inst = InstanceStore.shared.get(handle) else { return 0 }
    return Int32(inst.listInputs().count)
}

@_cdecl("retrodmg_input_name")
public func retrodmg_input_name(_ handle: UInt64, _ index: Int32) -> UnsafeMutablePointer<CChar>? {
    guard let inst = InstanceStore.shared.get(handle) else { return nil }
    let inputs = inst.listInputs()
    let i = Int(index)
    guard i >= 0 && i < inputs.count else { return nil }
    return strdupSwift(inputs[i].name)
}

@_cdecl("retrodmg_set_input")
public func retrodmg_set_input(_ handle: UInt64, _ name: UnsafePointer<CChar>?, _ active: Int32, _ playerNo: Int32) {
    guard let inst = InstanceStore.shared.get(handle) else { return }
    guard let name, let key = String(validatingUTF8: name) else { return }
    var inputs = inst.listInputs()
    if let idx = inputs.firstIndex(where: { $0.name == key && $0.playerNo == Int(playerNo) || ($0.name == key && Int(playerNo) <= 1) }) {
        inputs[idx].active = active != 0
        inputs[idx].updated = true
    } else {
        var input = RetroInput(key, playerNo: Int(playerNo))
        input.active = active != 0
        input.updated = true
        inputs.append(input)
    }
    inst.update(inputs: inputs)
}

// Batch update inputs: provide parallel arrays of names, actives and playerNos
// names: const char*[] (array of C strings)
// actives: int8_t[] (0 or 1 values)
// playerNos: int32_t[] (player numbers)
// count: number of entries
@_cdecl("retrodmg_set_inputs")
public func retrodmg_set_inputs(_ handle: UInt64, _ names: UnsafePointer<UnsafePointer<CChar>?>?, _ actives: UnsafePointer<Int8>?, _ playerNos: UnsafePointer<Int32>?, _ count: Int32) {
    guard let inst = InstanceStore.shared.get(handle), let names = names, count > 0 else { return }
    var inputs = inst.listInputs()
    let cCount = Int(count)
    for i in 0..<cCount {
        guard let rawNamePtr = names.advanced(by: i).pointee else { continue }
        guard let name = String(validatingUTF8: rawNamePtr) else { continue }
        let active: Bool
        if let actives = actives {
            active = actives.advanced(by: i).pointee != 0
        } else {
            active = false
        }
        let playerNo: Int
        if let playerNos = playerNos {
            playerNo = Int(playerNos.advanced(by: i).pointee)
        } else {
            playerNo = 1
        }

        if let idx = inputs.firstIndex(where: { $0.name == name && $0.playerNo == playerNo || ($0.name == name && playerNo <= 1) }) {
            inputs[idx].active = active
            inputs[idx].updated = true
        } else {
            var input = RetroInput(name, playerNo: playerNo)
            input.active = active
            input.updated = true
            inputs.append(input)
        }
    }
    inst.update(inputs: inputs)
}

// MARK: - Video

// Copy the current 160x144 viewport into the provided buffer of Int32s.
// Returns the number of pixels written (160*144) or 0 if failed or buffer too small.
@_cdecl("retrodmg_viewport_copy")
public func retrodmg_viewport_copy(_ handle: UInt64, _ outPixels: UnsafeMutablePointer<Int32>?, _ outPixelCount: Int32) -> Int32 {
    guard let inst = InstanceStore.shared.get(handle), let outPixels else { return 0 }
    let viewport = inst.viewPort()
    let count = viewport.count
    guard outPixelCount >= Int32(count) else { return 0 }
    // Lightweight diagnostic: report if any pixel is non-zero (avoid huge dumps)
    var anyNonZero = false
    for v in viewport { if v != 0 { anyNonZero = true; break } }
    print("[retrodmg_viewport_copy] anyNonZero=\(anyNonZero) count=\(count)")
    for i in 0..<count {
        outPixels[i] = Int32(truncatingIfNeeded: viewport[i])
    }
    return Int32(count)
}

// Diagnostic test helper: write a deterministic test pattern into the provided buffer.
// Keep no extra test helpers here — the `retrodmg_viewport_copy` function prints the
// first few viewport words for diagnostics when called from the host.
