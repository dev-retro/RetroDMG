using System;
using System.Drawing;
using System.Numerics;

namespace Cade.DMG.Core;

public class PPU
{
    private readonly byte[] _vram;
    
    private const int ScreenWidth = 160;
    private const int ScreenHeight = 144;
    private const int ScreenPixels = ScreenWidth * ScreenHeight;
    private const int TileMapScreenWidth = 160;
    private const int TileMapScreenHeight = 160;
    private const int TileMapScreenPixels = TileMapScreenWidth * TileMapScreenHeight;
    private const int TileIndexLength = 0x180; // 0x0180;
    private const int RowIndexLength = 8;
    private const int PixelIndexLength = 8;
    
    public Pixel[] ScreenBuffer;
    public Pixel[] TileMapBuffer;
    public byte ScrollX { get; set; }
    public byte ScrollY { get; set; }
    private byte _colourPalette;
    private PPUMode _mode = PPUMode.HBlank;
    private int _renderLine = 0;
    private Pixel[,,] _tileMap;

    public PPU()
    {
        _vram = new byte[0x2000];
        ScreenBuffer = new Pixel[ScreenPixels];
        TileMapBuffer = new Pixel[TileMapScreenPixels];
        _tileMap = new Pixel[TileIndexLength, RowIndexLength, PixelIndexLength];

        for (int i = 0; i < TileMapBuffer.Length; i++)
        {
            TileMapBuffer[i] = new Pixel { A = 0, B = 255, G = 255, R = 255};
        }
    }

    public byte Read(ushort location)
    {
        return _vram[location];
    }

    public void Write(ushort location, byte value)
    {
        _vram[location] = value;

        var normalizedLocation = location & 0xFFFE;

        var byte1 = _vram[normalizedLocation];
        var byte2 = _vram[normalizedLocation + 1];

        var tileIndex = location / 16;
        var rowIndex = location % 16 / 2;

        for (int i = 0; i < 8; i++)
        {
            var mask = 1 << (7 - i);
            var lsb = byte1 & mask;
            var msb = byte2 & mask;
            Pixel colour;

            if (lsb == 0 && msb == 0)
            {
                colour = new Pixel { A = 255, B = 255, G = 255, R = 255};
            
            } else if (lsb == 1 && msb == 0)
            {
                colour = new Pixel { A = 255, B = 168, G = 168, R = 168};
            }
            else if(lsb == 0 && msb == 1)
            {
                colour = new Pixel { A = 255, B = 86, G = 86, R = 86};
            }
            else
            {
                colour = new Pixel {A = 255, B = 0, G = 0, R = 0};
            }
            
            
            _tileMap[tileIndex, rowIndex, i] = colour;
        }
    }

    public void Tick(ref int cycle)
    {
        switch (_mode)
        {
            case PPUMode.HBlank:
                if(cycle >= 204)
                {
                    _mode = 0;
                    _renderLine += 1;

                    if(_renderLine == 143)
                    {
                        _mode = PPUMode.VBlank;
                    }
                    else
                    {
                        _mode = PPUMode.OamAccess;
                    }
                }
                break;
            case PPUMode.VBlank:
                if(cycle >= 456)
                {
                    cycle = 0;
                    _renderLine += 1;

                    if(_renderLine > 153)
                    {
                        _mode = PPUMode.OamAccess;
                        _renderLine = 0;
                    }
                }
                break;
            case PPUMode.OamAccess:
                if (cycle >= 80)
                {
                    cycle = 0;
                    _mode = PPUMode.VRamAccess;
                }
                break;
            case PPUMode.VRamAccess:
                if (cycle >= 172)
                {
                    cycle = 0;
                    _mode = PPUMode.HBlank;
                    RenderTileMap();
                }
                break;
            
        }
    }

    public void Palette(byte palette)
    {
        _colourPalette = palette;
    }

    public byte Palette()
    {
        return _colourPalette;
    }

    private void RenderLine()
    {
        
    }

    public void RenderTileMap()
    {
        for (int t = 0; t < _tileMap.GetLength(0); t++)
        {
            for (int r = 0; r < _tileMap.GetLength(1); r++)
            {
                for (int p = 0; p < _tileMap.GetLength(2); p++)
                {
                    var tile = t * 8;
                    var test = tile + r * 160 + p;
                    //x + xline + ((y + yline) * 64)
                    //var test = t * 8 + t / 20 * r + p;
                    //Console.WriteLine($"pixel: {t * 8 + (t * r * 160) + p}");
                    TileMapBuffer[test] = _tileMap[t, r, p];
                }
            }
        }
    }
}

public enum ColourPalette
{
    Colour0,
    Colour1,
    Colour2,
    Colour3
}

public enum Colours
{
    Black,
    DarkGrey,
    LightGrey,
    White
}

public struct Pixel
{
    public byte R;
    public byte G;
    public byte B;
    public byte A;

    public Pixel(byte a = 255, byte r = 255, byte g = 255, byte b = 255)
    {
        R = r;
        G = g;
        B = b;
        A = a;
    }
}

public enum PPUMode
{
    HBlank, 
    VBlank, 
    OamAccess, 
    VRamAccess
}