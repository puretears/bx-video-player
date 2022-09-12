//
//  SwiftUIView.swift
//
//
//  Created by Mars on 2022/6/22.
//

import SwiftUI
import AVKit

public extension UIScreen {
  static var width: CGFloat {
    UIApplication.shared.connectedScenes
      .compactMap { scene -> UIWindow? in
        (scene as? UIWindowScene)?.keyWindow
      }
      .first?
      .screen.bounds.width ?? 0
  }
  
  static var height: CGFloat {
    UIApplication.shared.connectedScenes
      .compactMap { scene -> UIWindow? in
        (scene as? UIWindowScene)?.keyWindow
      }
      .first?
      .screen.bounds.height ?? 0
  }
  
  static var isLandscape: Bool {
    UIDevice.current.orientation.isLandscape
  }
  
  static var br: CGFloat {
    get {
      UIApplication.shared.connectedScenes
        .compactMap { scene -> UIWindow? in
          (scene as? UIWindowScene)?.keyWindow
        }
        .first?
        .screen.brightness ?? 0.5
    }
    set {
      UIApplication.shared.connectedScenes
        .compactMap { scene -> UIWindow? in
          (scene as? UIWindowScene)?.keyWindow
        }
        .first?
        .screen.brightness = newValue
    }
  }
}

public struct BXVideoPlayer: View {
  @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
  @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
  @Environment(\.scenePhase) var scenePhase
  
  @ObservedObject var model: VideoModel
  
  var width: CGFloat { UIScreen.width }
  var height: CGFloat { UIScreen.height }
  
  var isPortrait: Bool {
    return verticalSizeClass == .regular
  }
  
  var isLandscape: Bool {
    return verticalSizeClass == .compact
  }
  
  var contentWidth: CGFloat {
    if isPortrait {
      return width
    }
    else {
      return height * model.ratio
    }
  }

  var contentHeight: CGFloat {
    if isPortrait {
      return width / model.ratio
    }
    else {
      return height
    }
  }
  
  let controlActions: () -> Void
  
  public init(model: VideoModel,
              controlActions: @escaping () -> Void = {}) {
    self.model = model
    self.controlActions = controlActions
    
    // we need this to use Picture in Picture
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.playback, mode: .moviePlayback)
    } catch {
      print("Setting category to AVAudioSessionCategoryPlayback failed.")
    }
  }
  
  public var body: some View {
    ZStack {
      Color.black
        .ignoresSafeArea()
        
      // video
      GeometryReader { proxy in
        ZStack {
          VideoPlayerLayer(model: model)
#if DEBUG
.overlay {
  makeDebugFrame(color: .red, label: "Video player")
}
#endif
          // control
          ControlsLayer(model: model, controlActions: controlActions)
          
          // Gesture
          GestureLayer(model: model, area: proxy.size)
#if DEBUG
.overlay {
  makeDebugFrame(color: .brown, label: "Gesture area")
}
#endif
          .padding(.top, 44)
          .padding(.bottom, 44)
        }
      }
    }
    .onRotate {
      if $0 == .portrait {
        model.playerOrientation = .portrait
      }
      else if $0 == .landscapeLeft || $0 == .landscapeRight {
        model.playerOrientation = .landscape
      }
    }
    .onAppear {
      model.playerOrientation = isPortrait ? .portrait : .landscape
    }
  }
  
  private func makeDebugFrame(color: Color, label: String) -> some View {
    ZStack(alignment: .topLeading) {
      Rectangle()
        .stroke(color, lineWidth: 2)
      
      Text(label)
        .foregroundColor(color)
        .font(.caption2)
        .padding([.top, .leading], 5)
    }
  }
}

struct BXVideoPlayer_Previews: PreviewProvider {
  static var previews: some View {
    BXVideoPlayer(
      model: VideoModel(
        url: URL(string: "https://free-video.boxueio.com/h-task-local-storage-basic.mp4")!,
        title: "The task local storage"
      )
    )
  }
}
