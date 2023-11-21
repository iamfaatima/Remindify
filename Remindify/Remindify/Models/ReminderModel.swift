//
//  ReminderModel.swift
//  Remindify
//
//  Created by Dev on 06/11/2023.
//

import Foundation
import UIKit

struct ReminderModel{
    var opened : Bool = false // for cell
    var title : String?
    var description : String?
    var date : String?
    var documentID : String? //see if it can be removed
    var ownerId : String?
}
