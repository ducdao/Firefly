//
//  ViewController.swift
//  Firefly
//
//  Created by Matt Hanna on 11/11/17.
//  Copyright © 2017 SLOFirefly. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    let deviceId = UIDevice.current.identifierForVendor!.uuidString
    var lightOn: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let count = 100
        
        postId()
        
        for index in 0...count {
            setLightFlag(index)
            toggleTorch(lightOn)
            sleep(1)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func lightButton(_ sender: Any) {
    }
    
    func setLightFlag(_ count: Int) {
        if (!lightOn) {
            lightOn = true
        }
            // Torch is on, turn off
        else {
            lightOn = false
        }
        
        print("TOGGLING FLASHLIGHT...")
        print(count)
    }
    
    func toggleTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        if (device.hasTorch) {
            do {
                try device.lockForConfiguration()
                
                if (on) {
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
    
    func postId() {
        let url = URL(string: "https://test.christianjohansen.com/register")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        // Construct POST JSON body
        let postString = "{\"id\": \"" + deviceId + "\"}"
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {                                                 // check for fundamental networking error
            print("error=\(String(describing: error))")
        return
        }
    
        if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
        print("statusCode should be 200, but is \(httpStatus.statusCode)")
            print("response = \(String(describing: response))")
        }
    
        let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
        }
        task.resume()
    }
    
    // Function that gets JSON from some API
    func getJSON(_ apiString: String) {
        var jsonData : JSON?
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let request = URLRequest(url: URL(string: apiString)!)
        let task: URLSessionDataTask = session.dataTask(with: request) {
            (receivedData, response, error) -> Void in
            if let data = receivedData {
                // No do-catch since no errors thrown
                jsonData = JSON(data)
                
                // TODO: Make send setThreadArray as a parameter
                print("Initializing array of threads")
                self.setThreadList(jsonData!)
            }
        }
        
        task.resume()
    }
}
