//
//  SwiftUIView.swift
//  
//
//  Created by Mars on 2022/6/30.
//
import UIKit
import SwiftUI
import AVFoundation

class VideoPlayerView: UIView {
  // make this UIView rendered by a video player
  override class var layerClass: AnyClass {
    AVPlayerLayer.self
  }
  
  var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
  
  var player: AVPlayer? {
    get {
      playerLayer.player
    }
    set {
      playerLayer.player = newValue
    }
  }
}

struct VideoPlayerLayer: UIViewRepresentable {
  @ObservedObject var model: VideoModel
  
  func makeUIView(context: Context) -> VideoPlayerView {
    let view = VideoPlayerView()
    view.player = model.player
    
    return view
  }
  
  func updateUIView(_ uiView: VideoPlayerView, context: Context) {
    
  }
}
