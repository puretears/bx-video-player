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
  @Binding var showsControlPannel: Bool
  
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
  @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
  
  var isPortrait: Bool {
    return verticalSizeClass == .regular
  }
  
  var isLandscape: Bool {
    return verticalSizeClass == .compact
  }
  
  let controlActions: () -> Void
  
  public init(
    model: VideoModel,
    showsControlPannel: Binding<Bool>,
    controlActions: @escaping () -> Void = {}) {
    self.model = model
    self._showsControlPannel = showsControlPannel
    self.controlActions = controlActions
  }
  
  var body: some View {
    VStack {
      makeTopBar()
        
      Spacer()
      
      makeBottomBar()
    }
    .opacity(model.isDisplayingControl ? 1 : 0)
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
    HStack(spacing: 0) {
      makeBackButton()
      
      Text(model.title)
        .font(.callout)
        .lineLimit(1)
        .truncationMode(.tail)
        .foregroundColor(.white)
      
      Spacer()
      
      Button(action: {
        print("Toggle pip")
        withAnimation {
          model.isPipMode.toggle()
        }
      }, label: {
        Image(systemName: "pip")
          .frame(width: 44, height: 44)
          .foregroundColor(.white)
      })
      
      if showsControlPannel {
        Button(action: {
          controlActions()
        }, label: {
          Image("ellipse", bundle: .module).resizable().frame(width: 20, height: 20)
            .frame(width: 44, height: 44)
            .foregroundColor(.white)
        })
      }
    }
    .frame(height: 44)
    .foregroundColor(.white)
    .background(
      Color.black.opacity(0.5)
    )
  }
  
  @ViewBuilder
  func makeBottomBar() -> some View {
    HStack(spacing: 0) {
      makePlayButton()
      
      makeProgressBar()
      
      makeFullscreenToggle()
    }
    .frame(height: 44)
    .background(
      Color.black.opacity(0.5)
    )
  }
}

extension ControlsLayer {
  /// Top controls
  func makeBackButton() -> some View {
    Button(action: {
      if isPortrait || model.playerOrientation == .portrait {
        presentationMode.wrappedValue.dismiss()
      }
      else if isLandscape || model.playerOrientation == .landscape { // Landscape
        model.playerOrientation = .portrait
        
        if #available(iOS 16.0, *) {
          let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
          windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        } else {
          // Fallback on earlier versions
          UIDevice.current.setValue(
            UIInterfaceOrientation.portrait.rawValue,
            forKey: "orientation"
          )
        }
      }
    }, label: {
      Image(systemName: "chevron.backward")
        .frame(width: 44, height: 44)
        .foregroundColor(.white)
    })
  }
  
  /// Bottom controls
  func makePlayButton() -> some View {
    Button(action: {
      print("Playing")
      if model.isPlaying {
        model.pause()
      }
      else {
        model.play()
      }
    }, label: {
      Group {
        if model.isPlaying {
          Image(systemName: "pause.fill")
        }
        else {
          Image(systemName: "play.fill")
        }
      }
      .frame(width: 44, height: 44)
      .foregroundColor(.white)
    })
    
  }
  
  func makeProgressBar() -> some View {
    HStack {
      BXSliderView(value: $model.currentProgress, onChanged: { curr in
        Task {
          await model.seekTo(percentage:curr)
        }
      }, onEnded: { _ in
        model.isEditingCurrentTime = false
      })
      
      HStack(spacing: 0) {
        Text(model.currentTime.asPlayerString())
        Text("/")
        Text(CGFloat(model.duration).asPlayerString())
      }
      .font(.system(size: 12, design: .monospaced))
      .foregroundColor(.white)
    }
  }
  
  /**
   **Note**
   
   Before iOS 15, the notification mechanism is
   Rotation -> Updating layout -> Notification. In the callback,
   we get the current device orientation after rotation.
   
   But iOS 16 and later, the mechansim changes to
   Rotation -> Notification -> Update layout. So we got the device
   orientation before rotation in the callback.
   */
  func makeFullscreenToggle() -> some View {
    Button(action: {
      if isLandscape || model.playerOrientation == .landscape {
        model.playerOrientation = .portrait
        
        if #available(iOS 16.0, *) {
          let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
          windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        } else {
          // Fallback on earlier versions
          UIDevice.current.setValue(
            UIInterfaceOrientation.portrait.rawValue,
            forKey: "orientation"
          )
        }
      }
      else if isPortrait || model.playerOrientation == .portrait {
        model.playerOrientation = .landscape
        
        if #available(iOS 16.0, *) {
          let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
          windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
        } else {
          // Fallback on earlier versions
          UIDevice.current.setValue(
            UIInterfaceOrientation.landscapeRight.rawValue,
            forKey: "orientation"
          )
        }
      }
    }, label: {
      Image(systemName: "arrow.up.left.and.arrow.down.right")
        .frame(width: 44, height: 44)
        .foregroundColor(.white)
    })
  }
}

struct ControlsLayer_Previews: PreviewProvider {
  static var previews: some View {
    BXVideoPlayer(
      model: VideoModel(
        url: URL(string: "https://free-video.boxueio.com/h-task-local-storage-basic.mp4")!,
        title: "The task local storage - II"
      )
    )
  }
}
