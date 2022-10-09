//
//  DummyCell.swift
//  klear-1
//
//  Created by Yorwos Pallikaropoulos on 2/15/20.
//  Copyright © 2020 Yorwos Pallikaropoulos. All rights reserved.
//

import UIKit

class DummyCell: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var textField: UITextField!
    
    override init(frame:CGRect){
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupView(){
        Bundle.main.loadNibNamed("DummyCell", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
    }
        
    func setBackground(color: UIColor){        
        self.textField.backgroundColor = color
        self.contentView.backgroundColor = color
    }
}
