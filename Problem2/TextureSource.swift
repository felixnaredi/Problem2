//
//  TextureSource.swift
//  Problem2
//
//  Created by Felix Naredi on 2019-08-15.
//  Copyright © 2019 Felix Naredi. All rights reserved.
//

import Foundation
import MetalKit
import simd

// -------------------------------------------------------------------------------------------------
// Utility extensions.
//

extension MTLOrigin: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Int...) {
    self.init(x: elements[0], y: elements[1], z: elements[2])
  }
}

extension MTLSize: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Int...) {
    self.init(width: elements[0], height: elements[1], depth: elements[2])
  }
}

// -------------------------------------------------------------------------------------------------
// Main protocol.
//

protocol TextureSource {
  func texture(width: Int, height: Int) -> MTLTexture?
}

// -------------------------------------------------------------------------------------------------
// Example structures based on TextureSource.
//

fileprivate func convert_bgra8unorm(red: Float, green: Float, blue: Float, alpha: Float) -> Int32 {
  return Int32(blue * 255) | Int32(green * 255) << 8 | Int32(red * 255) << 16 | Int32(alpha * 255)
    << 24
}

fileprivate func convert_bgra8unorm(_ vector: simd_float4) -> Int32 {
  return convert_bgra8unorm(red: vector[0], green: vector[1], blue: vector[2], alpha: vector[3])
}

struct OneColorTexture: TextureSource {
  let device: MTLDevice
  let _rgba_color: simd_float4

  var bgra8unorm: Int32 {
    return convert_bgra8unorm(_rgba_color)
  }

  init(device: MTLDevice, red: Float, green: Float, blue: Float, alpha: Float) {
    self.device = device
    _rgba_color = [red, green, blue, alpha]
  }

  func texture(width: Int, height: Int) -> MTLTexture? {
    // Create texture.
    guard
      let texture = device.makeTexture(
      descriptor: MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false))
    else { return nil }

    // Fill texture (monad) with pixels of the chosen color for the source.
    [Int32](
      repeating: bgra8unorm, count: width * height).withUnsafeBytes({
      (buffer: UnsafeRawBufferPointer) in

      texture.replace(
        region: MTLRegion(
          origin: [0, 0, 0], size: [width, height, 1]),
        mipmapLevel: 0, withBytes: buffer.baseAddress!,
        bytesPerRow: width * MemoryLayout<Int32>.alignment)
    })

    return texture
  }
}

struct HorizontalSplitTexture: TextureSource {
  let device: MTLDevice
  let _rgba_colors: [simd_float4]

  var bgra8unorm: [Int32] { return _rgba_colors.map(convert_bgra8unorm) }

  init(device: MTLDevice, colors: [simd_float4]) {
    self.device = device
    _rgba_colors = colors
  }

  func texture(width: Int, height: Int) -> MTLTexture? {
    // Create texture.
    guard
      let texture = device.makeTexture(
      descriptor: MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false))
    else { return nil }

    // Fill texture (monad) with pixels of the chosen color for the source.
    let rowHeight = height / _rgba_colors.count
    for (offset, pixel) in bgra8unorm.enumerated() {
      [Int32](
        repeating: pixel, count: width * rowHeight).withUnsafeBytes({
        (buffer: UnsafeRawBufferPointer) in
        texture.replace(
          region: MTLRegion(
            origin: [0, offset * rowHeight, 0], size: [width, rowHeight, 1]),
          mipmapLevel: 0, withBytes: buffer.baseAddress!,
          bytesPerRow: width * MemoryLayout<Int32>.alignment)
      })
    }

    return texture
  }
}

/// The PolygonTexturePipeline is used as a factory for making texture sources drawing polygons.
struct PolygonTexturePipeline {
  let device: MTLDevice
  let commandQueue: MTLCommandQueue
  let pipeline: MTLRenderPipelineState

  init(device: MTLDevice) {
    self.device = device
    self.commandQueue = device.makeCommandQueue()!

    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    let library = device.makeDefaultLibrary()!
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineDescriptor.vertexFunction = library.makeFunction(
      name: "PolygonTexturePipeline__vertex_shader")
    pipelineDescriptor.fragmentFunction = library.makeFunction(
      name: "PolygonTexturePipeline__fragment_shader")
    self.pipeline = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
  }

  struct Source: TextureSource {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let pipeline: MTLRenderPipelineState
    let renderPassDescriptor: MTLRenderPassDescriptor
    let vertices: MTLBuffer
    let count: Int

    func texture(width: Int, height: Int) -> MTLTexture? {
      let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .bgra8Unorm,
        width: width,
        height: height,
        mipmapped: false)
      textureDescriptor.usage = [.shaderRead, .renderTarget]

      let texture = device.makeTexture(descriptor: textureDescriptor)!
      renderPassDescriptor.colorAttachments[0].texture = texture

      let commandBuffer = commandQueue.makeCommandBuffer()!
      let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
      commandEncoder.setRenderPipelineState(pipeline)
      commandEncoder.setVertexBuffer(vertices, offset: 0, index: 0)
      commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: count)

      commandEncoder.endEncoding()
      commandBuffer.commit()

      return texture
    }
  }

  func makeSource(vertices: [(position: simd_float2, color: simd_float3)]) -> Source {
    return
      vertices.withUnsafeBytes({
      let renderPassDescriptor = MTLRenderPassDescriptor()
      renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
      renderPassDescriptor.colorAttachments[0].loadAction = .clear
      renderPassDescriptor.colorAttachments[0].storeAction = .store
      return Source(
        device: device, commandQueue: commandQueue, pipeline: pipeline,
        renderPassDescriptor: renderPassDescriptor,
        vertices: device.makeBuffer(
          bytes: $0.baseAddress!, length: $0.count, options: .cpuCacheModeWriteCombined)!,
        count: vertices.count)
    })
  }
}

struct LinearGradientTexturePipeline<FragmentShaderDeamon: ShaderDaemonProtocol> {
  let device: MTLDevice
  let commandQueue: MTLCommandQueue
  let pipeline: MTLRenderPipelineState
  let fragmentShaderDeamon: FragmentShaderDeamon

  init(device: MTLDevice, fragmentShaderDeamon: FragmentShaderDeamon) {
    self.device = device
    self.commandQueue = device.makeCommandQueue()!

    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineDescriptor.vertexFunction = device.makeDefaultLibrary()!.makeFunction(
      name: "LinearGradientTexture__vertex_shader")
    pipelineDescriptor.fragmentFunction = fragmentShaderDeamon.makeFunction(device: device)
    self.pipeline = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    self.fragmentShaderDeamon = fragmentShaderDeamon
  }

  struct Source: TextureSource {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let pipeline: MTLRenderPipelineState
    let transform: float4x4
    let fragmentShaderDeamon: FragmentShaderDeamon
    let fragmentData: FragmentShaderDeamon.EncoderData

    func texture(width: Int, height: Int) -> MTLTexture? {
      let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .bgra8Unorm,
        width: width,
        height: height,
        mipmapped: false)
      textureDescriptor.usage = [.shaderRead, .renderTarget]

      // TODO:
      // Program crashes when renderPassDescriptor is stored within the object. This has not been
      // an issue before.
      //
      // Unsure on what goes wrong. Mostly it just crashes with a bad memory access error. Other
      // times it complains over memory deallocation. It has also thrown exceptions on the behalf of
      // a missing selector in the internal side of the render pass descriptor.
      //
      // Current solution is to init a new MTLRenderPassDescriptor each time a texture is made.
      let renderPassDescriptor = MTLRenderPassDescriptor()
      renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
      renderPassDescriptor.colorAttachments[0].loadAction = .clear
      renderPassDescriptor.colorAttachments[0].storeAction = .store

      let texture = device.makeTexture(descriptor: textureDescriptor)!
      renderPassDescriptor.colorAttachments[0].texture = texture

      let commandBuffer = commandQueue.makeCommandBuffer()!
      let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
      commandEncoder.setRenderPipelineState(pipeline)

      var transform = self.transform
      commandEncoder.setVertexBytes(&transform, length: MemoryLayout<float4x4>.size, index: 0)

      fragmentShaderDeamon.encode(with: commandEncoder, data: fragmentData)

      commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

      commandEncoder.endEncoding()
      commandBuffer.commit()

      return texture
    }
  }

  func makeTextureSource(
    transformMatrix: simd_float4x4,
    fragmentData: FragmentShaderDeamon.EncoderData
  ) -> Source {
    return Source(
      device: device, commandQueue: commandQueue, pipeline: pipeline, transform: transformMatrix,
      fragmentShaderDeamon: fragmentShaderDeamon, fragmentData: fragmentData)
  }

}
