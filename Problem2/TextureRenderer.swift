//
//  TextureRenderer.swift
//  Problem2
//
//  Created by Felix Naredi on 2019-08-15.
//  Copyright © 2019 Felix Naredi. All rights reserved.
//

import Foundation
import MetalKit
import simd

class TextureRenderer: NSObject, MTKViewDelegate {
  var textureSource: TextureSource?
  private let commandQueue: MTLCommandQueue!
  private let pipeline: MTLRenderPipelineState!

  override init() {
    guard let device = MTLCreateSystemDefaultDevice() else {
      commandQueue = nil
      pipeline = nil
      super.init()
      return
    }

    commandQueue = device.makeCommandQueue()!

    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    let library = device.makeDefaultLibrary()!
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")!
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "samplingShader")!
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    try! pipeline = device.makeRenderPipelineState(descriptor: pipelineDescriptor)

    super.init()
  }

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

  func draw(in view: MTKView) {
    let (viewWidth, viewHeight) = (Int(view.frame.width), Int(view.frame.height))
    guard let texture = textureSource?.texture(width: viewWidth, height: viewHeight) else { return }

    let commandBuffer = commandQueue.makeCommandBuffer()!
    let encoder = commandBuffer.makeRenderCommandEncoder(
      descriptor: view.currentRenderPassDescriptor!)!
    encoder.setRenderPipelineState(pipeline)
    encoder.setFragmentTexture(texture, index: 0)
    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    encoder.endEncoding()

    commandBuffer.present(view.currentDrawable!)
    commandBuffer.commit()
  }

}
