using System;
namespace Cade.DMG.Core;

public class CoreManager
{
	private PPU ppu;
	private MMU mmu;
	private CPU cpu;

	public CoreManager()
	{
		ppu = new();
		mmu = new(ref ppu);
		cpu = new(ref mmu);
	}

	public void LoadGame(byte[] game)
	{
		mmu.LoadGame(game);
	}

	public void LoadBootrom(byte[] bootrom)
	{
		mmu.LoadBootrom(bootrom);
	}

	public void Tick()
	{
		cpu.Tick();
	}
}

