using System;
using Cade.Common.Interfaces;

namespace Cade.DMG;

public class GbOutputManager : CadeOutputManager
{
    private GraphicsView? graphicsView;
    //private GraphicsCanvas graphicsCanvas;

    public GbOutputManager()
	{
	}

    public override void AddGraphicsView(GraphicsView graphicsView)
    {
        this.graphicsView = graphicsView;
        //TODO: Add Graphics Canvas
        //this.graphicsView.Drawable = graphicsCanvas;
    }

    public override void Dispose()
    {
        throw new NotImplementedException();
    }

    public override void Draw()
    {
        throw new NotImplementedException();
    }

    public override void Setup()
    {
        throw new NotImplementedException();
    }
}

