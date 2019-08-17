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

fileprivate func makePipeline(device: MTLDevice) -> MTLRenderPipelineState? {
  let pipelineDescriptor = MTLRenderPipelineDescriptor()
  let library = device.makeDefaultLibrary()
  pipelineDescriptor.vertexFunction = library?.makeFunction(name: "TextureRenderer__vertex_shader")
  pipelineDescriptor.fragmentFunction = library?.makeFunction(
    name: "TextureRenderer__fragment_shader")
  pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
  return try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
}

class TextureRenderer: NSObject, MTKViewDelegate {
  var textureSource: TextureSource?
  private let commandQueue: MTLCommandQueue!
  private let pipeline: MTLRenderPipelineState!

  init?(device: MTLDevice) {
    guard let commandQueue = device.makeCommandQueue(), let pipeline = makePipeline(device: device)
    else { return nil }

    self.commandQueue = commandQueue
    self.pipeline = pipeline

    super.init()
  }

  override init() {
    let device = MTLCreateSystemDefaultDevice()!
    self.commandQueue = device.makeCommandQueue()
    self.pipeline = makePipeline(device: device)
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
    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    encoder.endEncoding()

    commandBuffer.present(view.currentDrawable!)
    commandBuffer.commit()
  }

}

