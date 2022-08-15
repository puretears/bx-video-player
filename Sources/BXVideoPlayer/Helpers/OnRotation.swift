//
//  SwiftUIView.swift
//  
//
//  Created by Mars on 2022/6/24.
//

import SwiftUI

struct OnRotationViewModifier: ViewModifier {
  let action: (UIDeviceOrientation) -> Void
  
  func body(content: Content) -> some View {
    content
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
        action(UIDevice.current.orientation)
      }
  }
}

extension View {
  func onRotate(_ action: @escaping (UIDeviceOrientation) -> Void) -> some View {
    modifier(OnRotationViewModifier(action: action))
  }
}
