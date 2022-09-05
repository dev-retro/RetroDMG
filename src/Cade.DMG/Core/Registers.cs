using System;

namespace Cade.DMG.Core;

public class Registers
{
    public byte A { get; set; }
    public byte B { get; set; }
    public byte C { get; set; }
    public byte D { get; set; }
    public byte E { get; set; }
    public byte F { get; set; }
    public byte H { get; set; }
    public byte L { get; set; }

    public ushort SP { get; set; }
    public ushort PC { get; set; }


    public ushort AF {
        get
        {
            return (ushort) ((A << 8) | F);
        }
        set
        {
            A = (byte) (value >> 8);
            F = (byte) value;
        }
    }

    public ushort BC
    {
        get
        {
            return (ushort) ((B << 8) | C);
        }
        set
        {
            B = (byte) (value >> 8);
            C = (byte) value;
        }
    }

    public ushort DE
    {
        get
        {
            return (ushort) ((D << 8) | E);
        }
        set
        {
            D = (byte) (value >> 8);
            E = (byte) value;
        }
    }

    public ushort HL
    {
        get
        {
            return (ushort) ((H << 8) | L);
        }
        set
        {
            H = (byte) (value >> 8);
            L = (byte) value;
        }
    }

    public void F_Zero(bool set)
    {
        int bit = 8 % 8;
        var mask = (byte) (1 << bit);
        if (set)
        {
            F |= mask;
        }
        else
        {
            F &= (byte) ~mask;
        }
    }

    public byte F_Zero()
    {
        int bit = 8 % 8;
        var mask = (byte) (1 << bit);
        return (byte) ((F & mask) >> bit);
    }

    public void F_Subtraction(bool set)
    {
        int bit = 7 % 8;
        var mask = (byte) (1 << bit);
        if (set)
        {
            F |= mask;
        }
        else
        {
            F &= (byte) ~mask;
        }
    }
    
    public byte F_Subtraction()
    {
        int bit = 7 % 8;
        var mask = (byte) (1 << bit);
        return (byte) ((F & mask) >> bit);
    }
    
    public void F_HalfCarry(bool set)
    {
        int bit = 6 % 8;
        var mask = (byte) (1 << bit);
        if (set)
        {
            F |= mask;
        }
        else
        {
            F &= (byte) ~mask;
        }
    }
    
    public byte F_HalfCarry()
    {
        int bit = 6 % 8;
        var mask = (byte) (1 << bit);
        return (byte) ((F & mask) >> bit);
    }
    
    public void F_Carry(bool set)
    {
        int bit = 5 % 8;
        var mask = (byte) (1 << bit);
        if (set)
        {
            F |= mask;
        }
        else
        {
            F &= (byte) ~mask;
        }
    }
    
    public byte F_Carry()
    {
        int bit = 5 % 8;
        var mask = (byte) (1 << bit);
        return (byte) ((F & mask) >> bit);
    }
    
    public override string ToString()
    {
        return $"PC:{PC:X}, A:{A:X}, B:{B:X}, C:{C:X}, D:{D:X}, E:{E:X}, F:{F:X}, H:{H:X}, L:{L:X} SP:{SP:X} AF:{AF:X} BC:{BC:X} DE:{DE:X}\n";
    }
}