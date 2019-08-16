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

struct OneColorTexture: TextureSource {
  let device: MTLDevice
  let _rgba_color: simd_float4

  var bgra8unorm: Int32 {
    return Int32(_rgba_color[2] * 255) | Int32(_rgba_color[1] * 255) << 8 | Int32(
      _rgba_color[0] * 255) << 16
      | Int32(_rgba_color[3] * 255) << 24
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
