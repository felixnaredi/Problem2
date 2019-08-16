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
  private var color = simd_float3(0.8, 0.5, 0.3)

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
  @IBOutlet weak var textureView: ClickDrawPolygonView!

  var renderer: TextureRenderer?

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let device = MTLCreateSystemDefaultDevice()!

    renderer = TextureRenderer(device: device)

    textureView.delegate = renderer
    textureView.device = device
    textureView.pipeline = PolygonTexturePipeline(device: device)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

}

