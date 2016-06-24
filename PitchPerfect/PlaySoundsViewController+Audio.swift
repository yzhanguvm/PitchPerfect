//
//  PlaySoundsViewController+Audio.swift
//  PitchPerfect
//
//  Created by Zhang, Angie on 6/23/16.
//  Copyright © 2016 Zhang, Angie. All rights reserved.
//

import UIKit
import AVFoundation

extension PlaySoundsViewController: AVAudioPlayerDelegate {
    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let RecordingDisabledTitle = "Recording Disabled"
        static let RecordingDisabledMessage = "You've disabled your app from recording your microphone. Check Settings."
        static let RecordingFailedTitle = "Recording Failed"
        static let RecordingFailedMessage = "Something went wrong with your recording."
        static let AudioRecorderError = "Audio Recorder Error"
        static let AudioSessionError = "Audio Session Error"
        static let AudioRecordingError = "Audio Recording Error"
        static let AudioFileError = "Audio File Error"
        static let AudioEngineError = "Audio Engine Error"
    }
    
    //raw values corresponding to sender tag
    enum PlayingState {case Playing, NotPlaying}
    
    // MARK: Audio Functions
    
    func setupAudio() {
        //initialize (recording) audio file
        do {
            try audioFile = AVAudioFile(forReading: recordedAudioURL as URL)
        } catch {
            showAlert(title: Alerts.AudioFileError, message: String(error))
        }
        print("Audio has been set up")
    }
    
    func playSound(rate: Float? = nil, pitch: Float? = nil, echo: Bool? = false, reverb: Bool? = false) {
        // Initialize audio engine components
        audioEngine = AVAudioEngine()
        
        // node for playing audio
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)
        
        // node for adjusting rate/pitch
        let changedRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            changedRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            changedRatePitchNode.rate = rate
        }
        audioEngine.attach(changedRatePitchNode)
        
        // node for echo
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(echoNode)
        
        // node for reverb
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attach(reverbNode)
        
        // connect nodes
        if echo == true && reverb == true {
            connectAudioNodes(nodes: audioPlayerNode, changedRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
        } else if echo == true {
            connectAudioNodes(nodes: audioPlayerNode, changedRatePitchNode, echoNode, audioEngine.outputNode)
        } else if reverb == true {
            connectAudioNodes(nodes: audioPlayerNode, changedRatePitchNode, reverbNode, audioEngine.outputNode)
        } else {
            connectAudioNodes(nodes: audioPlayerNode, changedRatePitchNode, audioEngine.outputNode)
        }
        
        // schedule to play and start the engine
        audioPlayerNode.stop()
        audioPlayerNode.scheduleFile(audioFile, at: nil) {
            var delayInSeconds: Double = 0
            if let lastRenderTime = self.audioPlayerNode.lastRenderTime,
                let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime) {
                if let rate = rate {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
                } else {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
                }
            }
            
            // schedule a stop timer for when audio finishes playing
            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(PlaySoundsViewController.stopAudio), userInfo: nil, repeats: false)
            RunLoop.main().add(self.stopTimer!, forMode: RunLoopMode.defaultRunLoopMode)
        }
        
        do {
            try audioEngine.start()
        } catch {
            showAlert(title: Alerts.AudioEngineError, message: String(error))
            return
        }
        
        // play the recording!
        audioPlayerNode.play()
    }
    
    // MARK: Connect List of Audio Nodes
        
    func connectAudioNodes(nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile.processingFormat)
        }
    }
        
    func stopAudio() {
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        
        configureUI(playState: .NotPlaying)
        
        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }
        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
        
    // MARK: UI functions
        
    func configureUI(playState: PlayingState) {
        switch(playState) {
        case .Playing:
            setPlayButtonEnabled(enabled: false)
            stopButton.isEnabled = true
        case .NotPlaying:
            setPlayButtonEnabled(enabled: true)
            stopButton.isEnabled = false
        }
    }
    
    func setPlayButtonEnabled(enabled: Bool) {
        snailButton.isEnabled = enabled
        rabbitButton.isEnabled = enabled
        chipmunkButton.isEnabled = enabled
        darthVaderButton.isEnabled = enabled
        echoButton.isEnabled = enabled
        reverbButton.isEnabled = enabled
    }
        
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}
