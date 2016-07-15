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
            
            func displayError (error: String) {
                print(error)
                print("URL at time of error: \(url)")
                performUIUpdatesOnMain{
                    self.setUIEnabled(true)
                }
            }
            
//            was there an error?
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
//            was any data returned?
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
//          make a variable placeholder
            let parsedData: AnyObject!
                    
//          parse the json to readable format
            do {
//              serialization = convert to bytes and de serialization means the opposite all grouped under NSSerialization
                parsedData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
//              throw error if necessary
                displayError("Could not parse the data as JSON: \(data)")
                return
            }
            
//            are there photos and photo keys in our result?
            guard let photosDictionary = parsedData[Constants.FlickrResponseKeys.Photos] as? [String: AnyObject],
                let photoArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' and '\(Constants.FlickrResponseKeys.Photo)' in '\(parsedData)'")
                    return
            }
                        
//          select random photo
            let randomPhotoImdex = Int(arc4random_uniform(UInt32(photoArray.count)))
            let photoDictionary = photoArray[randomPhotoImdex] as [String: AnyObject]
            let photoTitle = photoDictionary[Constants.FlickrResponseKeys.Title] as? String
            
//           does our photo have a key for 'url_m'?
            guard let imageURLString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else {
                displayError("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)' in '\(photoDictionary)'")
                return
            }
            
//            if an image exists at the URL then set the image and title
            let imageURL = NSURL(string: imageURLString)
//          if the url returned data then we turn it into NSData format and then send it to the main queue to update the views contents
            if let imageData = NSData(contentsOfURL: imageURL!) {
                performUIUpdatesOnMain() {
                    self.photoImageView.image = UIImage(data: imageData)
                    self.photoTitleLabel.text = photoTitle
                    self.setUIEnabled(true)
                }
            } else {
                displayError("Image does not exist at '\(imageURL)'")
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