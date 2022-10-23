//
//  ViewController.swift
//  Klear
//
//  Created by Yorwos Pallikaropoulos on 6/25/20.
//  Copyright © 2020 Yorwos Pallikaropoulos. All rights reserved.
//

import UIKit
import MobileCoreServices
import WidgetKit

class ViewController: UIViewController {
    private var isAnimating = false
    
    private let moc = CoreDataStack.regularStore().moc!
    
//    MARK: - outlets
  
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var placeholderViewTop: UIView!
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var placeHolderViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var placeHolderViewHeightConstraint: NSLayoutConstraint!
 
    //    MARK: - private constants
    
    private let colors: [UIColor] = [#colorLiteral(red: 0.8509803922, green: 0, blue: 0.0862745098, alpha: 1), #colorLiteral(red: 0.862745098, green: 0.1137254902, blue: 0.09019607843, alpha: 1), #colorLiteral(red: 0.8745098039, green: 0.2274509804, blue: 0.09411764706, alpha: 1),  #colorLiteral(red: 0.8862745098, green: 0.3450980392, blue: 0.09803921569, alpha: 1), #colorLiteral(red: 0.8941176471, green: 0.4588235294, blue: 0.1019607843, alpha: 1), #colorLiteral(red: 0.9058823529, green: 0.5725490196, blue: 0.1058823529, alpha: 1), #colorLiteral(red: 1, green: 0.7647058824, blue: 0.2431372549, alpha: 1)]
    private let doneBackgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
    let transformLayer = CATransformLayer()
    
//    MARK: - private variables - initial constraints/positions
    private let shadingView = UIView() // used to shade all other cells when in editing mode
    private var tableViewInitialTopConstraint =  CGFloat()
//    used to set the scrollingZones when dragging a cell
    private var defaultScrollingLimit: CGFloat = 0.0
    private var bottomScrollZoneLimit: CGFloat = 0.0
    private var topScrollZoneLimit: CGFloat = 0.0
    private var topScrollZoneRect:CGRect{
        let differenceOfTop = tableView.frame.minY
        let rect = CGRect(x: 0, y: view.frame.minY , width: tableView.frame.width, height: topScrollZoneLimit + differenceOfTop)
        return rect
    }
    
    private var bottomScrollZoneRect :CGRect{
        let differenceOfBottom = view.frame.maxY - tableView.frame.minY - tableView.frame.height
        let rect = CGRect(x: 0, y: view.frame.maxY - differenceOfBottom - bottomScrollZoneLimit , width: tableView.frame.width, height: bottomScrollZoneLimit + differenceOfBottom)
        return rect
    }
    
    // will be used special handling in case there are not enough rows to cover the entire view
    private var isTableSmallerThanItsView:Bool{
        if tableView.contentSize.height < tableView.frame.height{
            return true
        }else{
            return false
        }
    }
   
    private var draggingCellSnapshot: UIView?
    private var initialCellToBeDragged = UITableViewCell()

//  MARK: - states
    
//    will use these to see if we passed the threshold and decide if we will add a new item
//    threshold = row height
    private var scrollOffsetWhenDraggingEnded:CGFloat = 0
    private var scrollOffsetThreshold: CGFloat = 0
    
//  editing mode: - while a cell is selected and its text filed is edited.
//  we are using this to block all other interactions
    private var editingMode: Bool = false{
        didSet{
            if editingMode == true{
                blockInteractions()
            }else{
                unBlockInteractions()
            }
        }
    }
//    the cell which is currently being edited
    private var editingCell:TodoCell?
    
//    a placeholder for new cell (will be used in the "pull to create new item" action
    var newItemCellPlaceholder = UITableViewCell()

// using this mode to check if we are in the process of adding a new item
    private var addingNewItemMode: Bool = false

// keep the offset position when entering mode, in order to return to the same position afterwards
    private var tableViewEditingOffset: CGFloat = 0.0
    
//   MARK: - gesture recognizers

    private var tapGestureRecognizer = UITapGestureRecognizer()
    private var longGestureRecognizer = UILongPressGestureRecognizer()
    private var pinchGestureRecognizer = UIPinchGestureRecognizer()

//    MARK: - model helper functions
    
//    this holds the actual items
    private var todos: ToDos = ToDos(items: [])
    
    private func loadToDoItems(){
        print("Load items...")
        todos = ItemRepo.allIn(moc: moc)
    }

//    MARK: - helper UI variables and functions
    //    get the frame for indexPath
    //    !!CHECK!! not sure if this is needed
    
    private func frameForRow(at indexPath:IndexPath) -> CGRect{
        let rowHeight = tableView.rowHeight
        let row = indexPath.row
        let width = tableView.frame.width
        let y = rowHeight * CGFloat(row)
        return CGRect(x: 0, y: y, width: width, height: rowHeight)
    }
    
    private var getNextColor: UIColor{
        get{
            let index = todos.rowNumberToIndex(from: todos.indexOfFirstNotDoneItem)
            return getColor(for: index, in: todos.countOfNotDoneItems + 1)
        }
    }

    private func blockInteractions(){
        tableView.isScrollEnabled = false
        self.tableView.dragInteractionEnabled = false
        longGestureRecognizer.isEnabled = false
    }
    
    private func unBlockInteractions(){
        tableView.isScrollEnabled = true
        self.tableView.dragInteractionEnabled = true
        longGestureRecognizer.isEnabled = true
    }
    
    private func getColorForPlaceHolderTop() -> UIColor{
        if let firstVisibleCell = tableView.visibleCells.first as? TodoCell{
            let bgColor = firstVisibleCell.getBackGroundColor()
            return bgColor
        }else{
            return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        }
    }
    

//MARK: - initial setup
       
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup the table view and the custom cell
        let todoCellView = UINib(nibName: "TodoCell", bundle: nil)
        self.tableView.register(todoCellView, forCellReuseIdentifier: "TodoCell")
        self.tableView.keyboardDismissMode = .onDrag
        tableView.delegate = self
        tableView.dataSource = self
        
        // setup the scrollOffset (user dragging to create a new item) threshold
        scrollOffsetThreshold = -tableView.rowHeight
        
        // Disable selection (no use for selecting rows)
        tableView.allowsSelection = false
        tableView.allowsSelectionDuringEditing = false
        
        tableViewInitialTopConstraint = tableViewTopConstraint.constant

        // initialize the list of items (and the table)
        loadToDoItems()
        // this is used to create a dummy cell at the top of the table while adding a new item
        newItemCellPlaceholder = UITableViewCell(style: .default, reuseIdentifier: "TodoCell")
        
        resetScrollPosition()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)

        placeHolderViewHeightConstraint.constant = 5.0 //!!CHECK!! I don't know if this is actually needed
        tableView.contentInset.bottom = tableView.rowHeight

        // setup the newItemPlaceHolder
        addPlaceHolderForNewItem()

        // initial setup for gesture recognizers

        // used for custom drag & drop of cells
        longGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longGestureRecognizer.cancelsTouchesInView = true
        longGestureRecognizer.delaysTouchesBegan = true
        longGestureRecognizer.delegate = self
        longGestureRecognizer.numberOfTapsRequired = 0
        view.addGestureRecognizer(longGestureRecognizer)
        
        // will use the tap recognizer to dismiss editing mode
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(handleTap))
        tapGestureRecognizer.delegate = self
        tapGestureRecognizer.delaysTouchesBegan = true

        // initial setup for scrolling zones
        defaultScrollingLimit = tableView.rowHeight * 2.0
        resetScrollZones()
    }
    
    private func addPlaceHolderForNewItem(){
        var perspective = CATransform3DIdentity
        perspective.m34 = -1/200
        transformLayer.transform = perspective
        let anchorPoint = CGPoint(x: 0.5, y: 1.0)
        newItemCellPlaceholder.textLabel?.textColor = .white
        newItemCellPlaceholder.layer.anchorPoint = anchorPoint
        let width = tableView.bounds.width
        let height = tableView.rowHeight
        newItemCellPlaceholder.frame = CGRect(x:  -width / 2.0 , y: -height , width: width, height: height)
        transformLayer.position = CGPoint(x: width/2.0, y: 0)
        transformLayer.addSublayer(newItemCellPlaceholder.layer)
        tableView.layer.addSublayer(transformLayer)
        let ratio:CGFloat = .pi/2
        newItemCellPlaceholder.layer.transform = CATransform3DMakeRotation(ratio, 1, 0, 0)
    }
    
    private func removePlaceHolderForNewItem(){
        transformLayer.removeFromSuperlayer()
    }
    
    private func resetScrollPosition(to offset: CGFloat = 0){
        tableView.contentOffset.y = 0
    }

//  MARK: - editing functions
    /*
         when tapping is done on a cell we are entering editing mode. Following things happen:
         1. TodoCell, check if it can be edited and (if yes) textField becomes first responder (handled by the view)
         2. This triggers textFieldDidBeginEditing delegate which calls todoCellWillModify (in VC)
         3. When editing ends, textField resings first responder and its delegate calls todoCellWasModified (TodoCell delegate method in VC)
         4. TodoCellWasModified calls following method (updateCellAndReturnToPreviousState)
    */

    fileprivate func deleteCell(_ index: Int, indexPath: IndexPath, cell: TodoCell) {
        let distance = 1.5 * tableView.frame.width
        
        UIView.animate(withDuration: 0.2, animations: {
            cell.leftConstraint.constant = -distance
            cell.rightConstraint.constant = distance
            cell.checkLabelLeftConstraint.constant = -distance
            cell.deleteLabelRightConstraint.constant = distance
            cell.layoutIfNeeded()
        }) { (ended) in
            // update the model
            self.tableView.performBatchUpdates({
                print("Remove item")
                self.todos.remove(at: index)
                ItemRepo.saveIn(moc: self.moc, todos: self.todos)
                WidgetCenter.shared.reloadAllTimelines()
                self.todos.remove(at: index)
                self.tableView.deleteRows(at: [indexPath], with: .none)
            }) { (done) in
                self.tableView.reloadData()
            }
        }
    }
    
    fileprivate func updateCell(_ index: Int, cell: TodoCell) {
        self.todos.getAt(index: index).setTitle(title: cell.textField.text)
        self.tableView.reloadData()
    }
    
    private func updateCellAndReturnToPreviousState(cell: TodoCell){
        // disable scrolling of table view until we've finished with animations
        tableView.isScrollEnabled = false

        // if all text was deleted, mark the cell for deletion
        let cellIsToBeDeleted =  cell.textField.text! == "" ? true  : false

        // scroll back to the position before editing started
        // make the cells opaque
        UIView.animate(withDuration: 0.25, delay:  0.0 ,  options: .curveEaseOut, animations: {
            self.tableView.contentOffset.y = self.tableViewEditingOffset
            let visibleCells = self.tableView.visibleCells
            for visibleCell in visibleCells{
                visibleCell.alpha = 1.0
            }
        }) {(ended) in
            //reset the content inset
            self.tableView.contentInset.bottom = self.tableView.rowHeight
            self.editingCell = nil
  
            // update the model with the modified entry, or delete it if the text is now empty
            if let tableView = cell.superview as? UITableView, let indexPath = tableView.indexPath(for: cell){
                let index = self.todos.rowNumberToIndex(from: indexPath.row)
                if cellIsToBeDeleted{
                    self.deleteCell(index, indexPath: indexPath, cell: cell)
                }else{
                    self.updateCell(index, cell: cell)
                }
            }

            // remove the tap recognizer
            self.view.removeGestureRecognizer(self.tapGestureRecognizer)
            self.editingMode = false
            self.addingNewItemMode = false // if this was triggered by the adding new item procedure, exit
        }
    }
    
//    MARK: - add new item functions
    
    /*
         For a new item to be added, following should happen
         1. User drags the table until it passes a threshold (set to be the row size)  - state of dragging is handled by scrollViewDidScroll
         2. User relases while still beyond the threshold - offset is fixed in scrollViewDidEndDragging
         3. scrollViewDidScroll calls addNewItem
         following are the same steps as in editing mode
         4. When editing ends, textField resings first responder and its delegate calls todoCellWasModified (TodoCell delegate method in VC)
         5. TodoCellWasModified calls following method (updateCellAndReturnToPreviousState)
    */
        
    private func addNewItem(at indexPath:IndexPath){
        /*
            1. add a new blank item at the array
            2. add rowHeight to the current offset of the table
               (to compensate for the removal of the placeholder)
            3. reload table data
            4. make the new cell's text field the fiest responder
               (this triggers the whole editing procedure)
         */
        print("addNewItem")
        let item = ItemRepo.create()
        todos.append(item: item)
        tableView.contentOffset.y = tableView.contentOffset.y + tableView.rowHeight
        tableView.reloadData()
       
        if let newCell =  tableView.cellForRow(at: indexPath) as? TodoCell{
            print("Take focus")
            newCell.textField.text = ""
            newCell.textField.becomeFirstResponder()
        }
    }
    
    //  currently not used
    @objc func handlePinch(sender: UIPinchGestureRecognizer){
        switch sender.state{
        case .began:
            break
        //   let position = sender.location(in: tableView)
        // let indexPath = tableView.indexPathForRow(at: position)
        case .changed:
            break
        default:
            break
        }
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended, editingMode == true{
            view.endEditing(false)
        }
    }

    // updates the BG color for each of the visible cells
    private func updateColors(){
        let visibleCells = tableView.visibleCells
        guard let indexPathsForVisibleCells = tableView.indexPathsForVisibleRows else {return}
        var i = 0
        for visibleCell in visibleCells{
            if let cell = visibleCell as? TodoCell{
                let bgColor = cell.isAlreadyDone ? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) : getColor(for: indexPathsForVisibleCells[i].row)
                cell.setBackground(color:bgColor)
                i += 1
            }
        }
    }

    private func getColor(for index:Int, in colorCount:Int = 0) -> UIColor{
        var color:UIColor
        if todos.countOfNotDoneItems < colors.count {
            color = colors[index]
            return color
        }else{
            let startColor = colors.first!
            let endColor = colors.last!
            var percentage:CGFloat
            percentage = colorCount == 0 ? CGFloat(index)/CGFloat(todos.countOfNotDoneItems) : CGFloat(index)/CGFloat(colorCount)
            let color = UIColor.interpolate(from: startColor, to: endColor, with: percentage)
            return color
        }
    }


    
    private func shadeAllOtherCellsExcept(cell: UITableViewCell, with alpha: CGFloat = 0.3){
        tableView.visibleCells.forEach { (visibleCell) in
            if visibleCell != cell{
                visibleCell.alpha = alpha
            }
        }
    }
    
//    MARK: - methods for custom drag and drop
    /*
         Needed to implement custom drag & drop for better control
         The drag is detected by a longPressGestureRecognizer (action handleLongPress)
         3 states are used:
         1. began:
            the indexPath is detected and initialCellToBeDragged gets the current cell.
            the initial scroll zones are defined (when entering these, scrolling will occur)
            a snapshotView is created and a short magnification animation is performed.
            the snapshotView is going to be moved (the cell is hidden)
            a CADisplayLink is created. This will periodically call scrollTableAndCell to handle
            moving of the snapshot and the scrolling of table (when needed)
        2. ended:
            handling the drop:
            scrollZones are reset
            the destination position is calculated and the snapshot is animated to the position
            display link is invalidated (scrollTableAndCell is not called any more)
            the cell is revealed.
        3. cancel:
            invalidate the display link
     
        Drag struct keeps info about the state of the drag
     */
    
    @objc func handleLongPress(sender: UILongPressGestureRecognizer) {
        // get the location of the touch
        
        let locationInTableView = sender.location(in: tableView) // used for calculation of index path
        let locationInSuperView = sender.location(in: view) // used to calculate the position of the dragging cell
        Drag.diffCurrentAndCalculatedOffset = 0.0

        switch sender.state {
            
        case .began:

            // ignore if user touches the blurView
            if blurView.frame.contains(locationInSuperView) {
                sender.state = .cancelled
                return
            }
            
            //save the initial position
            Drag.currentPosition = locationInSuperView
        
            // get the  indexPath, if possible - else exit (no cell to drag)
            
            guard let indexPath = tableView.indexPathForRow(at: locationInTableView) else {return}
            // get the actual cell
            if let cell = tableView.cellForRow(at: indexPath) as? TodoCell{

                // check if the current location is already within the scroll zones
                // if yes adjust it accordingly (add 5 points threshold)
                if bottomScrollZoneRect.contains(locationInSuperView){
                    bottomScrollZoneLimit = view.frame.maxY - locationInSuperView.y + 5.0
                }else if topScrollZoneRect.contains(locationInSuperView){
                    topScrollZoneLimit = locationInSuperView.y - view.frame.minY  + 5.0
                }
                // save the cell and the indexPath
                initialCellToBeDragged = cell
                Drag.currentIndexPath = indexPath
                // calculate the touch position as offset from cell's center
                Drag.cellOffsetFromCenter = CGPoint(x: locationInTableView.x - cell.center.x , y: locationInTableView.y - cell.center.y)
                
                // create the snapshot (if not possible, exit - nothing to do here)
                guard let snapshot = cell.snapshotView(afterScreenUpdates: true) else {return}

                // initialize it - the cell is going to be magnified a little bit and cast a shadow
                snapshot.frame = cell.convert(cell.bounds, to: view) //cell is going to move within view (not tableView)
                snapshot.layer.shadowOffset = CGSize(width: 5.0, height: 5.0)
                snapshot.layer.shadowRadius = 5.0
                snapshot.layer.shadowOpacity = 0.4
                draggingCellSnapshot = snapshot
                
                //now add it to view
                view.addSubview(draggingCellSnapshot!)
                
                // and create the magnification animation
                UIView.animate(withDuration: 0.25) { [weak self] in
                    if self?.draggingCellSnapshot != nil{
                        self?.draggingCellSnapshot!.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                    }
                }

                // hide the initialCell, movement will be done for the snapshot
                initialCellToBeDragged.alpha = 0.0
                // intialize the displayLink
                Drag.displayLink = CADisplayLink(target: self, selector:#selector(scrollTableAndCell))
                Drag.displayLink?.add(to: .main, forMode: .default)
            }
            
        case .changed:
            break
            
        case .ended:
            resetScrollZones() //for the next dragging sesssion
            // reset display link - don't want to call that anymore
            Drag.displayLink?.invalidate()
            Drag.displayLink = nil

            // animate the cell to its resting position
            // following options:
            // 1. the current position corresponds to a valid indexPath
            //        ok, unless we scrolled with no swapping (see scrollTableAndCell) and dropped in outside the tableView
            if let indexPath = Drag.currentIndexPath{
                if let destinationCell = tableView.cellForRow(at: indexPath){

                    // translate the destinationFrame to superview
                    let destinationFrame = tableView.convert(destinationCell.frame, to: view)
                    animateSnapshotToFinalFrame(destinationFrame)
                }

                //        should be out of bounds, get the indexPath of the draggingCell
            }else{
                //                if indexPath is nil there 2 chances:
                //                1. dragginCellSnapshot is beyond the list of items so, it should get the final indexpath
                //                 2. dragginCellSnapshot is at the very top, it should get index = 0
                if let draggingIndexPath = Drag.currentIndexPath{
                    if draggingIndexPath.row == 0 || draggingIndexPath.row == todos.count() - 1{
                        if  let destinationCell = tableView.cellForRow(at: draggingIndexPath){
                            let destinationFrame = tableView.convert(destinationCell.frame, to: view)
                            animateSnapshotToFinalFrame(destinationFrame)
                        }
                    }
                }
            }

            TodoCell.shoudlBlockTextField = false
        case .cancelled:
            Drag.displayLink?.invalidate()
            Drag.displayLink = nil
            TodoCell.shoudlBlockTextField = false
            //            - TODO: move the initial cell to its original position
        default:
            break
        }
    }

    private func resetScrollZones(){
        topScrollZoneLimit = defaultScrollingLimit
        bottomScrollZoneLimit = defaultScrollingLimit
    }
    /*
      scrollTableAndCell is called periodically (via displayLink) while dragging a cell (snapshot)
      - updates the position of the dragging cell snapshot
      - if the cell snapshot is over another cell (different index path than the previous known index path), swaps the cells
      - if the snapshot is within the top/bottom scrolling zones (threshold) it scrolls the tableView as well

     */
    @objc private func scrollTableAndCell() {
        // get the current location in view (used to track the position of the cell snapshot)
        let currentLocationInView = longGestureRecognizer.location(in: view)
        // and the location in tableView (used to calculate current index path in tableView)
        let currentLocationInTableView = longGestureRecognizer.location(in:tableView)
        
        // update the snapshot based on location
        update(snapshot: draggingCellSnapshot, with: currentLocationInView)
        
        var newOffset = Double(tableView.contentOffset.y)
        
        // get the current table view offset
        let currentOffsetY = Double(tableView.contentOffset.y)
  
        // *****  swapping cell part  *****
        var adjustedLocation = currentLocationInTableView
        // if the current position is above the visible portion of the tableView
        // (i.e we are currently touching the blur view)
        // adjust the position, in order to be just within the visible view
        // thus avoid swap loop (top 2 cells constantly swapping each other)
        if Double(currentLocationInTableView.y) < Double(tableView.rowHeight) + currentOffsetY,
            currentOffsetY >= 0.0{
            
            if currentOffsetY > 0.0{
                adjustedLocation = CGPoint(x: Double(currentLocationInTableView.x), y: Double(tableView.rowHeight) + currentOffsetY)
                
            }else{ // we are at the very top of the table (used to be able to swap the first cell)
                adjustedLocation = CGPoint(x: Double(currentLocationInTableView.x), y: 0.0)
            }
        }
        
        // get the current index path and swap if it is different than the previous known index path
        if let currentIndexPath = tableView.indexPathForRow(at: adjustedLocation){
            if currentIndexPath != Drag.currentIndexPath{
                swapCell(Drag.currentIndexPath!, currentIndexPath)
            }
            // save the current indexPath
            Drag.currentIndexPath = currentIndexPath
        }
        
        // *****  scrolling part *****
        if let lastLocation = Drag.currentPosition,
            lastLocation != currentLocationInView
        {
            //  check if we are within scrollZones
            if topScrollZoneRect.contains(currentLocationInView){
                // calculate the offset to scroll to top gradually
                let diff = Double((topScrollZoneRect.maxY - currentLocationInView.y)/Drag.scrollingRate)
                newOffset = currentOffsetY - diff
            }else if bottomScrollZoneRect.contains(currentLocationInView){
                // calculate the offset to scroll to bottom gradually
                let diff = Double((currentLocationInView.y - bottomScrollZoneRect.minY)/Drag.scrollingRate)
                newOffset = currentOffsetY + diff
            }
        }
        
        // re-adjust the offset if it is less than 0 or the table has few enough cells not to be scrollable
        let maxScrollLimit: Double = isTableSmallerThanItsView ? 0.0 : Double(tableView.contentSize.height - tableView.frame.height + tableView.contentInset.bottom)
        let minScrollLimit: Double = 0.0
        if newOffset < minScrollLimit{
            newOffset = minScrollLimit
        }else if newOffset > maxScrollLimit{
            newOffset = maxScrollLimit
        }
 
        tableView.setContentOffset(CGPoint(x: 0.0, y: newOffset), animated: false)
    }
 
    private func swapCell(_ i:IndexPath, _ j:IndexPath){
        /*
          swapCell is called by scrollTableAndCell when we change indexPath
          - will move row from source IndexPath -> destination IndexPath
          - hide the cell after swapping
          - swap the items at the array of items
         */
        tableView.beginUpdates()
        tableView.moveRow(at: i, to: j)
        if let currentCell = tableView.cellForRow(at: i) as? TodoCell{
            currentCell.isHidden = true
        }
        let initialIndex = todos.rowNumberToIndex(from: i.row)
        let endIndex = todos.rowNumberToIndex(from: j.row)
        print("Swap from " + String(initialIndex) + " to " + String(endIndex))
        todos.swap(from: initialIndex, to: endIndex)
        ItemRepo.saveIn(moc: moc, todos: todos)
        tableView.endUpdates()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /*
      when dragging is done, animateSnapshotToFinalFrame is called
      to place the dragging cell to its resting positiond (with animation)
     */
    private func animateSnapshotToFinalFrame(_ frame:CGRect) {
        print("Animate")

        let initialIndex = todos.rowNumberToIndex(from: Drag.currentIndexPath!.row)
        var isChanged = false
        let todoItem = todos.getAt(index: initialIndex)
        //        check if done property needs to be changed
        //        we need to change it in the following situations:
        //        A. it is done and the previous one is not done

        if todoItem.isDone() {
            if initialIndex >  1 && todos.getAt(index: initialIndex - 1).isNotDone() {
                todos.getAt(index: initialIndex).setNotDone()
                isChanged = true
                
            }
//        B. it is not done and the next one is done
        }else{
            if initialIndex + 1 < todos.count() && todos.getAt(index: initialIndex + 1).isDone() {
                todos.getAt(index: initialIndex).setDone()
                    isChanged = true
                }
            }

        UIView.animate(withDuration: 0.25, animations: {
            self.draggingCellSnapshot?.transform = CGAffineTransform.identity
            self.draggingCellSnapshot?.frame = frame
            if isChanged{
        }
        }) { (ended) in
            self.tableView.contentInset.top = 0
            self.draggingCellSnapshot!.removeFromSuperview()
            self.draggingCellSnapshot = nil
            self.initialCellToBeDragged.alpha = 1.0
            guard let visibleIndices = self.tableView.indexPathsForVisibleRows else {return}
            self.tableView.beginUpdates()
            self.tableView.reloadRows(at: visibleIndices, with: .none)
            self.tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
    //            reset the top contentInset
            self.tableView.contentInset.top = 0.0
        }
    }
        
    private func update(snapshot:UIView?, with location:CGPoint){
        if snapshot != nil{
            snapshot!.center.x = location.x - Drag.cellOffsetFromCenter.x
            snapshot!.center.y = location.y - Drag.cellOffsetFromCenter.y
        }
    }
}

// MARK: - TableView delegate methods
extension ViewController:  UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todos.count()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell") as! TodoCell
        let todoItem = todos.todos[indexPath.row]

        cell.resetCell()
        cell.delegate = self
        cell.setText(todoItem.getTitle())
        let cellColor = todoItem.isDone() ?  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) : getColor(for: indexPath.row)
            
        cell.setBackground(color: cellColor)

        // set the text attributes accoringly if item is done or not
        if todoItem.isDone() {
            cell.textField.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
            
            // make the text  strikethrough
            let attributedString: NSMutableAttributedString =  NSMutableAttributedString(string: todoItem.getTitle())
            let font = UIFont(name: "Helvetica", size: 17.0)
            attributedString.addAttribute(NSAttributedString.Key.font, value: font!, range: NSMakeRange(0, attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributedString.length))
            cell.textField.text = ""
            cell.textField.attributedText = attributedString
            // we want to disable editing for items that are already done
            cell.textField.isEnabled = false
        }else{
            cell.textField.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            cell.textField.isEnabled = true
        }
        cell.isAlreadyDone = todoItem.isDone()
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return false
    }
    
    // all visible rows were displayed, i.e table.reloadData has finished
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath == tableView.indexPathsForVisibleRows?.last{
            tableView.isScrollEnabled = true
        }
    }
}

//MARK: - ScrollView delegate methods
//Will  use these to detect "pull to add" action
extension ViewController: UIScrollViewDelegate{
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        addPlaceHolderForNewItem()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /*
         1.  scroll offset < 0 --> in dragging  ("pulling") mode.
         3D tranform of the new item placeholder (pull to add..) until it reaches the threshold
         alpha of the transform layer changes gradually until it reaches the threshold
         when threshold is reached text changes from "pull to add new item" to "release to..."
         placeholderViewTop bg = black
         if dragging has ended (scrollViewEndDragging is called):
         - remove the placeholder
         - addingNewItemMode = true
         - call addNewItem
         
         
         2. scroll offset > 0 -> normal mode
         grow the height of the placeholder (hidden behind the blur view) until it reaches the row height
         change the placeholderViewTop bg to the cell that is hiding behind
         
         */
        
        let scrollOffset = scrollView.contentOffset.y
        
        if scrollOffset < 0{ //dragging
            
            // if we are in the midst of a drag & drop operation, exit
            placeHolderViewHeightConstraint.constant = 0.0
            let baseAlpha:CGFloat = 0.2
            let dragPercentage = abs(scrollOffset) < abs(scrollOffsetThreshold) ? scrollOffset/scrollOffsetThreshold : 1.0
            
            // set up the layer
            newItemCellPlaceholder.backgroundColor = colors.first!
            let alpha = baseAlpha + dragPercentage * (1-baseAlpha)
            newItemCellPlaceholder.isHidden = false
            newItemCellPlaceholder.alpha = alpha
            newItemCellPlaceholder.textLabel?.text = dragPercentage < 1 ? "Pull to Create Item" : "Release to Create Item"
            // transformRatio should go from pi/2 to 0
            let transformRatio = CGFloat.pi / 2.0 - (CGFloat.pi / 2.0) * dragPercentage
            if !editingMode {
                newItemCellPlaceholder.layer.transform = CATransform3DMakeRotation(transformRatio, 1, 0, 0)
            }
            
            if scrollOffsetWhenDraggingEnded < scrollOffsetThreshold{
                // if at the moment the dragging ended (user released) the offset passed the threshold we are in adding mode
                
                print("Adding new item")
                scrollOffsetWhenDraggingEnded = 0
                addingNewItemMode = true //will exit only after textField ends editing
                newItemCellPlaceholder.textLabel?.text = ""
                removePlaceHolderForNewItem()
                addNewItem(at: IndexPath(row: 0, section: 0))
            }
        }else if scrollOffset > 0{//normal scrolling
            // grow placeholder' height while scrolling (up to the height of a row)
            placeHolderViewHeightConstraint.constant = scrollOffset < -scrollOffsetThreshold ? scrollOffset : tableView.rowHeight
            placeholderViewTop.backgroundColor = getColorForPlaceHolderTop()
        }else{ // in intial position (not scrolled)
            placeholderViewTop.backgroundColor = .black
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // used to decide if we are going to add a new item (passed the threshold),
        // or just cancel the procedure.
        scrollOffsetWhenDraggingEnded  = scrollView.contentOffset.y
    }
}
    
public extension UIColor {
    /// The RGBA components associated with a `UIColor` instance.
    var components: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let components = self.cgColor.components!
        
        switch components.count == 2 {
        case true : return (r: components[0], g: components[0], b: components[0], a: components[1])
        case false: return (r: components[0], g: components[1], b: components[2], a: components[3])
        }
    }
    
    static func interpolate(from fromColor: UIColor, to toColor: UIColor, with progress: CGFloat) -> UIColor {
        let fromComponents = fromColor.components
        let toComponents = toColor.components

        let r = (1 - progress) * fromComponents.r + progress * toComponents.r
        let g = (1 - progress) * fromComponents.g + progress * toComponents.g
        let b = (1 - progress) * fromComponents.b + progress * toComponents.b
        let a = (1 - progress) * fromComponents.a + progress * toComponents.a

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}


// MARK: - TodoCellDelegate Methods
extension ViewController:TodoCellDelegate{
 
    func todoCellWillModify(cell: TodoCell) {
        /*
             Will do the following:
             1. Block other interactions
             2. Assign the tapGestureRecognizer to the view (tapping will cause editing to finish)
             3. Animate the editing cell to the top of the view
             4. Shade out all other visible cells
         */
        // TODO: - this is called more than once for some reason, not very elegenat way to keep tableViewEditingOffset value
        if editingMode == false {
            // we don't want to keep track of the offset if in adding new item mode
            tableViewEditingOffset = addingNewItemMode ? 0 :  tableView.contentOffset.y
            isAnimating = true
        }
        editingMode = true // block any gestures outside the textField
        editingCell = cell
        print("Editing cell")

        view.addGestureRecognizer(tapGestureRecognizer)
        
        if tableView.indexPath(for: cell) != nil{
            self.tableView.isScrollEnabled = false

            // setup a shading view the 2* height of the visible tableView cell (we won't scroll past that)
            shadingView.alpha = 0.2
            shadingView.backgroundColor = .black
            
            // setup the snapshot cell (going to simulate the editable cell)
            if addingNewItemMode{
                modifyNewCell(cell)
            }else{
                shadingView.frame = CGRect(origin: CGPoint(x: 0, y: tableView.contentOffset.y), size: CGSize(width: tableView.frame.width, height: tableView.frame.height * 2.0))
                tableView.addSubview(shadingView)
                guard let viewOnTop = cell.snapshotView(afterScreenUpdates: false) else {return}
     
                modifyExistingCell(viewOnTop, cell)
            }
        }
    }
    
    fileprivate func modifyNewCell(_ cell: TodoCell) {
        shadingView.frame = CGRect(origin: CGPoint(x: 0, y: tableView.rowHeight), size: CGSize(width: tableView.frame.width, height: tableView.frame.height))
        tableView.addSubview(shadingView)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.shadingView.alpha = 0.7
        }) { (ended) in
            self.shadingView.removeFromSuperview()
            self.shadeAllOtherCellsExcept(cell: cell)
        }
    }
    
    fileprivate func modifyExistingCell(_ viewOnTop: UIView, _ cell: TodoCell) {
        viewOnTop.frame = cell.frame
        tableView.addSubview(viewOnTop)
        
        // setup a huge content inset so we can scroll the selected cell to top in any case
        let contentInset = tableView.visibleSize.height - 40.0
        tableView.contentInset.bottom = contentInset
        
        CATransaction.begin()
        //                get the absolute position of the cell and calculate
        //                the distance to the the top of the table
        let distanceToTop = tableView.convert(cell.frame, to: view).minY - 60
        let currentOffset = tableView.contentOffset.y
        let newOffset = distanceToTop + currentOffset
        view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut ,animations: {
            self.shadingView.alpha = 0.7
            self.tableView.setContentOffset(CGPoint(x: 0.0, y: newOffset), animated: false)
        }) { (ended) in
            self.isAnimating = false
            viewOnTop.removeFromSuperview()
            self.shadeAllOtherCellsExcept(cell: cell)
            self.shadingView.removeFromSuperview()
        }
        
        CATransaction.commit()
    }
    
    
    func todoCellWasModified(cell: TodoCell) {
        updateCellAndReturnToPreviousState(cell: cell)
        print("Cell was modified " + cell.textField.text!)
        
        if let indexPath = tableView.indexPath(for: cell){
            let index = todos.rowNumberToIndex(from: indexPath.row)
            let item = todos.getAt(index: index)
            item.setTitle(title: cell.textField.text)
            ItemRepo.saveIn(moc: moc, todos: todos)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // Only this one is needed to delete the cell (update the model/controller)
    // rest (animation) is handled by the view
    func todoCellWasSetToDeleted(cell: TodoCell) {
        print("to delete")
        if let indexPath = tableView.indexPath(for: cell){
            let index = todos.rowNumberToIndex(from: indexPath.row)
            tableView.performBatchUpdates({
                cell.delegate = nil
                self.todos.remove(at: index)
                ItemRepo.saveIn(moc: moc, todos: todos)
                WidgetCenter.shared.reloadAllTimelines()
                
                tableView.deleteRows(at: [indexPath], with: .left)
            }) { (finished) in
                self.tableView.reloadData()
            }
        }
    }
    
    /*
        the view is responsible for the panning of the cell
        and deciding when the threshold is passed.
        following 2 delegate functions are used for:
          1. returning the color of the next not done cell (while panning is still ongoing)
          2. handle all other stuff when panning has finished
     */
    func todoCellPassedTheDoneThreshold(cell: TodoCell){
        cell.setBackground(color: getNextColor)
    }
    
    /*
        View has detected that the cell was set to done (or reset to not done)
        it animated the cell accordingly and informed the delegate (controller)
        controller will do the following:
          1. find where in the table (model) and table VC the item should be placed
             below the last not done item (if it was set to done) or
             above the first done item (it it was reset to not done
          2. animate the cell to that position (and update the model accordingly) while
          3. changing the bg and text color accordingly.
     */
    func todoCellWasSetToDone(cell: TodoCell) {
        if let sourceIndexPath = tableView.indexPath(for: cell){
            let sourceIndex = self.todos.rowNumberToIndex(from: sourceIndexPath.row)

            // 2. Calculate the destination
            let destinationIndex = todos.getAt(index: sourceIndex).isDone() ? todos.indexOfFirstNotDoneItem :  todos.indexOfLastDoneItem
            let destinationRow = todos.rowNumberToIndex(from: destinationIndex)
            let destinationIndexPath = IndexPath(row: destinationRow, section: 0)

            print("Marked as done from " + String(sourceIndex) + " to " + String(destinationIndex))
            
            // 3. Toggle the done property
            todos.getAt(index: sourceIndex).toggleDone()
            ItemRepo.saveIn(moc: moc, todos: todos)
            
            // 4. Animation - no animation if source == destination
            if destinationIndex != sourceIndex{
                animateCell(destinationIndex, cell, destinationIndexPath, sourceIndexPath, sourceIndex)
            } else{ //source == destination (just update the model)
                tableView.reloadData()
            }
        }
    }
    
    fileprivate func animateCell(_ destinationIndex: Int, _ cell: TodoCell, _ destinationIndexPath: IndexPath, _ sourceIndexPath: IndexPath, _ sourceIndex: Int) {
        // preserve the values of the cell (as a TodoItem) and create the animatedCell
        let originalTodoItem = self.todos.getAt(index: sourceIndex)

        // A. setup the view to animate
        // since we are going to animate bg and text color
        // a snapshot won't do, we need an actual view
        let animatedCell = DummyCell(frame: cell.frame)
        animatedCell.setBackground(color: cell.getBackGroundColor())
        animatedCell.textField.attributedText = cell.textField.attributedText
        animatedCell.textField.textColor = cell.textField.textColor
        tableView.addSubview(animatedCell)
        cell.setBackground(color: .black)
        cell.textField.textColor = .black
        // if the destination it is not visible don't travel the whole distance
        // just one row more than what is visible (avoids animating too quickly)
        var destinationIndexPathForAnimation:IndexPath
        if let visibileIndices = tableView.indexPathsForVisibleRows{
            if visibileIndices.contains(destinationIndexPath) {
                destinationIndexPathForAnimation = destinationIndexPath
            }else{
                if sourceIndexPath.row < destinationIndexPath.row{
                    // destinationIndexPath is below the visible area
                    let last = visibileIndices.last!
                    destinationIndexPathForAnimation = IndexPath(row: last.row +  1, section: 0)
                }else{
                    // destinationIndexPath is above the visible area
                    let first = visibileIndices.first!
                    destinationIndexPathForAnimation = IndexPath(row: first.row - 1, section: 0 )
                }
            }
        }else{
            destinationIndexPathForAnimation = destinationIndexPath
        }
        
        //let destinationFrame = frameForRow(at: destinationIndexPath)
        let destinationFrame = frameForRow(at: destinationIndexPathForAnimation)
        
        // group table update and dummy cell animation together (for animations to be in sync)
        CATransaction.begin()
        // start animation
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: { [weak tableView = self.tableView] in
            animatedCell.frame = destinationFrame
            if self.todos.getAt(index: sourceIndex).isDone() {
                // if item is reset to not done,  bg and text color were previously changed (when threshold was passed). don't animate those
                animatedCell.textField.backgroundColor = .black
                animatedCell.contentView.backgroundColor = .black
                animatedCell.textField.layer.opacity = 0.27 // textColor is not animatable so we will use  opacity to simulate the effect
            }
            
            tableView?.beginUpdates()
            // remove the chosen cell
            self.todos.remove(at: sourceIndex)
            tableView?.deleteRows(at: [sourceIndexPath], with: .none)
            // create a dummy item at destination index (will act as placeholder while animation lasts)
            
            let dummyTodoItemAtDestination = ItemRepo.create()
            self.todos.insert(item: dummyTodoItemAtDestination, at: destinationIndex)
            tableView?.insertRows(at: [destinationIndexPath], with: .middle)
            tableView?.endUpdates()
            
        }) { (finished) in
            self.tableView.beginUpdates()
            // swap the dummyItem with the selected item
            self.todos.remove(at: destinationIndex)
            self.tableView.deleteRows(at: [destinationIndexPath], with: .none)
            self.todos.insert(item: originalTodoItem, at: destinationIndex)
            ItemRepo.saveIn(moc: self.moc, todos: self.todos)
        
            self.tableView.insertRows(at: [destinationIndexPath], with: .none)
            self.tableView.endUpdates()
            // reload only the row at the destination, for the rest just update the bg color
            self.tableView.reloadRows(at: [destinationIndexPath], with: .none)
            self.updateColors()
            animatedCell.layer.isHidden = true
            animatedCell.removeFromSuperview()
            cell.removeFromSuperview()
            self.view.layoutIfNeeded()
        }
        CATransaction.commit()
    }
}
