//
//  SwiftUIView.swift
//  
//
//  Created by Mars on 2022/7/15.
//

import SwiftUI

struct GestureLayer: View {
  var body: some View {
    ZStack {
      makeGestureArea()
        .border(Color.brown, width: 6)
    }
    .padding(.top, 44)
    .padding(.bottom, 44)
    
  }
  
  func makeGestureArea() -> some View {
    Rectangle()
      .fill(Color.clear)
      .contentShape(Rectangle())
      .gesture(handleGesture())
  }
  
  func handleGesture() -> some Gesture {
    DragGesture()
      .onChanged { _ in
        print("onChanged")
      }
      .onEnded { _ in
        print("ended")
      }
  }
}
