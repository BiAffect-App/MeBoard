//
//  EditProfile.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 11/2/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit
import SQLite

class EditProfiles: ExtraView, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView?
    @IBOutlet var effectsView: UIVisualEffectView?

    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var keyboardButton: UIBarButtonItem!
    @IBOutlet var settingsLabel: UILabel?
    @IBOutlet var pixelLine: UIView?
    
    var callBack: (String) -> ()
    var deleteCallback: (String) -> ()
    override var darkMode: Bool {
        didSet {
            self.updateAppearance(darkMode)
        }
    }
    
    let cellBackgroundColorDark = UIColor.white.withAlphaComponent(CGFloat(0.25))
    let cellBackgroundColorLight = UIColor.white.withAlphaComponent(CGFloat(1))
    let cellLabelColorDark = UIColor.white
    let cellLabelColorLight = UIColor.black
    let cellLongLabelColorDark = UIColor.lightGray
    let cellLongLabelColorLight = UIColor.gray
    var deleteScreen:DeleteViewController?
    
    // TODO: these probably don't belong here, and also need to be localized
    var profilesList: [(String, [String])]?
    
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        self.callBack = tempCallBack
        self.deleteCallback = tempCallBack
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
        self.loadNib()
        
        let profiles: [String] = Database().getProfiles()

        self.profilesList = [("Profiles", profiles)]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("loading from nib not supported")
    }
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool, outputFunc: () -> Void) {
        fatalError("init(globalColors:darkMode:solidColorMode:outputFunc:) has not been implemented")
    }
    
    func loadNib() {
        let assets = Bundle(for: type(of: self)).loadNibNamed("EditProfile", owner: self, options: nil)
        
        if (assets?.count)! > 0 {
            if let rootView = assets?.first as? UIView {
                rootView.translatesAutoresizingMaskIntoConstraints = false
                self.addSubview(rootView)
                
                let left = NSLayoutConstraint(item: rootView, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
                let right = NSLayoutConstraint(item: rootView, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0)
                let top = NSLayoutConstraint(item: rootView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
                let bottom = NSLayoutConstraint(item: rootView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
                
                self.addConstraint(left)
                self.addConstraint(right)
                self.addConstraint(top)
                self.addConstraint(bottom)
            }
        }
        
        self.tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView?.estimatedRowHeight = 44;
        self.tableView?.rowHeight = UITableViewAutomaticDimension;
        
        let longpress = UILongPressGestureRecognizer(target: self, action: #selector(EditProfiles.longPressGestureRecognized(_:)))
        self.tableView?.addGestureRecognizer(longpress)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(EditProfiles.clickCallback(_:)))
        self.tableView?.addGestureRecognizer(tap)
        
        // XXX: this is here b/c a totally transparent background does not support scrolling in blank areas
        self.tableView?.backgroundColor = UIColor.white.withAlphaComponent(0.01)
        
        self.updateAppearance(self.darkMode)
    }
    
    ///drag and drop code
    func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        let longPress = gestureRecognizer as! UILongPressGestureRecognizer
        let state = longPress.state
        let locationInView = longPress.location(in: tableView)
        let indexPath = tableView?.indexPathForRow(at: locationInView)
        
        struct My {
            static var cellSnapshot : UIView? = nil
            static var cellIsAnimating : Bool = false
            static var cellNeedToShow : Bool = false
        }
        struct Path {
            static var initialIndexPath : IndexPath? = nil
        }
        
        switch state {
        case UIGestureRecognizerState.began:
            if indexPath != nil {
                Path.initialIndexPath = indexPath
                let cell = tableView?.cellForRow(at: indexPath!) as UITableViewCell!
                My.cellSnapshot  = snapshotOfCell(cell!)
                
                var center = cell?.center
                My.cellSnapshot!.center = center!
                My.cellSnapshot!.alpha = 0.0
                tableView?.addSubview(My.cellSnapshot!)
                
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    center?.y = locationInView.y
                    My.cellIsAnimating = true
                    My.cellSnapshot!.center = center!
                    My.cellSnapshot!.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    My.cellSnapshot!.alpha = 0.98
                    cell?.alpha = 0.0
                }, completion: { (finished) -> Void in
                    if finished {
                        My.cellIsAnimating = false
                        if My.cellNeedToShow {
                            My.cellNeedToShow = false
                            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                                cell?.alpha = 1
                            })
                        } else {
                            cell?.isHidden = true
                        }
                    }
                })
            }
            
        case UIGestureRecognizerState.changed:
            if My.cellSnapshot != nil {
                var center = My.cellSnapshot!.center
                center.y = locationInView.y
                My.cellSnapshot!.center = center
                
                if ((indexPath != nil) && (indexPath != Path.initialIndexPath)) {
                    
                    self.profilesList![0].1.insert(self.profilesList![0].1.remove(at: Path.initialIndexPath!.row), at: indexPath!.row)
                    tableView?.moveRow(at: Path.initialIndexPath!, to: indexPath!)
                    Path.initialIndexPath = indexPath
                }
            }
        default:
            if Path.initialIndexPath != nil {
                let cell = tableView?.cellForRow(at: Path.initialIndexPath!) as UITableViewCell!
                if My.cellIsAnimating {
                    My.cellNeedToShow = true
                } else {
                    cell?.isHidden = false
                    cell?.alpha = 0.0
                }
                
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    My.cellSnapshot!.center = (cell?.center)!
                    My.cellSnapshot!.transform = CGAffineTransform.identity
                    My.cellSnapshot!.alpha = 0.0
                    cell?.alpha = 1.0
                    
                }, completion: { (finished) -> Void in
                    if finished {
                        Path.initialIndexPath = nil
                        My.cellSnapshot!.removeFromSuperview()
                        My.cellSnapshot = nil
                        if indexPath != nil {
                            let profileName = self.profilesList![0].1[indexPath!.row]
                            let newRow = indexPath!.row
                            Database().reorderProfiles(profileName: profileName, newRowNum: newRow)
                        }
                    }
                })
            }
        }
    }
    
    func snapshotOfCell(_ inputView: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()! as UIImage
        UIGraphicsEndImageContext()
        
        let cellSnapshot : UIView = UIImageView(image: image)
        cellSnapshot.layer.masksToBounds = false
        cellSnapshot.layer.cornerRadius = 0.0
        cellSnapshot.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
        cellSnapshot.layer.shadowRadius = 5.0
        cellSnapshot.layer.shadowOpacity = 0.4
        return cellSnapshot
    }
    
    //table functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.profilesList!.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.profilesList![section].1.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == (self.profilesList?.count)! - 1 {
            return 50
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.profilesList?[section].0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") {
            let key = self.profilesList?[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row]
            
            let title = key!
            cell.textLabel?.text = title
            cell.backgroundColor = (self.darkMode ? cellBackgroundColorDark : cellBackgroundColorLight)
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        else {
            assert(false, "this is a bad thing that just happened")
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let profile = (self.profilesList?[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row])!
        if profile != "Default" {
            let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
                self.deleteScreen = DeleteViewController(view: self as UIView, type: "profile", name: profile)
                self.deleteScreen?.cancelButton.addTarget(self, action: #selector(self.removeDeleteScreen), for: .touchUpInside)
                self.deleteScreen?.deleteButton.tag = (indexPath as NSIndexPath).row
                self.deleteScreen?.deleteButton.addTarget(self, action: #selector(self.deleteElm(_:)), for: .touchUpInside)
                
            }
            return [delete]
        }
        else {
            let noDelete = UITableViewRowAction(style: .normal, title: "Delete") { (action, indexPath) in
                self.tableView?.setEditing(false, animated: false)
            }
            return [noDelete]
        }
        
    }
    
    func updateAppearance(_ dark: Bool) {
        if dark {
            self.effectsView?.effect
            let blueColor = UIColor(red: 135/CGFloat(255), green: 206/CGFloat(255), blue: 250/CGFloat(255), alpha: 1)
            self.pixelLine?.backgroundColor = blueColor.withAlphaComponent(CGFloat(0.5))
            self.settingsLabel?.textColor = UIColor.white
            
            if let visibleCells = self.tableView?.visibleCells {
                for cell in visibleCells {
                    cell.backgroundColor = cellBackgroundColorDark
                    let label = cell.viewWithTag(2) as? UILabel
                    label?.textColor = cellLabelColorDark
                    let longLabel = cell.viewWithTag(3) as? UITextView
                    longLabel?.textColor = cellLongLabelColorDark
                }
            }
        }
        else {
            let blueColor = UIColor(red: 0/CGFloat(255), green: 122/CGFloat(255), blue: 255/CGFloat(255), alpha: 1)
            self.pixelLine?.backgroundColor = blueColor.withAlphaComponent(CGFloat(0.5))
            self.settingsLabel?.textColor = UIColor.gray
            
            if let visibleCells = self.tableView?.visibleCells {
                for cell in visibleCells {
                    cell.backgroundColor = cellBackgroundColorLight
                    let label = cell.viewWithTag(2) as? UILabel
                    label?.textColor = cellLabelColorLight
                    let longLabel = cell.viewWithTag(3) as? UITextView
                    longLabel?.textColor = cellLongLabelColorLight
                }
            }
        }
    }
    
    func toggleSetting(_ sender: UISwitch) {
        if let cell = sender.superview as? UITableViewCell {
            if let indexPath = self.tableView?.indexPath(for: cell) {
                let key = self.profilesList?[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row]
                UserDefaults.standard.set(sender.isOn, forKey: key!)
            }
        }
    }
    
    func clickCallback(_ gestureRecognizer: UIGestureRecognizer) {
        
        let tap = gestureRecognizer as! UITapGestureRecognizer
        let locationInView = tap.location(in: tableView)
        let indexPath = tableView?.indexPathForRow(at: locationInView)
        if (self.tableView?.isEditing == false) {
            let text = self.profilesList?[((indexPath)?.section)!].1[(((indexPath))?.row)!]
            self.callBack(text!)
        }
    }
    
    func removeDeleteScreen() {
        if self.deleteScreen != nil {
            self.deleteScreen?.warningView.removeFromSuperview()
        }
        self.tableView?.setEditing(false, animated: false)
        self.deleteScreen = nil
    }
    
    func deleteElm(_ sender:UIButton) {
        let profile = (self.profilesList?[0].1[sender.tag])!
        self.deleteCallback(profile)
        /*Database().deleteProfile(profile_name: profile)
        UserDefaults.standard.string(forKey: "profile")
        UserDefaults.standard.register(defaults: ["profile": "Default"])
        self.banner?.profileSelector.setTitle(UserDefaults.standard.string(forKey: "profile")!, for: UIControlState())*/
        removeDeleteScreen()
        self.reloadData()
    }
    
    func reloadData() {
        let profiles: [String] = Database().getProfiles()
        self.profilesList = [("Profiles", profiles)]
        tableView?.reloadData()
    }
    
}

func tempCallBack(tempString:String) {
    print("Not innitialized")
}

