//
//  AppDelegate.swift
//  Problem2
//
//  Created by Felix Naredi on 2019-08-13.
//  Copyright © 2019 Felix Naredi. All rights reserved.
//

import Cocoa
import MetalKit

class ClickDrawPolygonView: MTKView {

  var pipeline: PolygonTexturePipeline?
  private var vertices = [(simd_float2, simd_float3)]()
  private var color = simd_float3(0.8, 0.3, 0.2)

  private func nextColor() -> simd_float3 { return [color[2], color[0], color[1]] }

  private func undoLastVertex() -> Bool {
    guard let element = vertices.popLast() else { return false }
    color = element.1

    if vertices.isEmpty { return true }

    if let delegate = delegate as? TextureRenderer {
      delegate.textureSource = pipeline?.makeSource(vertices: vertices)
    }

    return true
  }

  override func mouseDown(with event: NSEvent) {
    let location = convert(event.locationInWindow, from: nil)
    let (x, y) = (Float(location.x), Float(location.y))
    let (w, h) = (Float(frame.width), Float(frame.height))
    vertices.append(([2 * x / w - 1, 2 * y / h - 1], color))
    color = nextColor()

    guard let delegate = delegate as? TextureRenderer else { return }
    delegate.textureSource = pipeline?.makeSource(vertices: vertices)
  }

  override var acceptsFirstResponder: Bool { return true }

  override func keyDown(with event: NSEvent) {
    let backspace = 51
    print(event.keyCode)

    if event.keyCode == backspace {
      if undoLastVertex() { return }
    }

    super.keyDown(with: event)
  }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!
  @IBOutlet weak var textureView: MTKView!

  var renderer: TextureRenderer?
  var pipeline: LinearGradientTexturePipeline?

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let device = MTLCreateSystemDefaultDevice()!

    renderer = TextureRenderer(device: device)
    pipeline = LinearGradientTexturePipeline(device: device)

    Thread(block: {
      for r in sequence(first: Float(0), next: { ($0 + 0.01).remainder(dividingBy: 2 * Float.pi) })
      {
        let c = cos(r)
        let s = sin(r)
        let z: Float = 0.1  // abs(c) + 0.5

        self.renderer?.textureSource = self.pipeline?.makeSource(
          transform:
            float4x4([c, -s, 0, 0], [s, c, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]) * float4x4(
            [z, 0, 0, 0], [0, z, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]) * float4x4(
            [1, 0, 0, 0], [0, 1, 0, s], [0, 0, 1, 0], [0, 0, 0, 1])
        )

        Thread.sleep(forTimeInterval: 0.016)
      }
    }).start()

    textureView.delegate = renderer
    textureView.device = device
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

}

