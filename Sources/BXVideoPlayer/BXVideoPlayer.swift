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
}

fileprivate var pv: VideoPlayerLayer?

public struct BXVideoPlayer: View {
  @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
  @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
  @Environment(\.scenePhase) var scenePhase
  
  @ObservedObject var model: VideoModel
//  @State var pv: VideoPlayerLayer?
  
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
  
  public init(model: VideoModel) {
    self.model = model
    // we need this to use Picture in Picture
    let audioSession = AVAudioSession.sharedInstance()
    do {
        try audioSession.setCategory(.playback)
    } catch {
        print("Setting category to AVAudioSessionCategoryPlayback failed.")
    }
  }
  
  public var body: some View {
    ZStack {
      Color.yellow
        .border(Color.red, width: 6)
        .ignoresSafeArea()
      
      // video
      GeometryReader { _ in
        ZStack {
          VideoPlayerLayer(model: model) {
            pv = $0
          }
          .frame(width: contentWidth, height: contentHeight)
          
          // control
          ControlsLayer(model: model)
          
          GestureLayer()
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
    .onChange(of: scenePhase) { newPhase in
      if newPhase == .active {
        print("Active")
        pv?.connect()
      } else if newPhase == .background {
        print("Background")
        pv?.disconnect()
      }
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
