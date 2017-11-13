//
//  ViewController.swift
//  Firefly
//
//  Created by Duc Dao on 11/11/17.
//  Copyright © 2017 SLOFirefly. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UITextFieldDelegate {
    let deviceId: String = UIDevice.current.identifierForVendor!.uuidString
    @IBOutlet weak var seatNumber: UITextField!
    let backendURL = "https://test.christianjohansen.com/"
    var lightOn: Bool = false
    
    class Timing: NSObject {
        var startTime: Double = 0
        var onDuration: UInt32 = 0
        var offDuration: UInt32 = 0
        var endTime: Double = 0
    }
    
    // All the timings we need for the phone
    var times = Timing()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        seatNumber.keyboardType = UIKeyboardType.numberPad
        seatNumber.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Dismiss keyboard when selecting 'Return'
    func textFieldShouldReturn(_ seatNumber: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func lightButton(_ sender: Any) {
        // Dismiss keyboard
        view.endEditing(true)
        
        postIdJSON()
        
        self.getTimingJSON {(json) in
            self.times.startTime = json["startTime"].double!
            print(self.times.startTime)
            self.times.onDuration = useconds_t(json["onDuration"].int!)
            print(self.times.onDuration)
            self.times.offDuration = useconds_t(json["offDuration"].int!)
            print(self.times.offDuration)
            self.times.endTime = json["endTime"].double!
            print(self.times.endTime)
        }
        
        // Wait for POST call to set global variables
        sleep(1)
        
        print("Start time: " + "\(self.times.startTime)")
        print("On duration: " + "\(self.times.onDuration)")
        print("Off duration: " + "\(self.times.offDuration)")
        print("End time: " + "\(self.times.endTime)")
        
        // Get how long the phone is gonna wait until things get lit
        let waitTime = self.times.startTime - NSDate().timeIntervalSince1970
        print("Current time: " + "\(NSDate().timeIntervalSince1970)")
        
        print("Wait time: " + "\(waitTime)")
        
        Timer.scheduledTimer(timeInterval: waitTime, target: self,
                             selector: #selector(startLighting),
                             userInfo: nil, repeats: false)
    }
    
    @IBAction func masterButton(_ sender: Any) {
        lightButton(self)
    }
    
    @objc func startLighting() {
        var stateFlag: Bool = true
        
        for index in 0...31 {
            setLightFlag()
            toggleTorch()
            // Sleep in microseconds, alternate between on and off duration
            if (stateFlag) {
                usleep(self.times.onDuration * 1000)
                stateFlag = false
            }
            else {
                usleep(self.times.offDuration * 1000)
                stateFlag = true
            }
            
            print("TOGGLING FLASHLIGHT...")
            print(index)
        }
    }
    
    func setLightFlag() {
        // Tourch is off, turn on
        if (!self.lightOn) {
            self.lightOn = true
        }
        // Torch is on, turn off
        else {
            self.lightOn = false
        }
    }
    
    func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        if (device.hasTorch) {
            do {
                try device.lockForConfiguration()
                
                if (self.lightOn) {
                    device.torchMode = .on
                }
                else {
                    device.torchMode = .off
                }
                
                device.unlockForConfiguration()
            }
            catch {
                print("Torch could not be used")
            }
        }
        else {
            print("Torch is not available")
        }
    }
    
    func postIdJSON() {
        let seat: String = seatNumber.text!
        let url = URL(string: (backendURL + "register"))!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        // Construct POST JSON body
        let postString = "{\"id\": \"" + self.deviceId + "\",\n" + "\"seat\":" + seat + "}"
        request.httpBody = postString.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
        // Check for fundamental networking error
        guard let data = data, error == nil else {
            print("error=\(String(describing: error))")
        return
        }
            
        // Check for HTTP errors
        if let httpStatus =
            response as? HTTPURLResponse, httpStatus.statusCode != 200 {
        print("statusCode should be 200, but is \(httpStatus.statusCode)")
            print("response = \(String(describing: response))")
        }
    
        let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
        }
        task.resume()
        
        print("Seat Number: " + "\(seat)")
    }
    
    // Function that gets JSON from some API
    func getTimingJSON(completion:@escaping (_ json: JSON) -> Void) {
        var jsonData: JSON?
        let apiString = self.backendURL + "timing?id=" + self.deviceId
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let request = URLRequest(url: URL(string: apiString)!)
        let task: URLSessionDataTask = session.dataTask(with: request) {
            (receivedData, response, error) -> Void in
            if let data = receivedData {
                // No do-catch since no errors thrown
                jsonData = JSON(data)
                
                print("Initializing interval...")
                
                // Callback to see global variables
                completion(jsonData!)
            }
        }
        
        task.resume()
    }
}
