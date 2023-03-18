using System;
using Cade.Common.Interfaces;

namespace Cade.DMG;

public class DmgOutputManager : CadeOutputManager
{
    // private GraphicsView? graphicsView;
    // private DMGGraphicsCanvas graphicsCanvas;

    public DmgOutputManager()
	{
        // graphicsCanvas = new();
	}

    // public override void AddGraphicsView(GraphicsView graphicsView)
    // {
    //     this.graphicsView = graphicsView;
    //     this.graphicsView.Drawable = graphicsCanvas;
    // }

    public override void Dispose()
    {
        
    }

    public override void Draw()
    {
        // graphicsView?.Invalidate();
    }

    public override void Setup()
    {
        
    }
}

