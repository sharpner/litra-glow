import Foundation
import SwiftUI

class WebcamDetector: ObservableObject {
    @Published var isWebcamActive = false
    @Published var isAutoModeEnabled = false
    private var logTask: Process?
    private var logPipe: Pipe?
    private var litraController: LitraController?
    private let processingQueue = DispatchQueue(label: "webcam.log.processing", qos: .utility)
    init(litraController: LitraController) {
        self.litraController = litraController
        isAutoModeEnabled = UserDefaults.standard.bool(forKey: "isAutoModeEnabled")
        print("WebcamDetector initialized, AutoMode: \(isAutoModeEnabled)")
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    func toggleAutoMode() {
        isAutoModeEnabled = !isAutoModeEnabled
        print("AutoMode toggled to: \(isAutoModeEnabled)")
        UserDefaults.standard.set(isAutoModeEnabled, forKey: "isAutoModeEnabled")
        if isAutoModeEnabled && isWebcamActive {
            print("Auto mode enabled and webcam is active: turning light ON")
            litraController?.turnOn()
        }
    }

    func disableAutoMode() {
        if isAutoModeEnabled {
            isAutoModeEnabled = false
            print("AutoMode manually disabled")
            UserDefaults.standard.set(false, forKey: "isAutoModeEnabled")
        }
    }

    func startMonitoring() {
        print("Starting webcam log monitoring")
        if logTask != nil {
            stopMonitoring() // Stoppe vorherige Überwachung, falls vorhanden
        }
        logTask = Process()
        logPipe = Pipe()
        guard let logTask = logTask, let logPipe = logPipe else { return }
        logTask.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        logTask.arguments = ["stream", "--predicate", "subsystem contains 'camera' OR subsystem contains 'AVCapture' OR subsystem contains 'UVC'", "--style", "compact"]
        logTask.standardOutput = logPipe
        let fileHandle = logPipe.fileHandleForReading
        fileHandle.readabilityHandler = { [weak self] handle in
            guard let self = self else { return }
            let data = handle.availableData
            if !data.isEmpty {
                self.processingQueue.async {
                    self.processLogData(data)
                }
            }
        }
        do {
            try logTask.run()
            print("Log monitoring started successfully")
        } catch {
            print("Failed to start log monitoring: \(error)")
        }
    }

    func stopMonitoring() {
        print("Stopping webcam monitoring")
        if let fileHandle = logPipe?.fileHandleForReading {
            fileHandle.readabilityHandler = nil
        }
        logTask?.terminate()
        logTask = nil
        logPipe = nil
    }

    private func processLogData(_ data: Data) {
        guard let logString = String(data: data, encoding: .utf8) else { return }
        if logString.contains("manual framing") ||
            logString.contains("center stage")
        {
            return
        }
        if logString.contains("-[AVCaptureSession_Tundra startRunning]") ||
            (logString.contains("-[AVCaptureSession_Tundra _setRunning:") &&
                logString.contains("running -> 1"))
        {
            print("Camera activation detected: \(logString)")
            DispatchQueue.main.async {
                self.setWebcamActive(true)
            }
            return
        }
        if logString.contains("-[AVCaptureSession_Tundra stopRunning]") ||
            (logString.contains("-[AVCaptureSession_Tundra _setRunning:") &&
                logString.contains("running -> 0"))
        {
            print("Camera deactivation detected: \(logString)")
            DispatchQueue.main.async {
                self.setWebcamActive(false)
            }
            return
        }
        if logString.contains("changing sUserPreferredCamera from") ||
            logString.contains("changing sSystemPreferredCamera from")
        {
            if !logString.contains("-[AVCaptureSession_Tundra stopRunning]") {
                print("Camera switching detected, session remains active")
                DispatchQueue.main.async {
                    self.setWebcamActive(true)
                }
                return
            }
        }
        if logString.contains("AVCaptureSession") && !logString.contains("stopRunning") {
            if logString.contains("postNotificationNamed: AVCaptureSessionDidStartRunningNotification") {
                print("Session started running detected via notification")
                DispatchQueue.main.async {
                    self.setWebcamActive(true)
                }
                return
            }
        }
    }

    private func setWebcamActive(_ active: Bool) {
        if isWebcamActive != active {
            isWebcamActive = active
            print("Webcam status changed: \(active ? "active" : "inactive")")
            if isAutoModeEnabled {
                if active {
                    print("Auto mode ON and webcam active: turning light ON")
                    litraController?.turnOn()
                } else {
                    print("Auto mode ON and webcam inactive: turning light OFF")
                    litraController?.turnOff()
                }
            } else {
                print("Auto mode OFF: not controlling light")
            }
        }
    }
}
