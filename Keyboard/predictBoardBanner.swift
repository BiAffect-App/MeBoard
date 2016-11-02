//
//  predictboardBanner.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 10/5/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

/*
 This is the demo banner. The banner is needed so that the top row popups have somewhere to go. Might as well fill it
 with something (or leave it blank if you like.)
 */

class predictboardBanner: ExtraView {
    
    //var predictSwitch: UISwitch = UISwitch()
    //var predictLabel: UILabel = UILabel()
    let numButtons = UserDefaults.standard.integer(forKey: "numberACSbuttons")
    let numRows = UserDefaults.standard.integer(forKey: "numberACSrows")
    var buttons = [UIButton]()
    let recommendationEngine = WordList()
    var outFunc: (String) -> ()
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool, outputFunc: @escaping (String)->()) {
        self.outFunc = outputFunc //needs to be declared before the super.init
        
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
        
        print(UserDefaults.standard.integer(forKey: "numberACSrows"))
        for _ in 0..<self.numButtons {
            let button: UIButton = UIButton()
            buttons.append(button)
            self.addSubview(button)
            button.backgroundColor = UIColor.lightGray
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.clear.cgColor
            button.titleLabel?.font = UIFont(name: "Helvetica",
                                 size: 22)
            button.addTarget(self, action: #selector(runOutputFunc), for: .touchUpInside)
        }
        updateButtons(prevWord: "")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        fatalError("init(globalColors:darkMode:solidColorMode:) has not been implemented")
    }
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //self.predictSwitch.center = self.center
        //self.predictLabel.center = self.center
        //self.predictLabel.frame.origin = CGPointMake(self.predictSwitch.frame.origin.x + self.predictSwitch.frame.width + 20, self.predictLabel.frame.origin.y)
        
        //let yMax = self.getMaxY()
        //let yMin = self.getMinY()
        //let xMax = self.getMaxX()
        //let xMin = self.getMinX()
        
        let widthBut = (self.getMaxX() - self.getMinX()) / CGFloat(self.numButtons) * CGFloat(self.numRows)
        let heightBut = (self.getMaxY() - self.getMinY()) / CGFloat(self.numRows)
        //let halfWidth = widthBut / CGFloat(2)
        
        var x_offset = CGFloat(0)
        var y_offset = CGFloat(0)
        for index in 0..<self.numButtons {
            buttons[index].frame = CGRect(x: (self.getMinX() + x_offset), y: self.getMinY() + y_offset, width: widthBut - 1, height: heightBut - 1)
            x_offset += widthBut
            if (index + 1) % (self.numButtons / self.numRows) == 0 {
                y_offset += heightBut
                x_offset = CGFloat(0)
            }
            //button.center = self.center
        }
        //self.predictButton.frame.origin = CGPointMake(self.predictSwitch.frame.origin.x + self.predictSwitch.frame.width + 8, self.predictButton.frame.origin.y)
    }
    
    func runOutputFunc(_ sender:UIButton) {
        let wordToAdd = sender.titleLabel!.text!
        if wordToAdd != " "
        {
            self.outFunc(wordToAdd)
            updateButtons(prevWord: "")
        }

        
    }
    
    func updateButtons(prevWord: String) {
        let recommendations = recommendationEngine.recommendWords(input: prevWord)
        for index in 0..<self.numButtons {
            if index < recommendations.count {
                self.buttons[index].setTitle(recommendations[index], for: UIControlState())
            }
            else {
                self.buttons[index].setTitle(" ", for: UIControlState())
            }
        }
    }
    
    /*
    func respondToSwitch() {
        NSUserDefaults.standardUserDefaults().setBool(self.predictSwitch.on, forKey: predictionEnabled)
        //self.updateAppearance()
    }
    
    
    func updateAppearance() {
        if self.predictSwitch.on {
            self.predictLabel.text = "auto"
            self.predictLabel.alpha = 1
        }
        else {
            self.predictLabel.text = "🐱"
            self.predictLabel.alpha = 0.5
        }
        
        self.predictLabel.sizeToFit()
    }*/
    
}




