//
//  TableViewCell.swift
//  auditorytesting
//
//  Created by Adam Krekorian on 4/1/21.
//  Copyright © 2021 Adam Krekorian. All rights reserved.
//

import UIKit

class customSoundCell: UITableViewCell {

    
    @IBOutlet weak var soundId: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
