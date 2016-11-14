//
//  predictboard.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 9/24/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit
import SQLite

/*
 This is the demo keyboard. If you're implementing your own keyboard, simply follow the example here and then
 set the name of your KeyboardViewController subclass in the Info.plist file.
 */

class predictBoard: KeyboardViewController, UIPopoverPresentationControllerDelegate {
    
    let words = Database()
    var banner: predictboardBanner? = nil
    let recommendationEngine = Database()
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        UserDefaults.standard.register(defaults: ["profile": "Default"])
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func keyPressed(_ key: Key) {
        
        let textDocumentProxy = self.textDocumentProxy
        var keyOutput = ""
        if key.type != .backspace {
            keyOutput = key.outputForCase(self.shiftState.uppercase())
        }
        textDocumentProxy.insertText(keyOutput)
        let lastWord = getLastWord(delete: false)
        /*if key.type == .backspace
        {
            lastWord = lastWord.substring(to: lastWord.index(before: lastWord.endIndex))
        }*/
        if key.type == .space {
            do {
                let context = textDocumentProxy.documentContextBeforeInput
                let components = context?.components(separatedBy: " ")
                let count = (components?.count)! as Int
                let lastWord = (components?[count-2])! as String
                
                let db_path = dbObjects().db_path
                let db = try Connection("\(db_path)/db.sqlite3")
                let containers = dbObjects.Containers()
                
                let currentProfile = UserDefaults.standard.value(forKey: "profile") as! String
                // if word notExists in database
                if (try db.scalar(containers.table.filter(containers.ngram == lastWord).count) == 0) {
                    // insert lastWord into database
                    let insert = containers.table.insert(containers.ngram <- lastWord,
                                    containers.profile <- currentProfile, containers.frequency <- 1)
                    _ = try? db.run(insert)
                }
                else {
                    // increment lastWord in database
                    try db.run(containers.table.filter(containers.ngram == lastWord)
                                         .filter(containers.profile == currentProfile)
                                         .update(containers.frequency++, containers.lastused <- Date()))
                }
            } catch {}
        }
        self.updateButtons(prevWord: lastWord)
        return
    }
    
    override func setupKeys() {
        super.setupKeys()
    }
    
    override func createBanner() -> ExtraView? {
        self.banner = predictboardBanner(globalColors: type(of: self).globalColors, darkMode: self.darkMode(), solidColorMode: self.solidColorMode())
        self.layout?.darkMode

        //set up profile selector
        self.banner?.profileSelector.addTarget(self, action: #selector(showPopover), for: .touchUpInside)
         self.banner?.profileSelector.setTitle(UserDefaults.standard.string(forKey: "profile")!, for: UIControlState())
        
        //setup autocomplete buttons
        for button in (self.banner?.buttons)! {
            button.addTarget(self, action: #selector(autocompleteClicked), for: .touchUpInside)
            //button.addTarget(self, action: #selector(KeyboardViewController.playKeySound), for: .touchDown)

        }

        //Create selector pop up
        /*var tableView = UITableView()
        tableView = UITableView(frame: UIScreen.main.bounds, style: UITableViewStyle.plain)
        tableView.delegate      =   self.popUpController
        tableView.dataSource    =   self.popUpController
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(tableView)*/
        
        
        //populate buttons
        updateButtons(prevWord: "")
        
        return self.banner
    }
    
    
    
    ///autocomplete code
    func autoComplete(_ word:String) -> () {
        let textDocumentProxy = self.textDocumentProxy
        
        _ = getLastWord(delete: true)
        var insertionWord = word
        if let postContext = textDocumentProxy.documentContextAfterInput
        {
            let postIndex = postContext.startIndex
            if postContext[postIndex] != " " //add space if next word doesnt begin with space
            {
                insertionWord = word + " "
            }
        }
        else //add space if you are the last added word.
        {
            insertionWord = word + " "
        }
        // update database with insertion word
        textDocumentProxy.insertText(insertionWord)
    }
    
    func getLastWord(delete: Bool) ->String {
        let textDocumentProxy = self.textDocumentProxy
        var prevWord = ""
        if let context = textDocumentProxy.documentContextBeforeInput
        {
            if context.characters.count > 0
            {
                var index = context.endIndex
                index = context.index(before: index)
                
                while index > context.startIndex && context[index] != " "
                {
                    prevWord.insert(context[index], at: prevWord.startIndex)
                    //prevWord += String(context[index])
                    index = context.index(before: index)
                    if delete{
                        textDocumentProxy.deleteBackward()
                    }
                }
                if index == context.startIndex && context[index] != " "
                {
                    prevWord.insert(context[index], at: prevWord.startIndex)
                    //prevWord += String(context[index])
                    if delete {
                        textDocumentProxy.deleteBackward()
                    }
                }
            }
        }
        return prevWord
    }
    
    func autocompleteClicked(_ sender:UIButton) {
        let wordToAdd = sender.titleLabel!.text!
        if wordToAdd != " "
        {
            self.autoComplete(wordToAdd)
            // increment frequency of word in database
            do {
                let db_path = dbObjects().db_path
                let db = try Connection("\(db_path)/db.sqlite3")
                let containers = dbObjects.Containers()
                let currentProfile = UserDefaults.standard.value(forKey: "profile") as! String
                try db.run(containers.table.filter(containers.ngram == wordToAdd)
                                     .filter(containers.profile == currentProfile)
                                     .update(containers.frequency++, containers.lastused <- Date()))
            }
            catch {
                print("Incrementing word frequency failed")
            }
            updateButtons(prevWord: "")
        }
    }
    
    func updateButtons(prevWord: String) {
        // Get previous words to give to recommendWords()
        // ------------------------
        let context = textDocumentProxy.documentContextBeforeInput
        let components = context?.components(separatedBy: " ")
        let count = (components?.count)! as Int
        var word1 = ""
        var word2 = ""
        if count >= 3 {
            word1 = (components?[count-3])! as String
            word2 = (components?[count-2])! as String
        }
        // ------------------------
        let recommendations = Array(recommendationEngine.recommendWords(word1: word1, word2: word2,
                                                                        current_input:prevWord)).sorted()
        var index = 0
        for button in (self.banner?.buttons)! {
            if index < recommendations.count {
                button.setTitle(recommendations[index], for: UIControlState())
                button.addTarget(self, action: #selector(KeyboardViewController.playKeySound), for: .touchDown)
            }
            else {
                button.setTitle(" ", for: UIControlState())
                button.removeTarget(self, action: #selector(KeyboardViewController.playKeySound), for: .touchDown)
            }
            index += 1
        }
    }
    
        
    
    //Pop ups
    @IBAction func showPopover(sender: UIButton) {
        
        let tableViewController = PopUpTableViewController(selector: sender as UIButton!)
        tableViewController.modalPresentationStyle = UIModalPresentationStyle.popover
        
        present(tableViewController, animated: true, completion: nil)
        
        let popoverPresentationController = tableViewController.popoverPresentationController
        popoverPresentationController?.sourceView = sender as? UIView
        let height = Int(sender.frame.height)
        let width = Int(sender.frame.height) / 2
        //popoverPresentationController?.sourceRect = CGRect(origin: CGPoint(x: 0,y :height), size: CGSize(width: 100, height: 100))//CGRectMake(0, 0, sender.frame.size.width, sender.frame.size.height)
        
        popoverPresentationController?.sourceRect = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: width, height: height))
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
}


