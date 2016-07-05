//
//  NSBundleExtensions.swift
//  BugShaker
//
//  Created by Jake Payton on 6/24/16.
//  Copyright © 2016 Dan Trenz. All rights reserved.
//

import Foundation

extension NSBundle {

    var releaseVersion: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }

    var buildVersion: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }

    var appVersion: String? {
        guard let releaseVersion = self.releaseVersion else {
            return nil
        }
        guard let buildVersion = self.buildVersion else {
            return nil
        }
        return "\(releaseVersion).\(buildVersion)"
    }

}
