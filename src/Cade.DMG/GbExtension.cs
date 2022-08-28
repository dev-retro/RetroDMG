using System;
using Cade.Common.Interfaces;

namespace Cade.DMG
{
	public class GbExtension : CadeExtension
	{
		public GbExtension() : base(new GbInputManager(), new GbOutputManager())
		{
		}

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
            throw new NotImplementedException();
        }

        public override void Load(string path)
        {
            throw new NotImplementedException();
        }

        public override void Load(byte[] file)
        {
            throw new NotImplementedException();
        }

        public override void Run(CancellationTokenSource cancellationTokenSource)
        {
            throw new NotImplementedException();
        }

        public override void Setup()
        {
            //TODO: when ready us this to get the extension ready.
        }

        public override void Toggle()
        {
            throw new NotImplementedException();
        }
    }
}

