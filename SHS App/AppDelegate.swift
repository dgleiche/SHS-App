//
//  AppDelegate.swift
//  SHS App
//
//  Created by Dylan on 12/1/14.
//  Copyright (c) 2014 Dylan. All rights reserved.
//

import Cocoa
import AppKit
import WebKit

extension String {
    var floatValue: Float {
        return (self as NSString).floatValue
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate {
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var theLabel: NSTextField!
    @IBOutlet weak var theButton: NSButton!
    
    @IBOutlet weak var hacTable: NSTableView!
    
    @IBOutlet weak var webView: WebView!
    
    @IBOutlet weak var menuView: NSView!
    
    var buttonPresses = 0

    let statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu : NSMenu = NSMenu()
    var menuItemPref : NSMenuItem = NSMenuItem()
    var menuItemMain : NSMenuItem = NSMenuItem()
    
    //Global states for cur url
    var hacSigninURL = true
    var classesRedirectURL = false
    var classesScrape = false
    
    var classArr: Array<ClassInfo> = []
    var populateTable = false
    
    override func awakeFromNib() {
        theLabel.stringValue = "You've pressed the button \n \(buttonPresses) times"
        
        //Add statusBarItem
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.menu = menu
        statusBarItem.title = "SHS App"
        
        //Add the menu view
        menuItemMain.view = menuView
        menu.addItem(menuItemMain)
        
        //Add pref item to menu
        menuItemPref.title = "Preferences"
        menuItemPref.action = Selector("setWindowVisible:")
        menuItemPref.keyEquivalent = ""
        menu.addItem(menuItemPref)
        
        webView.hidden = true
        
        menu.delegate = self
        
        login(u, pass: p)
    }
    
    func menuWillOpen(menu: NSMenu) {
        NSApp.activateIgnoringOtherApps(true)
    }
    
    func login(user: String, pass: String) {
        let url = NSURL(string: "https://hac.westport.k12.ct.us/HomeAccess/")
        
        let request = NSURLRequest(URL: url!)
        
        webView.mainFrame.loadRequest(request)
        
        NSNotificationCenter.defaultCenter().addObserverForName("webview_finished", object: nil, queue: nil) { note in
            
            //Set the username and password
            var js = "document.getElementById('LogOnDetails_UserName').value='\(user)';"
            js += "document.getElementById('LogOnDetails_Password').value='\(pass)';"
            
            //Submit the form
            js += "document.getElementsByTagName('button')[0].click();"
            
            let response = self.webView.stringByEvaluatingJavaScriptFromString(js)
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName("populate_table", object: nil, queue: nil) { note in
            self.populateTable = true
            self.hacTable.reloadData()
        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        //Hide window initially
        self.window!.orderOut(self)
    }
    
    @IBAction func buttonPressed(sender: AnyObject) {
        buttonPresses += 1
        theLabel.stringValue = "You've pressed the button \n \(buttonPresses) times!"
        menuItemPref.title = "Clicked \(buttonPresses)"
        statusBarItem.title = "Presses \(buttonPresses)"
    }
    
    func setWindowVisible(sender: AnyObject) {
        //Make pref window visible
        self.window!.orderFront(self)
        
        //Make prominent window
        self.window!.level = 1
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        
        if populateTable {
            return classArr.count
        }
        
        return 1
    }
    
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {

        var cell: NSTableCellView = tableView.makeViewWithIdentifier("HacColumn", owner: tableView.self) as NSTableCellView
        
        let gradeLabel: NSTextField? = cell.viewWithTag(1500)? as? NSTextField
        
        let classLabel: NSTextField? = cell.viewWithTag(1600)? as? NSTextField
        
        if populateTable {
            classLabel?.stringValue = classArr[row].className
            
            var avg = 0
            
            for assignment in classArr[row].assignments {
                
            }
            
            var gradePossible: Float = 0
            var gradeGot: Float = 0
            
            for (category, info) in classArr[row].classInfo! {
                if info.weight > 0 {
                    gradePossible += info.weight
                    gradeGot += info.categoryPoints
                } else {
                    gradePossible += info.totalPoints
                    gradeGot += info.score
                }
            }
            
            if (gradePossible > 0) {
                let grade = round(10000 * (gradeGot/gradePossible)) / 100
            
                gradeLabel?.stringValue = "\(grade)%"
            } else {
                gradeLabel?.stringValue = "No Grade Avail."
            }
            
            return cell
        }
        
        classLabel?.stringValue = "Loading...."
        
        gradeLabel?.stringValue = ""
        
        return cell
        
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        let classIndex = self.hacTable.selectedRowIndexes.firstIndex
        
        if populateTable {
            let classInfo = classArr[classIndex]
            
            AssignmentTableDelegate.classInfo = classInfo
            
            NSNotificationCenter.defaultCenter().postNotificationName("updateTable", object: nil)
        }
    }
    
    override func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        if hacSigninURL {
            hacSigninURL = false
            classesRedirectURL = true
            
            //Webview finished loading, send notification
            NSNotificationCenter.defaultCenter().postNotificationName("webview_finished", object: self)
        } else {
            if classesRedirectURL {
                classesRedirectURL = false
                classesScrape = true
                
                //Redirect to classwork
                let js = "window.location='https://hac.westport.k12.ct.us/HomeAccess/Content/Student/Assignments.aspx'"
                self.webView.stringByEvaluatingJavaScriptFromString(js)
            }
            
            if classesScrape {
                var js = "document.getElementById('btnView').click();"
                js += "document.body.innerHTML"
                let page = self.webView.stringByEvaluatingJavaScriptFromString(js)
                
                let pageData = page.dataUsingEncoding(NSUTF8StringEncoding)
                
                //Evaluate with hpple
                let parser: TFHpple = TFHpple(HTMLData: pageData!)
                
                //Create a selector
                let xpath = "//div[@class='AssignmentClass']"
                
                //Create an array of the nodes
                let classNodes: NSArray = parser.searchWithXPathQuery(xpath)
                
                for node in classNodes {
                    //Find the name of the class
                    let xpathClassName = "//a[@class='sg-header-heading']/text()"
                    
                    let nameNode: NSArray = node.searchWithXPathQuery(xpathClassName)
                    
                    let nameElement: TFHppleElement = nameNode[0] as TFHppleElement
                    var name = nameElement.content
                    
                    //Regex to get rid of extra spaces
                    let regex = NSRegularExpression(pattern: "  +", options: nil, error: nil)
                    
                    name = regex?.stringByReplacingMatchesInString(name, options: nil, range: NSMakeRange(0, name.utf16Count), withTemplate: " ")
                    
                    //Find the 3rd word of the string (the name of the class
                    var nameCut = name.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: " "))
                    
                    nameCut.removeRange(0...3)
                    
                    name = " ".join(nameCut)
                    
                    //Find the assignments
                    let xpathAssignments = "//tr[@class='sg-asp-table-data-row']"
                    let assignmentNodes: NSArray = node.searchWithXPathQuery(xpathAssignments)
                    
                    var assignmentInfoArr: Array<Dictionary<String, (category: String, score: Float, totalPoints: Float)>> = []
                    
                    var classInfoDict: Dictionary<String, (score: Float, totalPoints: Float, weight: Float, categoryPoints: Float)> = [:]

                    for assignmentNode in assignmentNodes {
                        let xpathTableNodes = "//td"
                        let tdNodes = assignmentNode.searchWithXPathQuery(xpathTableNodes)
                        
                        //Filter out the category listings at the bottom
                        //Assignment will be at index 2, category at 3, weighted score at 7, and weighted points at 8
                        if tdNodes.count == 10 {
                            //Assignment name
                            var assignmentElement: TFHppleElement = tdNodes[2] as TFHppleElement
                            assignmentElement = assignmentElement.childrenWithTagName("a")[0] as TFHppleElement
                            
                            let assignment = assignmentElement.content.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                            //Category
                            let categoryElement: TFHppleElement = tdNodes[3] as TFHppleElement
                            let category = categoryElement.content
                            
                            //Score
                            let scoreElement: TFHppleElement = tdNodes[7] as TFHppleElement
                            let score = scoreElement.content
                            
                            //Points
                            let pointsElement: TFHppleElement = tdNodes[8] as TFHppleElement
                            let points = pointsElement.content
                            
                            let assignmentTuple = (category: category!, score: (score as NSString).floatValue, totalPoints: (points as NSString).floatValue)
                            
                            let assignmentInfo: Dictionary<String, (category: String, score: Float, totalPoints: Float)> = [assignment: assignmentTuple]
                            
                            assignmentInfoArr.append(assignmentInfo)
                        } else if tdNodes.count > 0 {
                            //Get the category weights
                            //If there is no weight (based solely on pnt scale) We assign weight of -1 for future reference
                            let tdCategoryElement = tdNodes[0] as TFHppleElement
                            let tdCategory = tdCategoryElement.content
                            
                            let categoryScoreElement = tdNodes[1] as TFHppleElement
                            let categoryMaxElement = tdNodes[2] as TFHppleElement
                            
                            let categoryScore = categoryScoreElement.content.floatValue
                            let categoryMax = categoryMaxElement.content.floatValue
                            
                            var categoryWeight = Float(-1)
                            var categoryPoints = Float(-1)
                            
                            if tdNodes.count == 6 {
                                let categoryWeightElement = tdNodes[4] as TFHppleElement
                                let categoryPointsElement = tdNodes[5] as TFHppleElement
                                
                                categoryWeight = categoryWeightElement.content.floatValue
                                categoryPoints = categoryPointsElement.content.floatValue
                                
                                
                            }
                            
                            let categoryTuple = (score: categoryScore, totalPoints: categoryMax, weight: categoryWeight, categoryPoints: categoryPoints)
                            
                            classInfoDict.updateValue(categoryTuple, forKey: tdCategory)
                        }
                    }
                    //Create a new classinfo object
                    let classInfo: ClassInfo = ClassInfo(className: name, assignments: assignmentInfoArr, classInfo: classInfoDict)
                    classArr.append(classInfo)
                }

                if classArr.count > 0 {
                    //Send notification to populate table
                    NSNotificationCenter.defaultCenter().postNotificationName("populate_table", object: self)
                }
                
            } //End Classes scrape
            
            
        } //End WebView Sender
        
    }


}

