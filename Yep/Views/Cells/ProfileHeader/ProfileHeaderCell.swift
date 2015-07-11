//
//  ProfileHeaderCell.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import CoreLocation
import FXBlurView
import Proposer

class ProfileHeaderCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarBlurImageView: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!

    struct Listener {
        static let Avatar = "ProfileHeaderCell.Avatar"
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)

        YepUserDefaults.avatarURLString.removeListenerWithName(Listener.Avatar)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    var blurredAvatarImage: UIImage? {
        willSet {
            avatarBlurImageView.image = newValue
        }
    }

    func configureWithDiscoveredUser(discoveredUser: DiscoveredUser) {
        updateAvatarWithAvatarURLString(discoveredUser.avatarURLString)

        let location = CLLocation(latitude: discoveredUser.latitude, longitude: discoveredUser.longitude)

        CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in

            if (error != nil) {
                println("reverse geodcode fail: \(error.localizedDescription)")
            }

            if let placemarks = placemarks as? [CLPlacemark] {
                if let firstPlacemark = placemarks.first {
                    self.locationLabel.text = firstPlacemark.locality
                }
            }
        })
    }

    func configureWithUser(user: User) {

        updateAvatarWithAvatarURLString(user.avatarURLString)

        if user.friendState == UserFriendState.Me.rawValue {
            YepUserDefaults.avatarURLString.bindListener(Listener.Avatar) { [weak self] avatarURLString in
                if let avatarURLString = avatarURLString {
                    self?.blurredAvatarImage = nil // need reblur
                    self?.updateAvatarWithAvatarURLString(avatarURLString)
                }
            }

            proposeToAccess(.Location(.WhenInUse), agreed: {

                YepLocationService.turnOn()

            }, rejected: {
                print("Yep can NOT get Location. :[\n")
            })

            NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateAddress", name: "YepLocationUpdated", object: nil)
        }

        // TODO: User Location
    }


    func blurImage(image: UIImage, completion: UIImage -> Void) {

        if let blurredAvatarImage = blurredAvatarImage {
            completion(blurredAvatarImage)

        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let blurredImage = image.blurredImageWithRadius(20, iterations: 20, tintColor: UIColor.blackColor())
                completion(blurredImage)
            }
        }
    }

    func updateAvatarWithAvatarURLString(avatarURLString: String) {

        if avatarImageView.image == nil {
            avatarImageView.alpha = 0
            avatarBlurImageView.alpha = 0
        }

        AvatarCache.sharedInstance.avatarFromURL(NSURL(string: avatarURLString)!) { [weak self] image in

            self?.blurImage(image) { blurredImage in
                dispatch_async(dispatch_get_main_queue()) {
                    self?.blurredAvatarImage = blurredImage
                }
            }

            dispatch_async(dispatch_get_main_queue()) {
                self?.avatarImageView.image = image

                UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut, animations: { () -> Void in
                    self?.avatarImageView.alpha = 1
                }, completion: { (finished) -> Void in
                })
            }
        }
    }
    
    func updateAddress() {
        
//        println("Location YepLocationUpdated")
        
        self.locationLabel.text = YepLocationService.sharedManager.address
    }
    
}
