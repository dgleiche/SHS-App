//
//  HacScrape.swift
//  SHS App
//
//  Created by Dylan on 12/3/14.
//  Copyright (c) 2014 Dylan. All rights reserved.
//

import Foundation
import Cocoa
import AppKit

//Struct to hold class data. Will have Class Name, then [Assignment : (Category, Score, Total Points)]
struct ClassInfo {
    var className = ""
    
    var assignments: Array<Dictionary<String, (category: String, score: Float, totalPoints: Float)>>
    
    //Holds the categories and their info. Key is the category name
    var classInfo: Dictionary<String, (score: Float, totalPoints: Float, weight: Float, categoryPoints: Float)>?
}

class AssignmentTableDelegate: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var assignmentTable: NSTableView!
    
    var updateTable = false
    
    
    //Workaround for no class vars. Need to store assignments in class var
    private struct SubStruct { static var classInfo: ClassInfo = ClassInfo(className: "nil", assignments:[], classInfo:nil) }
    
    class var classInfo: ClassInfo {
        
        get { return SubStruct.classInfo }
        set { SubStruct.classInfo = newValue }
    }
    
    override func awakeFromNib() {
        NSNotificationCenter.defaultCenter().addObserverForName("updateTable", object: nil, queue: nil) { note in
            self.updateTable = true
            
            self.assignmentTable.reloadData()
        }
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return SubStruct.classInfo.assignments.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var cell: NSTableCellView = tableView.makeViewWithIdentifier("AssignmentColumn", owner: tableView.self) as NSTableCellView
        
        let assignmentLabel: NSTextField? = cell.viewWithTag(1100)? as? NSTextField
        
        let categoryLabel: NSTextField? = cell.viewWithTag(2000)? as? NSTextField
        
        let scoreLabel: NSTextField? = cell.viewWithTag(2100)? as? NSTextField
        
        let percentLabel: NSTextField? = cell.viewWithTag(2200)? as? NSTextField
        
        if updateTable {
            
            let assignment = SubStruct.classInfo.assignments[row]
            
            //No worries assignment only will have 1 member
            for (assignment, info) in assignment {
                assignmentLabel?.stringValue = assignment
                
                categoryLabel?.stringValue = info.category
                
                let score = info.score
                let totalPoints = info.totalPoints
                
                scoreLabel?.stringValue = "\(score)/\(totalPoints)"
                
                let percent = round(10000 * (score/totalPoints)) / 100
                
                percentLabel?.stringValue = "\(percent)%"
            }
        }
        
        return cell
    }


}