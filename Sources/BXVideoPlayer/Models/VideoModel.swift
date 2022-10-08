//
//  File.swift
//  
//
//  Created by Mars on 2022/6/24.
//

import UIKit
import Combine
import Foundation
import MediaPlayer
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

extension CGFloat {
  func asPlayerString() -> String {
    let formatter = DateComponentsFormatter()
    
    formatter.allowedUnits = self >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
    formatter.unitsStyle = .positional
    formatter.zeroFormattingBehavior = .pad
    
    return formatter.string(from: self) ?? "00:00"
  }
}

/*
 The player could be in landscape mode when the device is in portrait mode or vice vesa.
 So we cannot rely on the device orientation.
 */
public enum PlayerOrientation {
  case portrait
  case landscape
}

public class VideoModel: ObservableObject {
  var player: AVPlayer = AVPlayer()
  
  @Published public var url: URL
  @Published public var title: String
  @Published public var duration: Double = 1.0
  @Published public var ratio: CGFloat = 16 / 9
  @Published public var isPlaying: Bool = false
  @Published public var isEditingCurrentTime = false
  
  @Published public var currentTime: CGFloat = 0
  @Published public var currentProgress: CGFloat = 0
  
  @Published public var volume: CGFloat = 0
  @Published public var brightness: CGFloat = UIScreen.br
  
  @Published public var isPipMode = false
  @Published public var isDisplayingControl = true
  
  @Published public var playerIsReady = false
  
  public var playerOrientation: PlayerOrientation = .portrait
  
  private var nowPlayingInfo = [String : Any]()
  private var timeObserver: Any?
  private var subscriptions: Set<AnyCancellable> = []
  
  deinit {
    if let timeObserver = timeObserver {
      player.removeTimeObserver(timeObserver)
    }
  }
  
  public init(url: URL, title: String) {
    self.url = url
    self.title = title
    
    volume = CGFloat(player.volume)
    player.automaticallyWaitsToMinimizeStalling = false
    
    Task {
      do {
        try await setCurrentItem(url: url)
        
        subscribePlayerState()
        subscribePlayingProgress()
        setupRemoteTransportControls()
        setupNowPlaying()
      }
      catch {
        if let e = error as? VideoError {
          switch e {
          case .emptyTrack:
            print("[BXVideoPlayer] Trying to play a video with empty track.")
          case .nonPlayable:
            print("[BXVideoPlayer] Trying to play a non-playable file.")
          }
        }
      }
    }
  }
  
  @MainActor
  public func switchUrl(url: URL) async throws {
    playerIsReady = false
    try await setCurrentItem(url: url)
  }
  
  @MainActor
  public func setCurrentItem(url: URL) async throws  {
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
    
    currentTime = 0
    currentProgress = 0
    
    let item = AVPlayerItem(asset: asset)
    player.replaceCurrentItem(with: item)
    
    playerIsReady = true
  }
  
  @MainActor
  public func seekTo(percentage: CGFloat) async {
    isEditingCurrentTime = true
    
    currentProgress = percentage
    currentTime = CGFloat(percentage) * duration
    
    Task {
      await player.seek(to: CMTimeMakeWithSeconds(CGFloat(percentage) * currentTime, preferredTimescale: 1000))
    }
    
    updateCommandCenterProgress()
  }
  
  public func play() {
    player.play()
    commandCenterPlay()
  }
  
  public func pause() {
    player.pause()
    commandCenterPause()
  }
  
  public func adjustVolume(_ diff: CGFloat) {
    volume += diff
    
    if volume < 0 { volume = 0 }
    else if volume > 1 { volume = 1 }
    
    player.volume = Float(volume)
  }
  
  public func adjustBrightness(_ diff: CGFloat) {
    brightness += diff
    
    if brightness < 0 { brightness = 0 }
    else if brightness > 1 { brightness = 1 }
    
    UIScreen.br = brightness
  }
  
  public func adjustProgress(_ diff: CGFloat) {
    currentTime += diff
    
    if currentTime < 0 {
      currentTime = 0
    }
    else if currentTime > duration {
      currentTime = duration
    }
    
    currentProgress = currentTime / duration
    
    Task {
      await player.seek(to: CMTimeMakeWithSeconds(currentTime, preferredTimescale: 1000))
    }
  }
}

extension VideoModel {
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
  
  private func subscribePlayerState() {
    player.publisher(for: \.timeControlStatus)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] status in
        switch status {
        case .playing:
          #if DEBUG
          print("[BXVideoPlayer] Play the video.")
          #endif
          self?.commandCenterPlay()
          self?.isPlaying = true
        case .waitingToPlayAtSpecifiedRate:
          #if DEBUG
          print("[BXVideoPlayer] The player is waiting for network conditions to improve.")
          #endif
          self?.isPlaying = false
        case .paused:
          #if DEBUG
          print("The player was paused.")
          #endif
          self?.commandCenterPause()
          self?.isPlaying = false
        @unknown default:
          print("[BXVideoPlayer] Unknown player state.")
          self?.isPlaying = false
          self?.playerIsReady = false
        }
      }
      .store(in: &subscriptions)
  }
  
  private func subscribePlayingProgress() {
    timeObserver = player.addPeriodicTimeObserver(
      forInterval: CMTime(value: 1, timescale: 600),
      queue: .main,
      using: { [weak self] time in
        guard let self = self else { return }
        
        // Cannot update the progress when seeking the video.
        if !self.isEditingCurrentTime {
          self.currentTime = time.seconds
          self.currentProgress = self.currentTime / self.duration
        }
      }
    ) // End timeObserver
  }
}

// Remote control
extension VideoModel {
  func setupRemoteTransportControls() {
    let commandCenter = MPRemoteCommandCenter.shared()
    
    commandCenter.playCommand.addTarget {
      [unowned self] event in
      if !self.isPlaying {
        self.play()
        return .success
      }
      return .commandFailed
    }
    
    commandCenter.pauseCommand.addTarget {
      [unowned self] event in
      if self.isPlaying {
        self.pause()
        return .success
      }
      return .commandFailed
    }
    
    commandCenter.changePlaybackPositionCommand.addTarget {
      [unowned self] event in
      let ev = event as! MPChangePlaybackPositionCommandEvent
      
      self.currentTime = CGFloat(ev.positionTime)
      self.currentProgress = self.currentTime / self.duration
      
      Task {
        await player.seek(to: CMTimeMakeWithSeconds(self.currentTime, preferredTimescale: 1000))
      }
      
      self.updateCommandCenterProgress()
      
      return .success
    }
    
    commandCenter.skipForwardCommand.addTarget {
      [weak self] event in
      #if DEBUG
      print("Forward 10 sec from command center.")
      #endif
      
      self?.adjustProgress(10)
      self?.updateCommandCenterProgress()
      
      return .success
    }
    
    commandCenter.skipBackwardCommand.addTarget {
      [weak self] event in
      #if DEBUG
      print("Backward 10 sec from command center.")
      #endif
      
      self?.adjustProgress(-10)
      self?.updateCommandCenterProgress()
      
      return .success
    }
  }
  
  // Define Now Playing Info
  func setupNowPlaying() {
    nowPlayingInfo[MPMediaItemPropertyTitle] = title
    
    if let image = UIImage(named: "lockscreen") {
      nowPlayingInfo[MPMediaItemPropertyArtwork] =
      MPMediaItemArtwork(boundsSize: image.size) {
        size in
        return image
      }
    }
    
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }
  
  func updateCommandCenterProgress() {
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }
  
  func commandCenterPause() {
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }

  func commandCenterPlay() {
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }
}
