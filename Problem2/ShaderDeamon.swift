//
//  ShaderDeamon.swift
//  Problem2
//
//  Created by Felix Naredi on 2019-08-18.
//  Copyright © 2019 Felix Naredi. All rights reserved.
//

import Foundation
import Metal
import simd

protocol ShaderDaemonProtocol {

  associatedtype EncoderData

  var functionName: String { get }

  func makeFunction(device: MTLDevice) -> MTLFunction?
  func encode(with encoder: MTLRenderCommandEncoder, data: EncoderData)
}

struct PeekGraphFragmentShaderDeamon: ShaderDaemonProtocol {

  var functionName: String { return "LinearGradientTexture__smooth_peek_fragment_shader" }

  func makeFunction(device: MTLDevice) -> MTLFunction? {
    return device.makeDefaultLibrary()?.makeFunction(name: functionName)
  }

  func encode(with encoder: MTLRenderCommandEncoder, data: MTLBuffer) {
    encoder.setFragmentBuffer(data, offset: 0, index: 0)
  }

  static func makeBuffer(
    device: MTLDevice, negativeColor: simd_float4, positiveColor: simd_float4,
    peekColor: simd_float4, slope: simd_float4
  ) -> MTLBuffer {
    return [
      negativeColor, positiveColor, peekColor, slope,
    ].withUnsafeBytes({
      return device.makeBuffer(
        bytes: $0.baseAddress!, length: MemoryLayout<simd_float4>.stride * 4,
        options: .cpuCacheModeWriteCombined)!
    })
  }
}
