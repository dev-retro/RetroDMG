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
    var pixelProvider: () -> [Int]
    var core: RetroDMG!
    var tilesPerRow: Float
    var rowsPerScreen: Float

    init(core: RetroDMG, pixelProvider: @escaping () -> [Int], tilesPerRow: Float = 20, rowsPerScreen: Float = 18, startCore: Bool = false) {
        self.core = core
        self.pixelProvider = pixelProvider
        self.tilesPerRow = tilesPerRow
        self.rowsPerScreen = rowsPerScreen
        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
        guard let defaultDevice = device else {
            fatalError("Device loading error")
        }
        colorPixelFormat = .bgra8Unorm
        clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        if startCore {
            _ = core.start()
        }
        createRenderer(device: defaultDevice)
    }

    public func update(inputs: [RetroInput]) {
        core.update(inputs: inputs)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createRenderer(device: MTLDevice){
        renderer = RetroDMGRenderer(device: device, pixelProvider: pixelProvider, tilesPerRow: tilesPerRow, rowsPerScreen: rowsPerScreen)
        delegate = renderer
    }
}

class RetroDMGRenderer: NSObject {
    var commandQueue: MTLCommandQueue!
    var renderPipelineState: MTLRenderPipelineState!

    var vertexBuffer: MTLBuffer!
    var vertices = [Vertex]()
    var device: MTLDevice
    var pixelProvider: () -> [Int]
    var tilesPerRow: Float
    var rowsPerScreen: Float

    init(device: MTLDevice, pixelProvider: @escaping () -> [Int], tilesPerRow: Float = 20, rowsPerScreen: Float = 18) {
        self.device = device
        self.pixelProvider = pixelProvider
        self.tilesPerRow = tilesPerRow
        self.rowsPerScreen = rowsPerScreen
        super.init()
        createCommandQueue(device: device)
        createPipelineState(device: device)
        createBuffers(device: device)
    }

    //MARK: Builders
    func createCommandQueue(device: MTLDevice) {
        commandQueue = device.makeCommandQueue()
    }

    func createPipelineState(device: MTLDevice) {
        do {
            let library = try device.makeDefaultLibrary(bundle: Bundle.module)
            let vertexFunction = library.makeFunction(name: "basic_vertex_function")
            let fragmentFunction = library.makeFunction(name: "basic_fragment_function")
            let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
            renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
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
        let pixels = pixelProvider()
        let black = SIMD4<Float>(0, 0, 0, 1)
        let dark = SIMD4<Float>(0.5, 0.5, 0.5, 1)
        let light = SIMD4<Float>(0.75, 0.75, 0.75, 1)
        let white = SIMD4<Float>(1, 1, 1, 1)

        vertices.removeAll(keepingCapacity: true)

        for pixel in 0..<pixels.count {
            let colour = pixels[pixel] == 0 ? white : pixels[pixel] == 1 ? light : pixels[pixel] == 2 ? dark : black
            let pixelWidth: Float = 2 / 8 / tilesPerRow
            let pixelHeight: Float = 2 / 8 / rowsPerScreen
            let x = pixelWidth * Float(pixel % Int(tilesPerRow * 8)) - 1
            let y = pixelHeight * Float(pixel / Int(tilesPerRow * 8)) - 1
            vertices.append(Vertex(position: SIMD3(x, y, 0), color: colour))
            vertices.append(Vertex(position: SIMD3(x + pixelWidth, y, 0), color: colour))
            vertices.append(Vertex(position: SIMD3(x, y + pixelHeight, 0), color: colour))
            vertices.append(Vertex(position: SIMD3(x + pixelWidth, y + pixelHeight, 0), color:colour))
        }

        createBuffers(device: device)

        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        commandEncoder?.setRenderPipelineState(renderPipelineState)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        for primativeCount in stride(from: 0, to: vertices.count, by: 4) {
            commandEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: primativeCount, vertexCount: 4)
        }

        commandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
