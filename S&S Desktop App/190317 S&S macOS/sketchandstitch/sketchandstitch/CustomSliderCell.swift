//
//  CustomSliderCell.swift
//  sketchandstitch
//
//  Created by Kirill Timchenko on 23.12.18.
//  Copyright © 2018 Kirill Timchenko. All rights reserved.
//

import Foundation

class CustomSliderCell: NSSliderCell {
    
    var color = NSColor.systemBlue
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawBar(inside aRect: NSRect, flipped: Bool) {
        var rect = aRect
        rect.size.height = CGFloat(3)
        let barRadius = CGFloat(2.5)
        let value = CGFloat((self.doubleValue - self.minValue) / (self.maxValue - self.minValue))
        let finalWidth = CGFloat(value * (self.controlView!.frame.size.width - 8))
        var leftRect = rect
        leftRect.size.width = finalWidth
        let bg = NSBezierPath(roundedRect: rect, xRadius: barRadius, yRadius: barRadius)
        NSColor.darkGray.setFill()
        if(self.color != NSColor.controlDarkShadowColor){
            bg.fill()
        }
        let active = NSBezierPath(roundedRect: leftRect, xRadius: barRadius, yRadius: barRadius)
        color.setFill()
        if(self.color != NSColor.controlDarkShadowColor){
            active.fill()
        }
        
    }
    
    func changeColor(color: Int){
        switch color{
        case 1:
            self.color = NSColor.systemGreen
            break
        case 2:
            self.color = NSColor.systemRed
            break
        case 3:
            self.color = NSColor.systemGray
            break
        case 4:
            self.color = NSColor.controlDarkShadowColor
            break
        default:
            self.color = NSColor.systemBlue
            break
        }
        
    }
    
}
