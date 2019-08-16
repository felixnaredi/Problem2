//
//  AppDelegate.swift
//  Problem2
//
//  Created by Felix Naredi on 2019-08-13.
//  Copyright © 2019 Felix Naredi. All rights reserved.
//

import Cocoa
import MetalKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!
  @IBOutlet weak var textureView: MTKView!

  let renderer = TextureRenderer()

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let device = MTLCreateSystemDefaultDevice()!

    textureView.delegate = renderer
    textureView.device = device

    // A simple spiel altering between colors of the displayed texture.
    Thread(block: {
      let rotator = simd_float2x2(
        [cos(Float.pi / 180.0), -sin(Float.pi / 180.0)],
        [sin(Float.pi / 180.0), cos(Float.pi / 180.0)])
      let greenRot = simd_float2x2(
        [cos(Float.pi / 1.5), -sin(Float.pi / 1.5)],
        [sin(Float.pi / 1.5), cos(Float.pi / 1.5)])
      let blueRot = simd_float2x2(
        [cos(Float.pi / -1.5), -sin(Float.pi / -1.5)],
        [sin(Float.pi / -1.5), cos(Float.pi / -1.5)])

      for vector in sequence(first: simd_float2(1, 0), next: { $0 * rotator }) {
        self.renderer.textureSource = OneColorTexture(
          device: device, red: max(vector.x, 0), green: max((vector * greenRot).x, 0),
          blue: max((vector * blueRot).x, 0), alpha: 1.0)

        Thread.sleep(forTimeInterval: 0.16)
      }
    }).start()
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

}

