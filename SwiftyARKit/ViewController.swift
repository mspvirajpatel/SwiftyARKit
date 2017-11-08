//
//  ViewController.swift
//  SwiftyARKit
//
//  Created by Viraj Patel on 07/11/17.
//  Copyright © 2017 Viraj Patel. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var myLable: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myLable.font = myLable.font.withTraits(traits: .traitBold)
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
