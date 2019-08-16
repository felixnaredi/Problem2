//
//  main.swift
//  Windmill
//
//  Created by Felix Naredi on 2019-08-13.
//  Copyright © 2019 Felix Naredi. All rights reserved.
//

import Foundation
import simd

func windmill<T>(
  radians: Float,
  transform: @escaping (simd_float2) -> T
) -> LazyMapSequence<UnfoldSequence<float2, (float2?, Bool)>, T> {

  let rotator = simd_float2x2([cos(radians), -sin(radians)], [sin(radians), cos(radians)])
  return sequence(
    first: simd_float2(1, 0),
    next: { return $0 * rotator }
  ).lazy.map({ transform($0) })
}

func windmill<T>(
  radians: Float, initialVector: simd_float2, initialResult: T,
  accumelator: @escaping (T, simd_float2) -> T
) -> LazyMapSequence<UnfoldSequence<(simd_float2, T), ((simd_float2, T)?, Bool)>, T> {

  let rotator = simd_float2x2([cos(radians), -sin(radians)], [sin(radians), cos(radians)])
  return sequence(
    first: (initialVector, initialResult),
    next: {
      let (vector, result) = $0
      return (vector * rotator, accumelator(result, vector))
    }).lazy.map({ $0.1 })
}

for y in windmill(radians: Float.pi / 16.0, transform: { $0.y }) { print(y) }
