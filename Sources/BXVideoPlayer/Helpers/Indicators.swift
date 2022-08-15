//
//  SwiftUIView.swift
//  
//
//  Created by Mars on 2022/8/12.
//

import SwiftUI

struct Indicators: View {
  @Binding var icon: String
  @Binding var progress: CGFloat
  
  var body: some View {
    HStack {
      Image(systemName: icon)
        .font(.headline)
        .foregroundColor(Color.white)
        .frame(width: 30, height: 30)
      ProgressView(value: progress)
    }
    .padding(10)
    .background(Color.black.opacity(0.3))
    .cornerRadius(9)
  }
}

struct BrightnessIndicator: View {
  @State private var icon: String = "sun.min.fill"
  @Binding var progress: CGFloat
  
  var body: some View {
    Indicators(icon: $icon, progress: $progress)
      .onAppear() {
        updateIcon(progress)
      }
      .onChange(of: progress) {
        updateIcon($0)
      }
  }
  
  func updateIcon(_ value: CGFloat) {
    if value >= 0.5 {
      icon = "sun.max.fill"
    }
    else {
      icon = "sun.min.fill"
    }
  }
}

struct VolumeIndicator: View {
  @State private var icon: String = "speaker.wave.1.fill"
  @Binding var progress: CGFloat
  
  var body: some View {
    Indicators(icon: $icon, progress: $progress)
      .onAppear() {
        updateIcon(progress)
      }
      .onChange(of: progress) {
        updateIcon($0)
      }
  }
  
  func updateIcon(_ value: CGFloat) {
    if value <= 0.3 {
      icon = "speaker.wave.1.fill"
    }
    else if value <= 0.6 {
      icon = "speaker.wave.2.fill"
    }
    else {
      icon = "speaker.wave.3.fill"
    }
  }
}

struct ProgressIndicator: View {
  let total: CGFloat
  @Binding var current: CGFloat
  
  var body: some View {
    HStack {
      Group {
        Text(current.asPlayerString())
        Text("/")
        Text(total.asPlayerString())
      }
      .font(.system(size: 14, design: .monospaced))
      .foregroundColor(Color(UIColor.white))
    }
    .padding(10)
    .background(Color.black.opacity(0.3))
    .cornerRadius(9)
  }
}
