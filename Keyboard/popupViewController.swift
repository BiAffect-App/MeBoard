//
//  popupTableViewController.swift
//  TastyImitationKeyboard
//
//  Created by Benjamin Katz on 11/3/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import Foundation
import UIKit
import SQLite

class PopUpViewController:  UIViewController,UITableViewDelegate, UITableViewDataSource {
    let popUpView = UIView()
    let tableView = UITableView()
    var selector: UIButton?
    var items: [String] = []
    var addButton = UIButton()
    var editButton = UIButton()
    
    init(selector: UIButton)
    {
        super.init(nibName: nil, bundle: nil)
        self.selector = selector
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add all Profiles to items
        let db_path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true).first!
        do {
            let db = try Connection("\(db_path)/db.sqlite3")
            for profile in try db.prepare(Table("Profiles")) {
                self.items.append(profile[Expression<String>("name")])
                print(profile[Expression<String>("name")])
            }
        }
        catch {
            print("Database connection failed")
        }
        
        // Do any additional setup after loading the view, typically from a nib.
        tableView.rowHeight = 40
        let width = 300
        let height = items.count * Int(self.tableView.rowHeight)
        
        //popUpView.frame = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 300, height: Int(height + Int(tableView.rowHeight))))
        
        tableView.frame         =   CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: width, height: height))
        self.preferredContentSize = CGSize(width: width, height: height + Int(tableView.rowHeight))
        tableView.delegate      =   self
        tableView.dataSource    =   self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.view.addSubview(tableView)
        
        addButton.frame = CGRect(x: 0, y: height, width: width / 2 - 1, height: Int(tableView.rowHeight))
        addButton.backgroundColor = UIColor.white
        addButton.setTitle("+", for: UIControlState())
        addButton.setTitleColor(UIColor.black, for: UIControlState())
        addButton.addTarget(self, action: #selector(dismissPopUp), for: .touchUpInside)
        self.view.addSubview(addButton)
        
        editButton.frame = CGRect(x: width / 2 + 1, y: height, width: width / 2 - 1, height: Int(tableView.rowHeight))
        editButton.backgroundColor = UIColor.white
        editButton.setTitle("edit", for: UIControlState())
        editButton.setTitleColor(UIColor.black, for: UIControlState())
        editButton.addTarget(self, action: #selector(dismissPopUp), for: .touchUpInside)
        self.view.addSubview(editButton)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        let text = self.items[indexPath.row]
        cell.textLabel?.text = text
        if text == selector?.titleLabel!.text! {
            cell.backgroundColor = UIColor.init(red: 242/255, green: 193/255, blue: 133/255, alpha: 1)
        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let newSelection = self.items[indexPath.row]
        selector?.setTitle(newSelection, for: UIControlState())
        UserDefaults.standard.register(defaults: ["profile": newSelection])
        dismissPopUp()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismissPopUp(){
        self.dismiss(animated: true, completion: { _ in })
    }
    
    
}

