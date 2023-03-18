using System.Runtime.InteropServices;

namespace Cade.DMG.NativeAOT;

[StructLayout(LayoutKind.Sequential)]
public struct Metadata
{
    public IntPtr ExtensionName;
    public IntPtr ExtensionDescription;
    public IntPtr ExtensionDeveloper;
    public IntPtr ExtensionGuid;
    public IntPtr PlatformName;
    public IntPtr PlatformDescription;
    public IntPtr PlatformDeveloper;
    public int MaxPlayers;
    public IntPtr ReleaseDate;
    public IntPtr SupportFileExtensions;
}