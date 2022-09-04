using System.IO;

namespace Cade.DMG.Core;

public class MMU
{
    private const ushort VRAMStart = 0x8000;
    private const ushort VRAMEnd = 0x9FFF;
    private const ushort ScrollX = 0xFF42;
    private const ushort ScrollY = 0xFF43;
    private const ushort ColourPalette = 0xFF47;

    private readonly byte[] _memory;
    private readonly byte[] _bootrom;
    private readonly PPU _ppu;

    public bool BootromLoaded { get; private set; }

    public MMU(ref PPU ppu)
    {
        _memory = new byte[0xFFFF];
        _bootrom = new byte[0x100];
        _ppu = ppu;

        BootromLoaded = false;
    }

    public byte Read(ushort location)
    {
        if (location >= _memory.Length)
        {
            return 0;
        }

        if (location < 0x100 && BootromLoaded)
        {
            return _bootrom[location];
        }
        
        if (location >= VRAMStart && location <= VRAMEnd)
        {
            return _ppu.Read((ushort)(location - VRAMStart));
        }

        if (location == ScrollX)
        {
            return _ppu.ScrollX;
        }

        if (location == ScrollY)
        {
            return _ppu.ScrollY;
        }
        
        if (location == ColourPalette)
        {
            return _ppu.Palette();
        }

        return _memory[location];
    }

    public void Write(ushort location, byte value)
    {
        if (location >= _memory.Length)
        {
            // Do nothing
        }
        else if (location >= VRAMStart && location <= VRAMEnd)
        {
            _ppu.Write((ushort) (location - VRAMStart), value);
        }
        else if (location == ScrollX)
        {
            _ppu.ScrollX = value;
        }
        else if (location == ScrollY)
        {
            _ppu.ScrollY = value;
        }
        else if (location == ColourPalette)
        {
            _ppu.Palette(value);
        }
        else
        {
            _memory[location] = value;
        }
    }

    public void LoadBootrom(byte[] bootrom)
    {
        bootrom.CopyTo(_bootrom, 0);
        BootromLoaded = true;
    }

    public void LoadGame(byte[] game)
    {
        game.CopyTo(_memory, 0);
    }
}