//
//  SwiftUIView.swift
//  
//
//  Created by Mars on 2022/7/15.
//

import SwiftUI

enum DragOperation {
  case none
  case volume
  case brightness
  case progress
}

struct GestureLayer: View {
  @ObservedObject var model: VideoModel
  
  @State var area: CGSize
  @State var op: DragOperation = .none
  @State var prevPos: CGPoint = .zero
  
  @State private var brightnessOpacity: CGFloat = 0
  @State private var volumeOpacity: CGFloat = 0
  @State private var progressOpacity: CGFloat = 0
  
  var body: some View {
    ZStack {
      BrightnessIndicator(progress: $model.brightness)
        .frame(width: 200, height: 30)
        .opacity(brightnessOpacity)
      
      VolumeIndicator(progress: $model.volume)
        .frame(width: 200, height: 30)
        .opacity(volumeOpacity)
      
      ProgressIndicator(total: model.duration, current: $model.currentTime)
        .frame(width: 250, height: 30)
        .opacity(progressOpacity)
      
      makeGestureArea()
    }
  }
  
  func makeGestureArea() -> some View {
    Rectangle()
      .fill(Color.clear)
      .contentShape(Rectangle())
      .gesture(handleGesture())
  }
  
  func handleGesture() -> some Gesture {
    DragGesture()
      .onChanged {
        if (op == .none) {
          op = judgeDragGesture(from: $0.startLocation, to: $0.location)
          prevPos = $0.location
        }
        else {
          gestureOperation(from: prevPos, to: $0.location)
          prevPos = $0.location
        }
      }
      .onEnded { _ in
        resetIndicatorDisplay()
#if DEBUG
print("Gesture event ended.")
#endif
      }
  }
}

extension GestureLayer {
  func judgeDragGesture(from: CGPoint, to: CGPoint) -> DragOperation {
    let diffX = to.x - from.x
    let diffY = to.y - from.y
    
    if (abs(diffX) > abs(diffY)) {
      // horizontal movement
      return .progress
    }
    else {
      if (from.x <= area.width / 2) {
        return .brightness
      }
      else {
        return .volume
      }
    }
  }
  
  func gestureOperation(from: CGPoint, to: CGPoint) {
    // 3.0 - Scale the diff down
    let xDiff = (to.x - from.x) / 3.0
    // 3.0 - Scale the diff up
    // Scroll up to increase, so we use from.y - to.y
    let yDiff = (from.y - to.y) / (area.height - 88) * 3
#if DEBUG
print("xDiff: \(xDiff) yDiff: \(yDiff)")
#endif

    switch op {
    case .progress:
      withAnimation { progressOpacity = 1 }
      model.adjustProgress(xDiff)
    case .brightness:
      withAnimation { brightnessOpacity = 1 }
      model.adjustBrightness(yDiff)
    case .volume:
      withAnimation { volumeOpacity = 1 }
      model.adjustVolume(yDiff)
    default:
      break
    }
  }
  
  func resetIndicatorDisplay() {
    op = .none
    prevPos = .zero
    
    withAnimation {
      brightnessOpacity = 0
      volumeOpacity = 0
      progressOpacity = 0
    }
  }
}
