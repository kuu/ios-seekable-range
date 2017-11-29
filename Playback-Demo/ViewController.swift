//
//  ViewController.swift
//  Playback-Demo
//
//  Created by Kuu Miyazaki on 11/29/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var ooyalaPlayerViewController: OOOoyalaPlayerViewController!
    var shouldRestore = false
    let TIMESCALE:Int32 = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let player = OOOoyalaPlayer(pcode: "ZxNGgyOhy-q1LotjzCC58NUpXlWV", domain: OOPlayerDomain(string: "https://tv-demo.link"))
        self.ooyalaPlayerViewController = OOOoyalaPlayerViewController(player: player)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.notificationHandler(_:)), name: nil, object: self.ooyalaPlayerViewController.player)
        
        self.addChildViewController(self.ooyalaPlayerViewController)
        self.view.addSubview(self.ooyalaPlayerViewController.view)
        self.ooyalaPlayerViewController.view.frame = self.view.bounds
        self.ooyalaPlayerViewController.player.setEmbedCode("ljN2w5ZDE6K2g0QlFEfIJsd-pc0TczyP")
        self.ooyalaPlayerViewController.player.play()
            }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func notificationHandler(_ notification: Notification) {
        if notification.name != NSNotification.Name.OOOoyalaPlayerStateChanged {
            return
        }
        guard let player = self.ooyalaPlayerViewController.player else {
            return
        }
        // debugPrint("@@@ Notification Received: \(notification.name). state: \(OOOoyalaPlayer.playerState(toString: player.state()))")
        if (player.state() != OOOoyalaPlayerStatePlaying || !self.shouldRestore) {
            return
        }
        self.shouldRestore = false
        let pos = restorePlaybackPosition()
        if (pos > 0) {
            let newTime = getTimeAtProgress(pos)
            self.ooyalaPlayerViewController.player.seek(Float64(newTime.seconds))
        }
    }
    
    func onEnterBackground() {
        savePlaybackPosition()
        self.shouldRestore = true
    }
    
    func savePlaybackPosition() {
        let userDefaults = UserDefaults.standard
        guard let player = self.ooyalaPlayerViewController.player else {
            return
        }
        userDefaults.set(player.playheadTime() / player.duration(), forKey:"playheadTime")
        userDefaults.synchronize()
    }
    
    func restorePlaybackPosition() -> Float64 {
        let userDefaults = UserDefaults.standard
        guard let playheadTime = userDefaults.object(forKey: "playheadTime") else {
            return 0
        }
        return playheadTime as! Float64
    }
    
    func getTimeAtProgress(_ progress: Float64) -> CMTime {
        var newTime = CMTime(seconds: 0.0, preferredTimescale: TIMESCALE)
        
        var clampedProgress = progress
        if clampedProgress < 0.0 {
            debugPrint("bad progress value \(progress)")
            clampedProgress = 0.0
        }
        else if clampedProgress > 1.0 {
            debugPrint("bad progress value \(progress)")
            clampedProgress = 1.0
        }
        
        if let mediaPlayer = self.ooyalaPlayerViewController.player {
            let seekableRange = mediaPlayer.seekableTimeRange()
            if CMTIMERANGE_IS_VALID(seekableRange) {
                let start = CMTimeGetSeconds(seekableRange.start)
                let duration = CMTimeGetSeconds(seekableRange.duration)
                debugPrint("@@@ seekableRange: start=\(start), duration=\(duration), curr=\(duration * clampedProgress)")
                newTime = CMTime(seconds: (duration * clampedProgress) + start, preferredTimescale: TIMESCALE)
            } else {
                debugPrint("@@@ CMTIMERANGE_IS_VALID(seekableRange) returns false")
            }
        }
        
        return newTime
    }
}

