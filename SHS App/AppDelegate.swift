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
    
    @IBOutlet weak var loginWindow: NSPanel!
    
    @IBOutlet weak var usernameField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    
    @IBOutlet weak var loginButton: NSButton!
    
    @IBOutlet weak var loginCancelButton: NSButton!
    
    @IBOutlet weak var hacTable: NSTableView!
    
    @IBOutlet weak var webView: WebView!
    
    @IBOutlet weak var menuView: NSView!
    
    let statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu : NSMenu = NSMenu()
    var menuItemLogin : NSMenuItem = NSMenuItem()
    var menuItemMain : NSMenuItem = NSMenuItem()
    var menuItemRefresh : NSMenuItem = NSMenuItem()
    
    @IBOutlet weak var menuItemUpdate: NSMenuItem!
    
    var menuItemQuit : NSMenuItem = NSMenuItem()
    
    //Global states for cur url
    var hacSigninURL = true
    var classesRedirectURL = false
    var classesScrape = false
    
    var classArr: Array<ClassInfo> = []
    var populateTable = false
    
    var loadingTableData = false
    
    var loginTest = false
    
    var loggedIn = false
    
    //Vars used in notifications
    var user = ""
    var pass = ""
    
    override func awakeFromNib() {
        
        //Add statusBarItem
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.menu = menu
        statusBarItem.title = "SHS App"
        
        //Add the refresh table menu item
        menuItemRefresh.title = "Refresh"
        menu.addItem(menuItemRefresh)
        
        //Add the menu view
        menuItemMain.view = menuView
        menu.addItem(menuItemMain)
        
        //Add pref item to menu
        menuItemLogin.title = "Log In"
        menuItemLogin.action = Selector("loginClicked:")
        menuItemLogin.keyEquivalent = ""
        menu.addItem(menuItemLogin)
        
        menu.addItem(menuItemUpdate)
        
        menuItemQuit.title = "Quit"
        menuItemQuit.action = Selector("quit:")
        menu.addItem(menuItemQuit)
        
        webView.hidden = true
        
        menu.delegate = self
        
        createNotificationListeners()
        
    }
    
    func quit(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }
    
    func resetVars() {
        classArr = []
        populateTable = false
        
        loadingTableData = false
        
        loginTest = false

        user = ""
        pass = ""
        
        menuItemLogin.title = "Log In"
        menuItemLogin.action = Selector("loginClicked:")
        
        menuItemRefresh.action = nil
        
        //Reload the table to clear it out
        self.hacTable.reloadData()
        
        //Reload the other table too
        AssignmentTableDelegate.classInfo = ClassInfo(className: "nil", assignments:[], classInfo:nil)
        
        NSNotificationCenter.defaultCenter().postNotificationName("updateTable", object: nil)
    }
    
    func createNotificationListeners() {
        //I cant create them in functions as they'd be created as many times as i call the function
        
        /* Notification for populating table */
        NSNotificationCenter.defaultCenter().addObserverForName("webview_finished", object: nil, queue: nil) { note in
            
            //Set the username and password
            var js = "document.getElementById('LogOnDetails_UserName').value='\(self.user)';"
            js += "document.getElementById('LogOnDetails_Password').value='\(self.pass)';"
            
            //Submit the form
            js += "document.getElementsByTagName('button')[0].click();"
            
            let response = self.webView.stringByEvaluatingJavaScriptFromString(js)
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName("redirectToClasses", object: nil, queue: nil) { note in
            //Determine whether or not we're testing or getting data
            self.classesScrape = !self.loginTest
            
            //Redirect to classwork
            let js = "window.location='https://hac.westport.k12.ct.us/HomeAccess/Content/Student/Assignments.aspx'"
            self.webView.stringByEvaluatingJavaScriptFromString(js)
            
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName("populate_table", object: nil, queue: nil) { note in
            //Populate the table
            self.populateTable = true
            self.hacTable.reloadData()
            
            //Create the logout button
            self.menuItemLogin.title = "Log Out"
            self.menuItemLogin.action = Selector("logoutClicked:")
        }
        
        /* Notification for handling whether logged in */
        NSNotificationCenter.defaultCenter().addObserverForName("loggedIn?", object: nil, queue: nil) { note in
            
            //Re-enable everything for next time
            self.loginButton.enabled = true
            self.loginCancelButton.enabled = true
            
            self.usernameField.enabled = true
            self.passwordField.enabled = true
            
            let loggedInObject: AnyObject = note.userInfo!["loggedIn"]!
            
            let isLoggedIn = (loggedInObject as NSObject == 0) ? false : true
            
            if isLoggedIn {
                //User name exists; continue with login
                
                self.loggedIn = true
                
                self.menuItemRefresh.action = Selector("refresh:")
                
                self.login(self.user, pass: self.pass)
                
                self.loginWindow!.orderOut(self)
                
                NSApp.stopModal()
            }
        }
        
    }
    
    func menuWillOpen(menu: NSMenu) {
        //Menubar item pressed; Make menubar prominent
        NSApp.activateIgnoringOtherApps(true)
    }
    
    func refresh(sender: AnyObject) {
        //First empty the table and put it in a loading state
        classArr = []
        
        //Reload the table to clear it out
        self.hacTable.reloadData()
        
        //Reload the other table too
        AssignmentTableDelegate.classInfo = ClassInfo(className: "nil", assignments:[], classInfo:nil)
        
        NSNotificationCenter.defaultCenter().postNotificationName("updateTable", object: nil)
        
        //A simple login should reload everything
        login(self.user, pass: self.pass)
    }
    
    func login(user: String, pass: String, test: Bool = false) {
        //Set up login test if necessary
        self.loginTest = test
        
        if !test {
            //Set table to loadingTable state
            self.loadingTableData = true
            
            self.populateTable = false
            
            self.hacTable.reloadData()
        }
        
        //Set up vars for notifications
        self.user = user
        self.pass = pass
        
        self.hacSigninURL = true
        self.classesRedirectURL = false
        self.classesScrape = false
        
        //Load the login page
        let url = NSURL(string: "https://hac.westport.k12.ct.us/HomeAccess/")
        
        let request = NSURLRequest(URL: url!)
        
        webView.mainFrame.loadRequest(request)
        
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        //Prompt for login if necessary
        self.loginWindow!.makeKeyAndOrderFront(self)
        
    }
    
    
    func loginClicked(sender: AnyObject) {
        NSApp.runModalForWindow(self.loginWindow!)
    }
    
    func logoutClicked(sender: AnyObject) {
        self.hacSigninURL = false
        self.classesRedirectURL = false
        self.classesScrape = false
        self.loginTest = false
        
        let url = NSURL(string: "https://hac.westport.k12.ct.us/HomeAccess/Account/LogOff")
        
        let request = NSURLRequest(URL: url!)
        
        webView.mainFrame.loadRequest(request)
        
        self.resetVars()
    }
    
    @IBAction func loginButtonClicked(sender: AnyObject) {
        
        let username = usernameField.stringValue
        let password = passwordField.stringValue
        
        //First ensure there is a value inputted
        if username != "" && password != "" {
            
            //Validate login
            login(username, pass: password, test: true)
            
            usernameField.enabled = false
            passwordField.enabled = false
            
            loginButton.enabled = false
            loginCancelButton.enabled = false
            
            //Notification will handle the rest
        }
        
    }
    
    @IBAction func closeButtonClicked(sender: AnyObject) {
        
        self.loginWindow!.orderOut(self)
        
        NSApp.stopModal()
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
        
        else if loadingTableData {
            classLabel?.stringValue = "Loading..."
            
            gradeLabel?.stringValue = ""
            
            return cell
        }
        
        classLabel?.stringValue = "Please Log In"
        
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
            
            let js = "window.location.pathname"
            
            let location = self.webView.stringByEvaluatingJavaScriptFromString(js)
            print(location)
            let loggedIn = (location == "/HomeAccess/Home/WeekView")
            
            if (loggedIn) {
                //Already logged in; continue with login
                classesRedirectURL = true
            }
                
            else {
                classesRedirectURL = true
                
                //Webview finished loading, send notification
                NSNotificationCenter.defaultCenter().postNotificationName("webview_finished", object: self)
                
                //We dont want to run any more of this code yet, so return
                return
            }
            
        }
        if classesRedirectURL {
            classesRedirectURL = false
            
            NSNotificationCenter.defaultCenter().postNotificationName("redirectToClasses", object: self)
        }
            
        else {
            if loginTest && !classesScrape {
                let js = "window.location.pathname"
                
                let location = self.webView.stringByEvaluatingJavaScriptFromString(js)
                
                let loggedIn = (location == "/HomeAccess/Content/Student/Assignments.aspx")
                
                NSNotificationCenter.defaultCenter().postNotificationName("loggedIn?", object: self, userInfo: ["loggedIn": loggedIn])
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
        }
        
        
    } //End WebView Sender
    
    
    
    
}

