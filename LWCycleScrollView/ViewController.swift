//
//  ViewController.swift
//  LWCycleScrollView
//
//  Created by lailingwei on 16/5/13.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var bannerView1: LWCycleScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let placeHolderImage = UIImage(named: "buildings")
        var images = [UIImage]()
        var titles = [String]()
        for i in 1...4 {
            images.append(UIImage(named: "h" + "\(i).jpg")!)
            titles.append("dengmayixyjjjghffghgjhgkgyuiga" + "\(i)")
        }

        bannerView1.show(images: images,
                         titles: titles,
                         alignment: .Right) { (index) in
                            print(index)
                            
        }
        
    }


}

