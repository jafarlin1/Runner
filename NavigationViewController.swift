//
//  NavigationViewController.swift
//  Runner
//
//  Created by JafarLin on 2023/6/9.
//  Copyright © 2023 John Kuhn. All rights reserved.
//

import UIKit

class NavigationViewController: UINavigationController {
    
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        topViewController?.supportedInterfaceOrientations ?? .all
        
        /*
         // MARK: - Navigation
         
         // In a storyboard-based application, you will often want to do a little preparation before navigation
         override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
         }
         */
        
    }
}
