//
//  File.swift
//  
//
//  Created by Mars on 2022/6/24.
//

import Foundation
import Combine
import AVFoundation

private let ERROR_VIDEO_LENGTH = 104.0
private let ERROR_VIDEO_RATIO: CGFloat = 1.78

enum VideoInfo {
  case duration(Double)
  case ratio(CGFloat)
}

enum VideoError: Error {
  case nonPlayable
  case emptyTrack
}

public class VideoModel: ObservableObject {
  var player: AVPlayer = AVPlayer()
  
  @Published public var url: URL
  @Published public var duration: Double = 0.0
  @Published public var ratio: CGFloat = 16 / 9
  @Published public var isPlaying: Bool = false
  
  private var subscriptions: Set<AnyCancellable> = []
  
  public init(url: URL) {
    self.url = url
    player.automaticallyWaitsToMinimizeStalling = false
    
    Task {
      try? await setCurrentItem(url: url)
    }
    
    
    player.publisher(for: \.timeControlStatus)
      .sink { [weak self] status in
        switch status {
        case .playing:
          self?.isPlaying = true
        default:
          self?.isPlaying = false
        }
      }
      .store(in: &subscriptions)
  
    player.addPeriodicTimeObserver(
      forInterval: CMTime(value: 1, timescale: 600),
      queue: .main,
      using: { [weak self] time in
        // TODO: Update playing progress
      }
    )
  }
  
  @MainActor
  public func setCurrentItem(url: URL) async throws {
    self.url = url
    let asset = AVAsset(url: url)
    
    try await withThrowingTaskGroup(of: VideoInfo.self) { group in
      // 1. Load duration
      group.addTask {
        try await self.loadDuration(asset: asset)
      }
      
      // 2. Load ratio
      group.addTask {
        try await self.loadRatio(asset: asset)
      }
      
      for try await result in group {
        switch result {
        case .ratio(let r):
          self.ratio = r
        case .duration(let d):
          self.duration = d
        }
      }
    }
    
    let item = AVPlayerItem(asset: asset)
    player.replaceCurrentItem(with: item)
  }
  
  public func play() {
    player.play()
  }
  
  public func pause() {
    player.pause()
  }
  
  private func loadDuration(asset: AVAsset) async throws -> VideoInfo {
    let (stat, d) = try await asset.load(.isPlayable, .duration)
    if stat {
      return VideoInfo.duration(d.seconds)
    }
    else {
      throw VideoError.nonPlayable
    }
  }

  private func loadRatio(asset: AVAsset) async throws -> VideoInfo {
    let tracks = try await asset.loadTracks(withMediaType: .video)
    
    if !tracks.isEmpty {
      let videoSize = try await tracks.first!.load(.naturalSize)
      let r = videoSize.width / videoSize.height
      
      return VideoInfo.ratio(r)
    }
    else {
      throw VideoError.emptyTrack
    }
  }
}
