//
//  TabViewController.swift
//  Racecar
//
//  Created by Taylor McIntyre on 2020-02-02.
//  Copyright © 2020 Taylor McIntyre. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let action = ActionViewController()
        let connect = ConnectionViewController()
        
        viewControllers = [action, connect].map(UINavigationController.init)
    }
}
