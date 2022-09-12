//
//  SwiftUIView.swift
//  
//
//  Created by Mars on 2022/6/30.
//
import UIKit
import SwiftUI
import Combine
import AVFoundation
import AVKit

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
    
    Task {
      try? await model.setCurrentItem(url: model.url)
      context.coordinator.setController(view.playerLayer)
    }
    
    return view
  }
  
  func updateUIView(_ uiView: VideoPlayerView, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    return Coordinator(self)
  }
}

class Coordinator: NSObject, AVPictureInPictureControllerDelegate {
  private let parent: VideoPlayerLayer
  private var controller: AVPictureInPictureController?
  private var cancellable: AnyCancellable?
  
  init(_ parent: VideoPlayerLayer) {
    self.parent = parent
    super.init()
    
    cancellable = parent.model.$isPipMode
      .sink { [weak self] (pipMode: Bool) in
        guard let self = self, let controller = self.controller else { return }
        
        if pipMode {
          if !controller.isPictureInPictureActive {
            controller.startPictureInPicture()
          }
        }
        else {
          if controller.isPictureInPictureActive {
            controller.stopPictureInPicture()
          }
        }
      }
  }
  
  func setController(_ playerLayer: AVPlayerLayer) {
    controller = AVPictureInPictureController(playerLayer: playerLayer)
    controller?.canStartPictureInPictureAutomaticallyFromInline = true
    controller?.delegate = self
  }
  
  func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    parent.model.isPipMode = true
  }
  
  func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    parent.model.isPipMode = false
  }
  
  func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
    print(error)
  }
}
