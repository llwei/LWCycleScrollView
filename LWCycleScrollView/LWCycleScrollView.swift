//
//  LWCycleScrollView.swift
//  LWCycleScrollView
//
//  Created by lailingwei on 16/5/13.
//  Copyright © 2016年 lailingwei. All rights reserved.
//
//  Github: https://github.com/llwei/LWCycleScrollView

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



private let CellIdentifier = "LWCycleCollectionViewCell"

private let AutoScrollTimeInterval: TimeInterval = 5.0                                  // 修改定时器触发时间
private let CountScale: Int = 5000
private let TitleFontSize: CGFloat = 14                                                 // 修改文字大小
private let TitleColor: UIColor = UIColor.white                                         // 修改文字颜色
private let IndicatorHeight: CGFloat = 20                                               // 修改底部指示器视图高度
private let IndicatorBgColor: UIColor = UIColor.black.withAlphaComponent(0.4)           // 修改底部指示器视图背景颜色
private let CurrentPageIndicatorTintColor: UIColor = UIColor.groupTableViewBackground    
private let PageIndicatorTintColor: UIColor = UIColor.lightGray


typealias LWCycleScrollViewDidSelectedHandler = ((_ index: Int, _ image: UIImage?) -> Void)


@objc enum LWCycleScrollViewPageContrlAlignment: Int {
    case center = 0
    case left   = 1
    case right  = 2
}


// MARK: - LWCycleScrollView

class LWCycleScrollView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
    
    fileprivate var collectionView: UICollectionView!
    fileprivate var indicatorView = UIView()
    fileprivate var pageControl = UIPageControl()
    fileprivate var leftTitleLabel = UILabel()
    fileprivate var rightTitleLabel = UILabel()
    fileprivate var timer: Timer?
    
    fileprivate var placeholderImage: UIImage?
    fileprivate var titles: [String]?
    fileprivate var images: [UIImage]? {
        didSet {
            self.totalItemCount = (images?.count ?? 0) * CountScale
            self.pageControl.numberOfPages = images?.count ?? 0
        }
    }
    fileprivate var imageURLs: [String]? {
        didSet {
            self.totalItemCount = (imageURLs?.count ?? 0) * CountScale
            self.pageControl.numberOfPages = imageURLs?.count ?? 0
        }
    }
    
    fileprivate var totalItemCount: Int = 0
    fileprivate var pageContrlAlignment: LWCycleScrollViewPageContrlAlignment = .center {
        didSet {
            switch pageContrlAlignment {
            case .center:
                self.leftTitleLabel.text = nil
                self.rightTitleLabel.text = nil
                self.pageControl.setContentHuggingPriority(249, for: .horizontal)
                self.leftTitleLabel.setContentHuggingPriority(250, for: .horizontal)
                self.rightTitleLabel.setContentHuggingPriority(250, for: .horizontal)
            case .left:
                self.leftTitleLabel.text = nil
                self.rightTitleLabel.text = titles?.first
                self.pageControl.setContentCompressionResistancePriority(751, for: .horizontal)
                self.leftTitleLabel.setContentHuggingPriority(250, for: .horizontal)
                self.rightTitleLabel.setContentHuggingPriority(249, for: .horizontal)
            case .right:
                self.leftTitleLabel.text = titles?.first
                self.rightTitleLabel.text = nil
                self.pageControl.setContentCompressionResistancePriority(751, for: .horizontal)
                self.leftTitleLabel.setContentHuggingPriority(249, for: .horizontal)
                self.rightTitleLabel.setContentHuggingPriority(250, for: .horizontal)
            }
        }
    }
    
    fileprivate var didSelectedHandler: LWCycleScrollViewDidSelectedHandler?
    
    
    // MARK: - Initial
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupCollectionView()
        setupIndicatorView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupCollectionView()
        setupIndicatorView()
    }
    
    
    fileprivate func setupCollectionView() {
        // UICollectionViewFlowLayout
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = frame.size
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .horizontal
        
        // UICollectionView
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = UIColor.lightGray
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(LWCycleScrollViewCell.self, forCellWithReuseIdentifier: CellIdentifier)
        addSubview(collectionView)
        
        // Add Constraints
        addCollectionViewConstraints()
    }
    
    
    fileprivate func setupIndicatorView() {
        
        indicatorView.backgroundColor = IndicatorBgColor
        addSubview(indicatorView)
        
        // TitleLabel
        leftTitleLabel.backgroundColor = UIColor.clear
        leftTitleLabel.font = UIFont.boldSystemFont(ofSize: TitleFontSize)
        leftTitleLabel.textColor = TitleColor
        indicatorView.addSubview(leftTitleLabel)
        
        rightTitleLabel.backgroundColor = UIColor.clear
        rightTitleLabel.font = UIFont.boldSystemFont(ofSize: TitleFontSize)
        rightTitleLabel.textColor = TitleColor
        indicatorView.addSubview(rightTitleLabel)
        
        // PageControl
        pageControl.backgroundColor = UIColor.clear
        pageControl.currentPageIndicatorTintColor = CurrentPageIndicatorTintColor
        pageControl.pageIndicatorTintColor = PageIndicatorTintColor
        indicatorView.addSubview(pageControl)
        
        // Add Constraints
        addIndicatorViewConstraints()
    }
    
    
    fileprivate func resetShow() {
        
        collectionView.reloadData()
        
        invalidateTimer()
        setupTimer()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(NSEC_PER_SEC) / 10) / Double(NSEC_PER_SEC)) {
            let resourceCount = self.totalItemCount / CountScale
            self.collectionView.scrollToItem(at: IndexPath(item: resourceCount * Int(CountScale / 2), section: 0),
                                                        at: UICollectionViewScrollPosition(),
                                                        animated: false)
            self.showContent(atIndex: 0)
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if superview == nil {
            invalidateTimer()
        }
    }
    
    deinit {
        print("\(NSStringFromClass(LWCycleScrollView.self)).deinit")
    }
    
    
    // MARK: - Layout
    
    fileprivate func addCollectionViewConstraints() {
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        let horiConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[collectionView]|",
                                                                             options: NSLayoutFormatOptions(),
                                                                             metrics: nil,
                                                                             views: ["collectionView" : collectionView])
        let vertiConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[collectionView]|",
                                                                              options: NSLayoutFormatOptions(),
                                                                              metrics: nil,
                                                                              views: ["collectionView" : collectionView])
        if #available(iOS 8.0, *) {
            NSLayoutConstraint.activate(horiConstraints)
            NSLayoutConstraint.activate(vertiConstraints)
        } else {
            addConstraints(horiConstraints)
            addConstraints(vertiConstraints)
        }
    }
    
    fileprivate func addIndicatorViewConstraints() {
        
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        leftTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        rightTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let indicatorHoriConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[indicatorView]|",
                                                                                      options: NSLayoutFormatOptions(),
                                                                                      metrics: nil,
                                                                                      views: ["indicatorView" : indicatorView])
        
        let indicatorVertiConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[indicatorView(==IndicatorHeight)]|",
                                                                                       options: NSLayoutFormatOptions(),
                                                                                       metrics: ["IndicatorHeight" : IndicatorHeight],
                                                                                       views: ["indicatorView" : indicatorView])
        
        let horiConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[leftTitleLabel]-8-[pageControl]-8-[rightTitleLabel]-8-|",
                                                                             options: NSLayoutFormatOptions(),
                                                                             metrics: ["8" : 8],
                                                                             views: [
                                                                                "leftTitleLabel" : leftTitleLabel,
                                                                                "pageControl" : pageControl,
                                                                                "rightTitleLabel" : rightTitleLabel])
        
        let leftTitleVertConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[leftTitleLabel]|",
                                                                                      options: NSLayoutFormatOptions(),
                                                                                      metrics: nil,
                                                                                      views: ["leftTitleLabel" : leftTitleLabel])
        
        let pageVertConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[pageControl]|",
                                                                                 options: NSLayoutFormatOptions(),
                                                                                 metrics: nil,
                                                                                 views: ["pageControl" : pageControl])
        
        let rightTitleVertConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[rightTitleLabel]|",
                                                                                       options: NSLayoutFormatOptions(),
                                                                                       metrics: nil,
                                                                                       views: ["rightTitleLabel" : rightTitleLabel])
        
        if #available(iOS 8.0, *) {
            NSLayoutConstraint.activate(indicatorHoriConstraints)
            NSLayoutConstraint.activate(indicatorVertiConstraints)
            NSLayoutConstraint.activate(horiConstraints)
            NSLayoutConstraint.activate(leftTitleVertConstraints)
            NSLayoutConstraint.activate(pageVertConstraints)
            NSLayoutConstraint.activate(rightTitleVertConstraints)
            
        } else {
            addConstraints(indicatorHoriConstraints)
            addConstraints(indicatorVertiConstraints)
            indicatorView.addConstraints(horiConstraints)
            indicatorView.addConstraints(leftTitleVertConstraints)
            indicatorView.addConstraints(pageVertConstraints)
            indicatorView.addConstraints(rightTitleVertConstraints)
            
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        flowLayout?.itemSize = frame.size
    }
    
    
    // MARK: - Helper methods
    
    
    fileprivate func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    fileprivate func setupTimer() {
        
        timer = Timer.scheduledTimer(timeInterval: AutoScrollTimeInterval,
                                                       target: self,
                                                       selector: #selector(LWCycleScrollView.timerAction),
                                                       userInfo: nil,
                                                       repeats: true)
    }
    
    func timerAction() {
        guard totalItemCount > 0 else {
            print("轮播图数量为0")
            invalidateTimer()
            return
        }
        
        let resourceCount = totalItemCount / CountScale
        let currentIndex = Int(collectionView.contentOffset.x / collectionView.bounds.size.width)
        let targetIndex = currentIndex + 1
        
        collectionView.scrollToItem(at: IndexPath(item: targetIndex, section: 0),
                                               at: UICollectionViewScrollPosition(),
                                               animated: true)
        
        showContent(atIndex: targetIndex % resourceCount)
    }
    
    
    /**显示对于下标的内容*/
    fileprivate func showContent(atIndex index: Int) {
        
        pageControl.currentPage = index
        
        switch pageContrlAlignment {
        case .center:
            break
        case .left:
            if titles?.count > index {
                rightTitleLabel.text = titles?[index]
            }
        case .right:
            if titles?.count > index {
                leftTitleLabel.text = titles?[index]
            }
        }
    }
    
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalItemCount
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as! LWCycleScrollViewCell
        
        let resourceCount = totalItemCount / CountScale
        let itemIndex = (indexPath as NSIndexPath).item % resourceCount
        
        // Fill content
        if let image = images?[itemIndex] {
            cell.imageView.image = image
        } else if let imageURL = imageURLs?[itemIndex] {
            // TODO: - 导入SDWebImage
            if let image = placeholderImage {
                cell.imageView.sd_setImage(with: URL(string: imageURL), placeholderImage: image)
            } else {
                cell.imageView.sd_setImage(with: URL(string: imageURL))
            }
        } else {
            cell.imageView.image = placeholderImage
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let resourceCount = totalItemCount / CountScale
        let itemIndex = (indexPath as NSIndexPath).item % resourceCount
        
        let cell = collectionView.cellForItem(at: indexPath) as! LWCycleScrollViewCell
        
        didSelectedHandler?(itemIndex, cell.imageView.image)
    }
    
    
    
    // MARK: - UIScrollView delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let currentIndex = Int(scrollView.contentOffset.x / scrollView.bounds.size.width)
        guard currentIndex == totalItemCount - 1 else {
            return
        }
        
        let resourceCount = totalItemCount / CountScale
        collectionView.scrollToItem(at: IndexPath(item: currentIndex % resourceCount + (resourceCount * Int(CountScale / 2)), section: 0),
                                               at: UICollectionViewScrollPosition(),
                                               animated: false)

    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        invalidateTimer()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let resourceCount = totalItemCount / CountScale
        let itemIndex = Int(scrollView.contentOffset.x / scrollView.bounds.size.width) % resourceCount
        
        showContent(atIndex: itemIndex)
        setupTimer()
    }
    
    
    
}


// MARK: - Public methods

extension LWCycleScrollView {
    
    /**
     通过本地图片数组更新轮播图
     
     - parameter images:          本地图片数组
     - parameter titles:          标题数组
     - parameter alignment:       pageControl位置
     - parameter selectedHandler: 回调
     */
    func show(images: [UIImage],
                     titles: [String]?,
                     alignment: LWCycleScrollViewPageContrlAlignment,
                     selectedHandler: LWCycleScrollViewDidSelectedHandler?) {
    
        self.images = images
        self.titles = titles
        self.pageContrlAlignment = alignment
        didSelectedHandler = selectedHandler
        
        resetShow()
    }
    
    
    /**
     通过urls地址数组更新轮播图
     
     - parameter imageURLs:        urls地址数组
     - parameter titles:           标题数组
     - parameter placeholderImage: 占位图
     - parameter alignment:        pageControl位置
     - parameter selectedHandler:  回调
     */
    func show(imageURLs: [String],
                        titles: [String]?,
                        placeholderImage: UIImage?,
                        alignment: LWCycleScrollViewPageContrlAlignment,
                        selectedHandler: LWCycleScrollViewDidSelectedHandler?) {
        
        self.imageURLs = imageURLs
        self.titles = titles
        self.placeholderImage = placeholderImage
        self.pageContrlAlignment = alignment
        didSelectedHandler = selectedHandler
        
        resetShow()
    }
    
    
}



// MARK: - LWCycleScrollViewCell

class LWCycleScrollViewCell: UICollectionViewCell {
    
    var imageView = UIImageView(frame: CGRect.zero)
    
    // MARK: - Initial
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupSubViews() {
        // ImageView
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        // Add Constraints
        addConstraints()
    }
    
    fileprivate func addConstraints() {
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let imgHoriConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[imageView]|",
                                                                                options: NSLayoutFormatOptions(),
                                                                                metrics: nil,
                                                                                views: ["imageView" : imageView])
        let imgVertiConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[imageView]|",
                                                                                 options: NSLayoutFormatOptions(),
                                                                                 metrics: nil,
                                                                                 views: ["imageView" : imageView])
        if #available(iOS 8.0, *) {
            NSLayoutConstraint.activate(imgHoriConstraints)
            NSLayoutConstraint.activate(imgVertiConstraints)
        } else {
            contentView.addConstraints(imgHoriConstraints)
            contentView.addConstraints(imgVertiConstraints)
        }
    }
    
    
}












