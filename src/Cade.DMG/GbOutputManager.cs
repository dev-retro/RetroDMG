using System;
using Cade.Common.Interfaces;

namespace Cade.DMG;

public class GbOutputManager : CadeOutputManager
{
    private GraphicsView? graphicsView;
    private DMGGraphicsCanvas graphicsCanvas;

    public GbOutputManager()
	{
        graphicsCanvas = new();
	}

    public override void AddGraphicsView(GraphicsView graphicsView)
    {
        this.graphicsView = graphicsView;
        this.graphicsView.Drawable = graphicsCanvas;
    }

    public override void Dispose()
    {
        
    }

    public override void Draw()
    {
        
    }

    public override void Setup()
    {
        
    }
}

