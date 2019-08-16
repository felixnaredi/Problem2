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
