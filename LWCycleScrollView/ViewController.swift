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
    @IBOutlet weak var bannerView2: LWCycleScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // 通过本地图片数组更新轮播图
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
        
        
        // 通过urls地址数组更新轮播图
        let placeHolderImage = UIImage(named: "buildings")
        let imageURLs = ["http://img1.3lian.com/img13/c3/10/d/34.jpg",
                         "http://rescdn.qqmail.com/dyimg/20140516/7E079BD74EF3.jpg",
                         "http://img3.3lian.com/2013/c2/64/d/73.jpg"]
        bannerView2.show(imageURLs: imageURLs,
                         titles: nil,
                         placeholderImage: placeHolderImage,
                         alignment: .Left) { (index) in
                            print(index)
        }
        
    }

    deinit {
        print("\(NSStringFromClass(ViewController.self)).deinit")
    }
    
    
}

