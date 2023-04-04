extern crate rustils;
extern crate timer;
extern crate chrono;

use std::thread;
use std::sync::{Arc, Mutex};
mod core;

use std::fs;
use std::fs::File;
use std::io::{BufReader, Read, Seek, SeekFrom};
use crate::core::Core;

fn main() {
    let mut core = Core::new();

    let mut file = File::open("/Users/hevey/Development/PlayCade/gb-test-roms/cpu_instrs/individual/06-ld r,r.gb").expect("No file found");
    let mut bytes = Vec::new();
    file.read_to_end(&mut bytes).expect("Failed to open file");

    core.cpu.memory.write_game(&bytes[..]);

    loop {
        core.cpu.tick();
    }

    println!("Game Loaded");


}