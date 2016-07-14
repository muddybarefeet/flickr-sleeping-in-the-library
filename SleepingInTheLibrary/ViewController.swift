//
//  ViewController.swift
//  SleepingInTheLibrary
//
//  Created by Jarrod Parkes on 11/3/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: - ViewController: UIViewController

class ViewController: UIViewController {

    // MARK: Outlets
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var grabImageButton: UIButton!
    
    // MARK: Actions
    
    @IBAction func grabNewImage(sender: AnyObject) {
        setUIEnabled(false)
        getImageFromFlickr()
    }
    
    // MARK: Configure UI
    
    private func setUIEnabled(enabled: Bool) {
        photoTitleLabel.enabled = enabled
        grabImageButton.enabled = enabled
        
        if enabled {
            grabImageButton.alpha = 1.0
        } else {
            grabImageButton.alpha = 0.5
        }
    }
    
    // MARK: Make Network Request
    
    private func getImageFromFlickr() {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.GalleryPhotosMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.GalleryID: Constants.FlickrParameterValues.GalleryID,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
//        create the request URL
        let urlStr = Constants.Flickr.APIBaseURL + escapedParameters(methodParameters)
        let url = NSURL(string: urlStr)!
        let request = NSURLRequest(URL: url)
        
//        run the request to get the data from the URL
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            
//            if here is no data then continue
            if error == nil {
//                if ther is a data item
                if let data = data {
//                    make a variable placeholder
                    let parsedData: AnyObject!
                    
//                    parse the json to readable format
                    do {
//                        serialization = convert to bytes and de serialization means the opposite all grouped under NSSerialization
                        parsedData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                    } catch {
//                    throw error if necessary
                        let alert = UIAlertController(title: "Alert", message: "Could not parse the data as JSON: '\(data)'", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "Working!!", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                        return
                    }
                    
//                  if there is a photos key in the response dictionary
                    if let photosDictionary = parsedData[Constants.FlickrResponseKeys.Photos] as? [String: AnyObject],
//                        if there is key on the photos dictionary that is "photo" (which is an array of dictionaries)
                        let photoArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                        
//                        make a random index and generate the dictionary at this index
                        let randomPhotoImdex = Int(arc4random_uniform(UInt32(photoArray.count)))
                        let photoDictionary = photoArray[randomPhotoImdex] as? [String: AnyObject]
                        
//                        
                        if let urlStr = photoDictionary![Constants.FlickrResponseKeys.MediumURL] as? String,
//                            get the url and title from the dictionary chosen at random
                            let photoTitle = photoDictionary![Constants.FlickrResponseKeys.Title] as? String {
                            let imageURL = NSURL(string: urlStr)
//                            if the url returned data then we turn it into NSData format and then send it to the main queue to update the views contents
                            if let imageData = NSData(contentsOfURL: imageURL!) {
                                performUIUpdatesOnMain() {
                                    self.photoImageView.image = UIImage(data: imageData)
                                    self.photoTitleLabel.text = photoTitle
                                    self.setUIEnabled(true)
                                }
                            }
                        }
                    }
                    
                }
            }
        }
        
        task.resume()
    }
    
    private func escapedParameters(parameters: [String: AnyObject]) -> String {
        
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            
            for (key, value) in parameters {
                let stringValue = "\(value)"
                let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
            }
            return "?\(keyValuePairs.joinWithSeparator("&"))"
        }
    
    }
}