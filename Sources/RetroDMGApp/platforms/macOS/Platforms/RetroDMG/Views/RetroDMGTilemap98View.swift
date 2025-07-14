//
//  RetroDMGDebugView.swift
//  Retro
//
//  Created by Glenn Hevey on 19/1/2025.
//

import SwiftUI
import MetalKit
import RetroDMG
import RetroKit

struct RetroDMGTilemap98View: View {
    var core: RetroDMG!
    
    init(core: RetroDMG!) {
        self.core = core
    }
    
    var body: some View {
        RetroDMGViewPort {
            RetroDMGTilemap98MetalView(core: core)
        }
        .aspectRatio(CGSize(width: 160, height: 144), contentMode: .fit)
    }
}


class RetroDMGTilemap98MetalView: MTKView {
    var renderer: RetroDMGTilemap98Renderer!
    var core: RetroDMG!
    var debugView: Bool = false
    
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
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createRenderer(device: MTLDevice){
        renderer = RetroDMGTilemap98Renderer(device: device, core: self.core)
        delegate = renderer
    }
}

// MARK: Renderer
class RetroDMGTilemap98Renderer: NSObject {
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
    }
    
    //MARK: Builders
    func createCommandQueue(device: MTLDevice) {
        commandQueue = device.makeCommandQueue()
    }
    
    func createPipelineState(device: MTLDevice) {
        do {
            // The device will make a library for us
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
            // Try to update the state of the renderPipeline
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

extension RetroDMGTilemap98Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        view.clearColor = MTLClearColor(red: 0.804, green: 0.859, blue: 0.878, alpha: 1)
    }
    
    func draw(in view: MTKView) {
        let pixels =  core.tileMap(get9800: true)
        let black = SIMD4<Float>(0.149, 0.169, 0.169, 1)
        let dark = SIMD4<Float>(0.4, 0.42, 0.439, 1)
        let light = SIMD4<Float>(0.58, 0.624, 0.659, 1)
        let white = SIMD4<Float>(0.804, 0.859, 0.878, 1)
        
        vertices.removeAll(keepingCapacity: true)
        
        for pixel in 0..<pixels.count {
            let colour = pixels[pixel] == 0 ? white : pixels[pixel] == 1 ? light : pixels[pixel] == 2 ? dark : black
            let tilesPerRow: Float = 32
            let rowsPerScreen: Float = 32
            
            let pixelWidth: Float = 2 / 8 / tilesPerRow
            let pixelHeight: Float = 2 / 8 / rowsPerScreen
            
            let x = pixelWidth * Float(pixel % (Int(tilesPerRow) * 8)) - 1
            let y = pixelHeight * Float(pixel / (Int(tilesPerRow) * 8)) - 1
            
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
