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
        return (SubStruct.classInfo.assignments.count > 0) ? (SubStruct.classInfo.assignments.count + SubStruct.classInfo.classInfo!.count + 1) : 0
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var cell: NSTableCellView = tableView.makeViewWithIdentifier("AssignmentColumn", owner: tableView.self) as NSTableCellView
        
        let assignmentLabel: NSTextField? = cell.viewWithTag(1100)? as? NSTextField
        
        let categoryLabel: NSTextField? = cell.viewWithTag(2000)? as? NSTextField
        
        let scoreLabel: NSTextField? = cell.viewWithTag(2100)? as? NSTextField
        
        let percentLabel: NSTextField? = cell.viewWithTag(2200)? as? NSTextField
        
        if updateTable {
            
            //Row is for total points
            if row == 0 {
                assignmentLabel?.stringValue = "Overall Score"
                
                var gradePossible: Float = 0
                var gradeGot: Float = 0
                
                for (category, info) in SubStruct.classInfo.classInfo! {
                    if info.weight > 0 {
                        gradePossible += info.weight
                        gradeGot += info.categoryPoints
                    } else {
                        gradePossible += info.totalPoints
                        gradeGot += info.score
                    }
                }
                
                categoryLabel?.stringValue = "\(gradeGot)/\(gradePossible)"
                
                scoreLabel?.stringValue = ""
                
                let grade = round(10000 * (gradeGot/gradePossible)) / 100
                
                percentLabel?.stringValue = "\(grade)%"
                
                let categoryInfoLabelColor = NSColor.blueColor()
                
                scoreLabel?.textColor = categoryInfoLabelColor
                percentLabel?.textColor = categoryInfoLabelColor
                assignmentLabel?.textColor = categoryInfoLabelColor
                categoryLabel?.textColor = categoryInfoLabelColor
                
                return cell
            }
            
            //Row is a category
            if row < SubStruct.classInfo.classInfo!.count + 1 {
                
                let categories = SubStruct.classInfo.classInfo!
                
                var i = 0
                for (category, info) in categories {
                    if i == row-1 {
                        assignmentLabel?.stringValue = category
                        
                        let score = info.score
                        let total = info.totalPoints
                        
                        categoryLabel?.stringValue = "\(score)/\(total)"
                        
                        let weight = info.weight
                        let catPoints = info.categoryPoints
                        
                        if weight > 0 {
                            scoreLabel?.stringValue = "* \(weight)"
                            
                            percentLabel?.stringValue = "\(catPoints)"
                            
                        } else {
                            scoreLabel?.stringValue = ""
                            
                            let percent = round(10000 * (score/total)) / 100
                            
                            percentLabel?.stringValue = "\(percent)%"
                        }
                        
                        let categoryInfoLabelColor = NSColor.redColor()
                        
                        scoreLabel?.textColor = categoryInfoLabelColor
                        percentLabel?.textColor = categoryInfoLabelColor
                        assignmentLabel?.textColor = categoryInfoLabelColor
                        categoryLabel?.textColor = categoryInfoLabelColor
                        
                        return cell
                    }
                    i++
                }
            }
            
            //Row is for assignments
            
            let assignmentIndex = row - SubStruct.classInfo.classInfo!.count - 1
            
            let assignment = SubStruct.classInfo.assignments[assignmentIndex]
            
            //No worries assignment only will have 1 member
            for (assignment, info) in assignment {
                assignmentLabel?.stringValue = assignment
                
                categoryLabel?.stringValue = info.category
                
                let score = info.score
                let totalPoints = info.totalPoints
                
                scoreLabel?.stringValue = "\(score)/\(totalPoints)"
                
                let percent = round(10000 * (score/totalPoints)) / 100
                
                percentLabel?.stringValue = "\(percent)%"
                
                let categoryInfoLabelColor = NSColor.blackColor()
                
                scoreLabel?.textColor = categoryInfoLabelColor
                percentLabel?.textColor = categoryInfoLabelColor
                assignmentLabel?.textColor = categoryInfoLabelColor
                categoryLabel?.textColor = categoryInfoLabelColor
            }
        }
        
        return cell
    }


}