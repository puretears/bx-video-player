import SwiftUI
import AVKit

public struct VideoPlayerControllerLayer: UIViewControllerRepresentable {
  @ObservedObject var model: VideoModel
  
  public init(model: VideoModel) {
    self.model = model
  }
  
  public func makeUIViewController(context: Context) -> AVPlayerViewController {
    
    let controller = AVPlayerViewController()
    
    controller.player = model.player
    controller.showsPlaybackControls = false
    
    if #available(iOS 16.0, *) {
      controller.allowsVideoFrameAnalysis = false
    }
    
    return controller
  }
  
  public func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    let player = AVPlayer(url: model.url)
    
    uiViewController.player = player
    uiViewController.showsPlaybackControls = false
    
    if #available(iOS 16.0, *) {
      uiViewController.allowsVideoFrameAnalysis = false
    }
  }
}
