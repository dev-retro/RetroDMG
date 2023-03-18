using System.Globalization;
using System.Runtime.InteropServices;
using Cade.DMG;
using Cade.DMG.NativeAOT;

namespace Cade.Chip8.NativeAOT;

public class ExtensionDetails
{
    [UnmanagedCallersOnly(EntryPoint = "GetMetadata")]
    public static Metadata GetMetadata()
    {
        DmgExtension extension = new();

        Metadata metadata = new()
        {
            ExtensionName = Marshal.StringToHGlobalAnsi(extension.ExtensionName),
            ExtensionDescription = Marshal.StringToHGlobalAnsi(extension.ExtensionDescription),
            ExtensionDeveloper = Marshal.StringToHGlobalAnsi(extension.ExtensionDeveloper),
            ExtensionGuid = Marshal.StringToHGlobalAnsi(extension.ExtensionGuid.ToString()),
            PlatformName = Marshal.StringToHGlobalAnsi(extension.PlatformName),
            PlatformDescription = Marshal.StringToHGlobalAnsi(extension.PlatformDescription),
            PlatformDeveloper = Marshal.StringToHGlobalAnsi(extension.PlatformDeveloper),
            MaxPlayers = extension.MaxPlayers,
            ReleaseDate = Marshal.StringToHGlobalAnsi(extension.ReleaseDate.ToString(CultureInfo.InvariantCulture)),
            SupportFileExtensions = Marshal.StringToHGlobalAnsi(string.Join(";", extension.SupportedFileExtensions))
        };
        

        return metadata;
    }

    [UnmanagedCallersOnly(EntryPoint = "FreeMetadata")]
    public static int FreeMetadata(IntPtr metadata)
    {
        var handle = GCHandle.FromIntPtr(metadata);
        handle.Free();
        
        return 0;
    }
}