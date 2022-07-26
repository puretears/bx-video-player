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

public struct BXVideoPlayer: View {
  @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
  @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
  
  @ObservedObject var model: VideoModel
  
  // Player width and height
//  @State var width: CGFloat = UIScreen.width
//  @State var height: CGFloat = UIScreen.height
  
  var width: CGFloat { UIScreen.width }
  var height: CGFloat { UIScreen.height }
  
  var isPortrait: Bool {
    return horizontalSizeClass == .compact && verticalSizeClass == .regular
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
  }
  
  public var body: some View {
      ZStack {
        Color.yellow
          .border(Color.red, width: 6)
          .ignoresSafeArea()
        
        // video
        GeometryReader { _ in
          ZStack {
            VideoPlayerLayer(model: model)
              .frame(width: contentWidth, height: contentHeight)
              .border(Color.red, width: 4)
            
            // control
            ControlsLayer(model: model)
              .border(Color.brown, width: 6)
            
            GestureLayer()
              .border(Color.green, width: 6)
          }
        }
      }
  }
  
  func makePlayer() -> some View {
    ZStack(alignment: .center) {
      Color.yellow.border(Color.red, width: 6)
      VStack {
        Spacer()
        Text("Hello")
      }
      
//        Color.blue.edgesIgnoringSafeArea(.all)
      
//        VideoPlayerLayer(model: model)
//          .frame(
//            width: contentWidth,
//            height: contentHeight
//          )
//
//        ControlsLayer(model: model)
//          .frame(
//            width: proxy.size.width,
//            height: isPortrait ? UIScreen.width / model.ratio : UIScreen.height
//          )
//          .border(Color.orange, width: 4)
//
//        GestureLayer()
//          .frame(
//            width: proxy.size.width,
//            height: isPortrait ? UIScreen.width / model.ratio : UIScreen.height
//          )
    }
    .frame(height: UIScreen.height)
//      .ignoresSafeArea(edges: [.top, .bottom])
    .border(Color.blue, width: 6)
//      .frame(maxHeight: .infinity)
    
//      .onRotate {
//        if $0 == .portrait {
//          print("Portrait")
//
//          if UIScreen.width > UIScreen.height {
//            width = UIScreen.height
//            height = width / model.ratio
//          }
//        }
//        else if ($0 == .landscapeLeft) || ($0 == .landscapeRight) {
//          print("Landscape")
//
//          if UIScreen.width < UIScreen.height {
//            height = UIScreen.width
//            width = height * model.ratio
//          }
//        }
//        print("w: \(width) h: \(height)")
//      }
  }
}

//struct BXVideoPlayer_Previews: PreviewProvider {
//  static var previews: some View {
//    BXVideoPlayer(
//      model: VideoModel(url: URL(string: "https://free-video.boxueio.com/h-task-local-storage-basic.mp4")!)
//    )
//  }
//}
