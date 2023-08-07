extern crate rustils;

use std::fs::File;
use std::io::Read;
use crate::core::Core;
use crate::core::timer::Timer;

mod core;

fn main() {
    let mut core = Core::new();

    // let mut bootromfile = File::open("/Users/hevey/Development/PlayCade/debugging/[BIOS] Nintendo Game Boy Boot ROM (World) (Rev 1).gb").expect("No file found");
    // let mut bootrom_bytes :[u8; 0x100] = [0; 0x100];
    // bootromfile.read(&mut bootrom_bytes).expect("Failed to open file");


    // let mut game_file = File::open("/Users/hevey/Development/PlayCade/debugging/Tetris (W) (V1.0) [!].gb").expect("No file found");
    let mut game_file = File::open("/Users/hevey/Development/PlayCade/gb-test-roms/cpu_instrs/individual/11-op a,(hl).gb").expect("No file found");
    let mut game_bytes = Vec::new();
    game_file.read_to_end(&mut game_bytes).expect("Failed to open file");

    // core.cpu.memory.write_bootrom(&bootrom_bytes);
    core.cpu.memory.write_game(&game_bytes[..]);
    let mut timer = Timer::new();
    core.cpu.memory.write(0xFF44, 0x90, &mut timer);

    println!("Game Loaded");

    loop {
        core.cpu.tick();
    }
}