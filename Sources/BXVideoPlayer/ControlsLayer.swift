//
//  SwiftUIView.swift
//  
//
//  Created by Mars on 2022/6/29.
//

import SwiftUI
import BXSliderView

struct ControlsLayer: View {
  @ObservedObject var model: VideoModel
  @State var hPadding: CGFloat = 15
  
  @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
  @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
  
  public init(model: VideoModel) {
    self.model = model
  }
  
  var body: some View {
    VStack {
      makeTopBar()
        
      Spacer()
      
      makeBottomBar()
    }
    .padding(.horizontal, horizontalSizeClass == .compact && verticalSizeClass == .regular ? 15 : 0)
  }
}

extension ControlsLayer {
  @ViewBuilder
  func makeTopBar() -> some View {
    /**
     ┌───────┬────────────────────┬────────────────────┐
     │ Back  │       Title        │     Operations     │
     └───────┴────────────────────┴────────────────────┘
     */
    HStack {
      Button(action: {
        
      }, label: {
        Image(systemName: "chevron.backward")
      })
      
      Text("Title")
      
      Spacer()
      
      Button(action: {
        
      }, label: {
        Image(systemName: "pip")
      })
      
      Button(action: {
        
      }, label: {
        Image("ellipse", bundle: .module).resizable().frame(width: 20, height: 20)
      })
    }
    .frame(height: 44)
    .foregroundColor(.white)
    .overlay(
      Rectangle().foregroundColor(Color.green).opacity(0.7)
    )
  }
  
  func makeBottomBar() -> some View {
    HStack {
      makePlayButton()
      
      makeProgressBar()
      
      Button(action: {
        print("Toggle fullscreen")
      }, label: {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
      })
      .foregroundColor(.white)
    }
    .frame(height: 44)
    .overlay(
      Rectangle().foregroundColor(Color.green).opacity(0.7)
        .allowsHitTesting(false)
    )
  }
}

extension ControlsLayer {
  func makePlayButton() -> some View {
    Button(action: {
      if model.isPlaying {
        model.pause()
      }
      else {
        model.play()
      }
      
    }, label: {
      if model.isPlaying {
        Image(systemName: "pause.fill")
      }
      else {
        Image(systemName: "play.fill")
      }
      
    })
    .foregroundColor(.white)
  }
  
  func makeProgressBar() -> some View {
    HStack {
      BXSliderView(value: $model.currentProgress, onChanged: { curr in
        model.pause()
        
        Task {
          let sec = Double(curr * Float(model.duration))
          await model.seek(to:sec)
        }
      }, onEnded: { _ in
        model.play()
      })
      
      Text("00:00/03:08")
        .font(.caption2)
        .foregroundColor(.white)
    }
  }
}

//struct ControlsLayer_Previews: PreviewProvider {
//  static var previews: some View {
//    BXVideoPlayer(
//      model: VideoModel(url: URL(string: "https://free-video.boxueio.com/h-task-local-storage-basic.mp4")!)
//    )
//  }
//}
