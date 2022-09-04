using System;
using Cade.Common.Interfaces;
using Cade.DMG.Core;

namespace Cade.DMG;

public class GbExtension : CadeExtension
{
    private CoreManager? coreManager;
    private IDispatcherTimer? cpuTimer;
    private IDispatcherTimer? graphicsTimer;

    public GbExtension() : base(new GbInputManager(), new GbOutputManager())
	{}

    public override string ExtensionName => "GameBoy";

    public override string ExtensionDescription => "Nintendo GameBoy extension for the Cade arcade system";

    public override string ExtensionDeveloper => "Cade";

    public override Guid ExtensionGuid => Guid.Parse("04c192df-279f-444f-baf4-5358e49ebdef");

    public override string PlatformName => "Nintendo GameBoy";

    public override string PlatformDescription => "The Game Boy is an 8-bit handheld game console developed and manufactured by Nintendo.";

    public override string PlatformDeveloper => "Nintendo";

    public override int MaxPlayers => 1;

    public override DateTime ReleaseDate => new DateTime(1989, 04, 21);

    public override string[] SupportedFileExtensions => new string[] { "gb" };

    public override void Close()
    {
        cpuTimer?.Stop();
        graphicsTimer?.Stop();
    }

    public override void Load(string path)
    {
        throw new NotImplementedException();
    }

    public override void Load(byte[] file)
    {
        coreManager?.LoadGame(file);
    }

    public override void Run(CancellationTokenSource cancellationTokenSource)
    {
        if(coreManager is not null)
        {
            var dispatcher = Application.Current!.Dispatcher; // if your context isn't a BindableObject (if your context is a BO then just this.Dispatcher...)
            cpuTimer = dispatcher.CreateTimer();
            cpuTimer.Interval = TimeSpan.FromSeconds(1.0 / 4194304);
            cpuTimer.Tick += (s, e) =>
            {
                coreManager.Tick();
            };
            cpuTimer.Start();



            graphicsTimer = dispatcher.CreateTimer();
            graphicsTimer.Interval = TimeSpan.FromSeconds(1.0 / 59.73);
            graphicsTimer.Tick += (s, e) =>
            {
                //TODO: emulate the graphics update
            };
            graphicsTimer.Start();
        }
    }

    public override void Setup()
    {
        coreManager = new();
    }

    public override void Toggle()
    {
        throw new NotImplementedException();
    }
}

