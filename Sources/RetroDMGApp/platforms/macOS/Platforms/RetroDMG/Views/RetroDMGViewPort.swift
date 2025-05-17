import SwiftUI
import MetalKit
import RetroDMG
import RetroKit

// MARK: SwiftUI + Metal
public struct RetroDMGViewPort: NSViewRepresentable {
    public var wrappedView: NSView
    
    private var handleUpdateUIView: ((NSView, Context) -> Void)?
    private var handleMakeUIView: ((Context) -> NSView)?
    
    public init(closure: () -> NSView) {
        wrappedView = closure()
    }
    
    public func makeNSView(context: Context) -> NSView {
        guard let handler = handleMakeUIView else {
            return wrappedView
        }
        
        return handler(context)
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {
        handleUpdateUIView?(nsView, context)
    }
    
    mutating func setMakeUIView(handler: @escaping (Context) -> NSView) -> Self {
        handleMakeUIView = handler
        
        return self
    }
    
    mutating func setUpdateUIView(handler: @escaping (NSView, Context) -> Void) -> Self {
        handleUpdateUIView = handler
        
        return self
    }
}

// MARK: Metal Stuff

class RetroDMGMetalView: MTKView {
    var renderer: RetroDMGRenderer!
    var core: RetroDMG!
    
    init(core: RetroDMG) {
        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
        // Make sure we are on a device that can run metal!
        guard let defaultDevice = device else {
            fatalError("Device loading error")
        }
        colorPixelFormat = .bgra8Unorm
        // Our clear color, can be set to any color
        clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        self.core = core
        createRenderer(device: defaultDevice)
    }
    
    public func update(inputs: [RetroInput]) {
        core.update(inputs: inputs)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createRenderer(device: MTLDevice){
        renderer = RetroDMGRenderer(device: device, core: self.core)
        delegate = renderer
    }
}

// MARK: Renderer
class RetroDMGRenderer: NSObject {
    var commandQueue: MTLCommandQueue!
    var renderPipelineState: MTLRenderPipelineState!
    
    var vertexBuffer: MTLBuffer!
    var vertices = [Vertex]()
    var core: RetroDMG
    var device: MTLDevice
    
    init(device: MTLDevice, core: RetroDMG) {
        self.device = device
        self.core = core

        
        super.init()
        
        createCommandQueue(device: device)
        createPipelineState(device: device)
        createBuffers(device: device)
        _ = self.core.start()
    }
    
    //MARK: Builders
    func createCommandQueue(device: MTLDevice) {
        commandQueue = device.makeCommandQueue()
    }
    
    func createPipelineState(device: MTLDevice) {
        // The device will make a library for u
        do {
            let library = try device.makeDefaultLibrary(bundle: Bundle.module)
            // Our vertex function name
            let vertexFunction = library.makeFunction(name: "basic_vertex_function")
            // Our fragment function name
            let fragmentFunction = library.makeFunction(name: "basic_fragment_function")
            // Create basic descriptor
            let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
            // Attach the pixel format that si the same as the MetalView
            renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            // Attach the shader functions
            renderPipelineDescriptor.vertexFunction = vertexFunction
            renderPipelineDescriptor.fragmentFunction = fragmentFunction

            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func createBuffers(device: MTLDevice) {
        if !vertices.isEmpty {
            vertexBuffer = device.makeBuffer(bytes: vertices,
                                             length: MemoryLayout<Vertex>.stride * vertices.count,
                                             options: [])
        }
    }
}

extension RetroDMGRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        view.clearColor = MTLClearColor(red: 0.804, green: 0.859, blue: 0.878, alpha: 1)
    }
    
    func draw(in view: MTKView) {
        let pixels = core.viewPort()
        let black = SIMD4<Float>(0.149, 0.169, 0.169, 1)
        let dark = SIMD4<Float>(0.4, 0.42, 0.439, 1)
        let light = SIMD4<Float>(0.58, 0.624, 0.659, 1)
        let white = SIMD4<Float>(0.804, 0.859, 0.878, 1)
        
        vertices.removeAll(keepingCapacity: true)
        
        for pixel in 0..<pixels.count {
            let colour = pixels[pixel] == 0 ? white : pixels[pixel] == 1 ? light : pixels[pixel] == 2 ? dark : black
            let tilesPerRow: Float = 20
            let rowsPerScreen: Float = 18
            
            let pixelWidth: Float = 2 / 8 / tilesPerRow
            let pixelHeight: Float = 2 / 8 / rowsPerScreen
            
            let x = pixelWidth * Float(pixel % 160) - 1
            let y = pixelHeight * Float(pixel / 160) - 1
            
            vertices.append(Vertex(position: SIMD3(x, y, 0), color: colour))
            vertices.append(Vertex(position: SIMD3(x + pixelWidth, y, 0), color: colour))
            vertices.append(Vertex(position: SIMD3(x, y + pixelHeight, 0), color: colour))
            vertices.append(Vertex(position: SIMD3(x + pixelWidth, y + pixelHeight, 0), color:colour))
        }
        
        
        createBuffers(device: device)
        
        // Get the current drawable and descriptor
        guard let drawable = view.currentDrawable,
            let renderPassDescriptor = view.currentRenderPassDescriptor else {
                return
        }
        // Create a buffer from the commandQueue
        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        commandEncoder?.setRenderPipelineState(renderPipelineState)
        // Pass in the vertexBuffer into index 0
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        
        for primativeCount in stride(from: 0, to: vertices.count, by: 4) {
            commandEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: primativeCount, vertexCount: 4)
        }
        
        commandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        

    }
}
