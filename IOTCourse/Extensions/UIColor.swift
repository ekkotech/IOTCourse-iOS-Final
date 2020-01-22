//
//  UIColor.swift
//  IOTCourse
//
//  Created by Andrew Coad on 20/08/2019.
//  Copyright © 2019 Andrew Coad. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    func withRedComponent(_ red: CGFloat) -> UIColor {
        var thisRed: CGFloat = 0.0
        var thisGreen: CGFloat = 0.0
        var thisBlue: CGFloat = 0.0
        var thisAlpha: CGFloat = 0.0
        
        self.getRed(&thisRed, green: &thisGreen, blue: &thisBlue, alpha: &thisAlpha)
        return UIColor(red: red, green: thisGreen, blue: thisBlue, alpha: thisAlpha)
    }
}

extension UIColor {
    func withGreenComponent(_ green: CGFloat) -> UIColor {
        var thisRed: CGFloat = 0.0
        var thisGreen: CGFloat = 0.0
        var thisBlue: CGFloat = 0.0
        var thisAlpha: CGFloat = 0.0
        
        self.getRed(&thisRed, green: &thisGreen, blue: &thisBlue, alpha: &thisAlpha)
        return UIColor(red: thisRed, green: green, blue: thisBlue, alpha: thisAlpha)
    }
}

extension UIColor {
    func withBlueComponent(_ blue: CGFloat) -> UIColor {
        var thisRed: CGFloat = 0.0
        var thisGreen: CGFloat = 0.0
        var thisBlue: CGFloat = 0.0
        var thisAlpha: CGFloat = 0.0
        
        self.getRed(&thisRed, green: &thisGreen, blue: &thisBlue, alpha: &thisAlpha)
        return UIColor(red: thisRed, green: thisGreen, blue: blue, alpha: thisAlpha)
    }
}

extension UIColor {
    func withHueComponent(_ hue: CGFloat) -> UIColor {
        var thisHue: CGFloat = 0.0
        var thisSaturation: CGFloat = 0.0
        var thisBrightness: CGFloat = 0.0
        var thisAlpha: CGFloat = 0.0
        
        self.getHue(&thisHue, saturation: &thisSaturation, brightness: &thisBrightness, alpha: &thisAlpha)
        return UIColor(hue: hue, saturation: thisSaturation, brightness: thisBrightness, alpha: thisAlpha)
    }
}

extension UIColor {
    func withSaturationComponent(_ saturation: CGFloat) -> UIColor {
        var thisHue: CGFloat = 0.0
        var thisSaturation: CGFloat = 0.0
        var thisBrightness: CGFloat = 0.0
        var thisAlpha: CGFloat = 0.0
        
        self.getHue(&thisHue, saturation: &thisSaturation, brightness: &thisBrightness, alpha: &thisAlpha)
        return UIColor(hue: thisHue, saturation: saturation, brightness: thisBrightness, alpha: thisAlpha)
    }
}

extension UIColor {
    func withBrightnessComponent(_ brightness: CGFloat) -> UIColor {
        var thisHue: CGFloat = 0.0
        var thisSaturation: CGFloat = 0.0
        var thisBrightness: CGFloat = 0.0
        var thisAlpha: CGFloat = 0.0
        
        self.getHue(&thisHue, saturation: &thisSaturation, brightness: &thisBrightness, alpha: &thisAlpha)
        return UIColor(hue: thisHue,
                       saturation: thisSaturation,
                       // Bug: creating an HSB colour with brightness == 0.0, also sets hue & saturation to 0.0
            brightness: brightness == 0.0 ? 0.001 : brightness,
            alpha: thisAlpha)
    }
}

extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var thisRed: CGFloat = 0.0
        var thisGreen: CGFloat = 0.0
        var thisBlue: CGFloat = 0.0
        var thisAlpha: CGFloat = 0.0
        
        self.getRed(&thisRed, green: &thisGreen, blue: &thisBlue, alpha: &thisAlpha)
        return (thisRed, thisGreen, thisBlue, thisAlpha)
    }
}

extension UIColor {
    var hsba: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        var thisHue: CGFloat = 0.0
        var thisSaturation: CGFloat = 0.0
        var thisBrightness: CGFloat = 0.0
        var thisAlpha: CGFloat = 0.0
        
        self.getHue(&thisHue, saturation: &thisSaturation, brightness: &thisBrightness, alpha: &thisAlpha)
        return (thisHue, thisSaturation, thisBrightness, thisAlpha)
    }
}

extension UIColor {
    var lightness: CGFloat {
        var thisRed: CGFloat = 0.0
        var thisGreen: CGFloat = 0.0
        var thisBlue: CGFloat = 0.0
        var thisAlpha: CGFloat = 0.0
        
        self.getRed(&thisRed, green: &thisGreen, blue: &thisBlue, alpha: &thisAlpha)
        return (thisRed + thisGreen + thisBlue) / 3.0

    }
}
