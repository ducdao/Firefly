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
    var interval: UInt32 = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        seatNumber.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ seatNumber: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func lightButton(_ sender: Any) {
        let count = 101
        
        view.endEditing(true)
        
        postIdJSON()
        getTimingJSON(backendURL + "timing?id=" + deviceId)
        
        for index in 0...count {
            setLightFlag()
            toggleTorch()
            // Sleep for .25 seconds
            usleep(self.interval * 1000)
            
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
        let postString = "{\"id\": \"" + self.deviceId + "\",\n" +
            "\"seat\":" + seat + "}"
        request.httpBody = postString.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
        // Check for fundamental networking error
        guard let data = data, error == nil else {
            print("error=\(String(describing: error))")
        return
        }
            
        // Check for HTTP errors
        if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
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
    func getTimingJSON(_ apiString: String) {
        var jsonData: JSON?
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let request = URLRequest(url: URL(string: apiString)!)
        let task: URLSessionDataTask = session.dataTask(with: request) {
            (receivedData, response, error) -> Void in
            if let data = receivedData {
                // No do-catch since no errors thrown
                jsonData = JSON(data)
                
                print("Initializing interval...")
                self.interval = useconds_t(jsonData!["interval"].int!)
                print("Timing: " + "\(self.interval)")
            }
        }
        
        task.resume()
    }
}
