﻿using System;
using Cade.Common.Interfaces;
using Cade.Common.Models;
#if MACCATALYST
using UIKit;
#endif


namespace Cade.DMG
{
	public class DmgInputManager : CadeInputManager
	{
		public DmgInputManager()
		{
		}

        private static Lazy<List<Input>> _lazy = new(() => new List<Input>
        {
            new Input
            {
                Name = "Up",
                Active = false,
                Number = 1,
                Player = 1,
                Type = InputType.Button,
            },
            new Input
            {
                Name = "Down",
                Active = false,
                Number = 2,
                Player = 1,
                Type = InputType.Button,
            },
            new Input
            {
                Name = "Left",
                Active = false,
                Number = 3,
                Player = 1,
                Type = InputType.Button,
            },
            new Input
            {
                Name = "Right",
                Active = false,
                Number = 4,
                Player = 1,
                Type = InputType.Button,
            },
            new Input
            {
                Name = "A",
                Active = false,
                Number = 5,
                Player = 1,
                Type = InputType.Button,
            },
            new Input
            {
                Name = "B",
                Active = false,
                Number = 6,
                Player = 1,
                Type = InputType.Button,
            },
            new Input
            {
                Name = "Start",
                Active = false,
                Number = 7,
                Player = 1,
                Type = InputType.Button,
            },
            new Input
            {
                Name = "Select",
                Active = false,
                Number = 8,
                Player = 1,
                Type = InputType.Button,
            },
        });

        public override List<Input> Inputs()
        {
            return _lazy.Value;
        }

        public override int MaxPlayers()
        {
            return 1;
        }

        public override void Update(List<Input> inputs)
        {
            _lazy = new Lazy<List<Input>>(() => inputs);
        }
    }
}

