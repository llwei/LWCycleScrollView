//
//  LWCycleScrollView.swift
//  LWCycleScrollView
//
//  Created by lailingwei on 16/5/13.
//  Copyright © 2016年 lailingwei. All rights reserved.
//
//  Github: https://github.com/llwei/LWCycleScrollView

import UIKit


private let CellIdentifier = "LWCycleCollectionViewCell"

private let AutoScrollTimeInterval: NSTimeInterval = 5.0                                        // 修改定时器触发时间
private let CountScale: Int = 5000
private let TitleFontSize: CGFloat = 14                                                         // 修改文字大小
private let TitleColor: UIColor = UIColor.whiteColor()                                          // 修改文字颜色
private let IndicatorHeight: CGFloat = 20                                                       // 修改底部指示器视图高度
private let IndicatorBgColor: UIColor = UIColor.blackColor().colorWithAlphaComponent(0.4)       // 修改底部指示器视图背景颜色
private let CurrentPageIndicatorTintColor: UIColor = UIColor.groupTableViewBackgroundColor()    
private let PageIndicatorTintColor: UIColor = UIColor.lightGrayColor()


typealias LWCycleScrollViewDidSelectedHandler = ((index: Int, image: UIImage?) -> Void)


@objc enum LWCycleScrollViewPageContrlAlignment: Int {
    case Center = 0
    case Left   = 1
    case Right  = 2
}


// MARK: - LWCycleScrollView

class LWCycleScrollView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
    
    private var collectionView: UICollectionView!
    private var indicatorView = UIView()
    private var pageControl = UIPageControl()
    private var leftTitleLabel = UILabel()
    private var rightTitleLabel = UILabel()
    private var timer: NSTimer?
    
    private var placeholderImage: UIImage?
    private var titles: [String]?
    private var images: [UIImage]? {
        didSet {
            self.totalItemCount = (images?.count ?? 0) * CountScale
            self.pageControl.numberOfPages = images?.count ?? 0
        }
    }
    private var imageURLs: [String]? {
        didSet {
            self.totalItemCount = (imageURLs?.count ?? 0) * CountScale
            self.pageControl.numberOfPages = imageURLs?.count ?? 0
        }
    }
    
    private var totalItemCount: Int = 0
    private var pageContrlAlignment: LWCycleScrollViewPageContrlAlignment = .Center {
        didSet {
            switch pageContrlAlignment {
            case .Center:
                self.leftTitleLabel.text = nil
                self.rightTitleLabel.text = nil
                self.pageControl.setContentHuggingPriority(249, forAxis: .Horizontal)
                self.leftTitleLabel.setContentHuggingPriority(250, forAxis: .Horizontal)
                self.rightTitleLabel.setContentHuggingPriority(250, forAxis: .Horizontal)
            case .Left:
                self.leftTitleLabel.text = nil
                self.rightTitleLabel.text = titles?.first
                self.pageControl.setContentCompressionResistancePriority(751, forAxis: .Horizontal)
                self.leftTitleLabel.setContentHuggingPriority(250, forAxis: .Horizontal)
                self.rightTitleLabel.setContentHuggingPriority(249, forAxis: .Horizontal)
            case .Right:
                self.leftTitleLabel.text = titles?.first
                self.rightTitleLabel.text = nil
                self.pageControl.setContentCompressionResistancePriority(751, forAxis: .Horizontal)
                self.leftTitleLabel.setContentHuggingPriority(249, forAxis: .Horizontal)
                self.rightTitleLabel.setContentHuggingPriority(250, forAxis: .Horizontal)
            }
        }
    }
    
    private var didSelectedHandler: LWCycleScrollViewDidSelectedHandler?
    
    
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
    
    
    private func setupCollectionView() {
        // UICollectionViewFlowLayout
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = frame.size
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .Horizontal
        
        // UICollectionView
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = UIColor.lightGrayColor()
        collectionView.pagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerClass(LWCycleScrollViewCell.self, forCellWithReuseIdentifier: CellIdentifier)
        addSubview(collectionView)
        
        // Add Constraints
        addCollectionViewConstraints()
    }
    
    
    private func setupIndicatorView() {
        
        indicatorView.backgroundColor = IndicatorBgColor
        addSubview(indicatorView)
        
        // TitleLabel
        leftTitleLabel.backgroundColor = UIColor.clearColor()
        leftTitleLabel.font = UIFont.boldSystemFontOfSize(TitleFontSize)
        leftTitleLabel.textColor = TitleColor
        indicatorView.addSubview(leftTitleLabel)
        
        rightTitleLabel.backgroundColor = UIColor.clearColor()
        rightTitleLabel.font = UIFont.boldSystemFontOfSize(TitleFontSize)
        rightTitleLabel.textColor = TitleColor
        indicatorView.addSubview(rightTitleLabel)
        
        // PageControl
        pageControl.backgroundColor = UIColor.clearColor()
        pageControl.currentPageIndicatorTintColor = CurrentPageIndicatorTintColor
        pageControl.pageIndicatorTintColor = PageIndicatorTintColor
        indicatorView.addSubview(pageControl)
        
        // Add Constraints
        addIndicatorViewConstraints()
    }
    
    
    private func resetShow() {
        
        collectionView.reloadData()
        
        invalidateTimer()
        setupTimer()
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) / 10), dispatch_get_main_queue()) {
            let resourceCount = self.totalItemCount / CountScale
            self.collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: resourceCount * Int(CountScale / 2), inSection: 0),
                                                        atScrollPosition: .None,
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
    
    private func addCollectionViewConstraints() {
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        let horiConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[collectionView]|",
                                                                             options: .DirectionLeadingToTrailing,
                                                                             metrics: nil,
                                                                             views: ["collectionView" : collectionView])
        let vertiConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[collectionView]|",
                                                                              options: .DirectionLeadingToTrailing,
                                                                              metrics: nil,
                                                                              views: ["collectionView" : collectionView])
        if #available(iOS 8.0, *) {
            NSLayoutConstraint.activateConstraints(horiConstraints)
            NSLayoutConstraint.activateConstraints(vertiConstraints)
        } else {
            addConstraints(horiConstraints)
            addConstraints(vertiConstraints)
        }
    }
    
    private func addIndicatorViewConstraints() {
        
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        leftTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        rightTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let indicatorHoriConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[indicatorView]|",
                                                                                      options: .DirectionLeadingToTrailing,
                                                                                      metrics: nil,
                                                                                      views: ["indicatorView" : indicatorView])
        
        let indicatorVertiConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[indicatorView(==IndicatorHeight)]|",
                                                                                       options: .DirectionLeadingToTrailing,
                                                                                       metrics: ["IndicatorHeight" : IndicatorHeight],
                                                                                       views: ["indicatorView" : indicatorView])
        
        let horiConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-8-[leftTitleLabel]-8-[pageControl]-8-[rightTitleLabel]-8-|",
                                                                             options: .DirectionLeadingToTrailing,
                                                                             metrics: ["8" : 8],
                                                                             views: [
                                                                                "leftTitleLabel" : leftTitleLabel,
                                                                                "pageControl" : pageControl,
                                                                                "rightTitleLabel" : rightTitleLabel])
        
        let leftTitleVertConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[leftTitleLabel]|",
                                                                                      options: .DirectionLeadingToTrailing,
                                                                                      metrics: nil,
                                                                                      views: ["leftTitleLabel" : leftTitleLabel])
        
        let pageVertConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[pageControl]|",
                                                                                 options: .DirectionLeadingToTrailing,
                                                                                 metrics: nil,
                                                                                 views: ["pageControl" : pageControl])
        
        let rightTitleVertConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[rightTitleLabel]|",
                                                                                       options: .DirectionLeadingToTrailing,
                                                                                       metrics: nil,
                                                                                       views: ["rightTitleLabel" : rightTitleLabel])
        
        if #available(iOS 8.0, *) {
            NSLayoutConstraint.activateConstraints(indicatorHoriConstraints)
            NSLayoutConstraint.activateConstraints(indicatorVertiConstraints)
            NSLayoutConstraint.activateConstraints(horiConstraints)
            NSLayoutConstraint.activateConstraints(leftTitleVertConstraints)
            NSLayoutConstraint.activateConstraints(pageVertConstraints)
            NSLayoutConstraint.activateConstraints(rightTitleVertConstraints)
            
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
    
    
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func setupTimer() {
        
        timer = NSTimer.scheduledTimerWithTimeInterval(AutoScrollTimeInterval,
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
        
        collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: targetIndex, inSection: 0),
                                               atScrollPosition: .None,
                                               animated: true)
        
        showContent(atIndex: targetIndex % resourceCount)
    }
    
    
    /**显示对于下标的内容*/
    private func showContent(atIndex index: Int) {
        
        pageControl.currentPage = index
        
        switch pageContrlAlignment {
        case .Center:
            break
        case .Left:
            if titles?.count > index {
                rightTitleLabel.text = titles?[index]
            }
        case .Right:
            if titles?.count > index {
                leftTitleLabel.text = titles?[index]
            }
        }
    }
    
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalItemCount
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! LWCycleScrollViewCell
        
        let resourceCount = totalItemCount / CountScale
        let itemIndex = indexPath.item % resourceCount
        
        // Fill content
        if let image = images?[itemIndex] {
            cell.imageView.image = image
        } else if let imageURL = imageURLs?[itemIndex] {
            // TODO: - 导入SDWebImage
            if let image = placeholderImage {
                cell.imageView.sd_setImageWithURL(NSURL(string: imageURL ?? ""), placeholderImage: image)
            } else {
                cell.imageView.sd_setImageWithURL(NSURL(string: imageURL ?? ""))
            }
        } else {
            cell.imageView.image = placeholderImage
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let resourceCount = totalItemCount / CountScale
        let itemIndex = indexPath.item % resourceCount
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! LWCycleScrollViewCell
        
        didSelectedHandler?(index: itemIndex, image: cell.imageView.image)
    }
    
    
    
    // MARK: - UIScrollView delegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        let currentIndex = Int(scrollView.contentOffset.x / scrollView.bounds.size.width)
        guard currentIndex == totalItemCount - 1 else {
            return
        }
        
        let resourceCount = totalItemCount / CountScale
        collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: currentIndex % resourceCount + (resourceCount * Int(CountScale / 2)), inSection: 0),
                                               atScrollPosition: .None,
                                               animated: false)

    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        invalidateTimer()
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
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
    func show(images images: [UIImage],
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
    func show(imageURLs imageURLs: [String],
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
    
    var imageView = UIImageView(frame: CGRectZero)
    
    // MARK: - Initial
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubViews() {
        // ImageView
        imageView.userInteractionEnabled = true
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        // Add Constraints
        addConstraints()
    }
    
    private func addConstraints() {
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let imgHoriConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[imageView]|",
                                                                                options: .DirectionLeadingToTrailing,
                                                                                metrics: nil,
                                                                                views: ["imageView" : imageView])
        let imgVertiConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[imageView]|",
                                                                                 options: .DirectionLeadingToTrailing,
                                                                                 metrics: nil,
                                                                                 views: ["imageView" : imageView])
        if #available(iOS 8.0, *) {
            NSLayoutConstraint.activateConstraints(imgHoriConstraints)
            NSLayoutConstraint.activateConstraints(imgVertiConstraints)
        } else {
            contentView.addConstraints(imgHoriConstraints)
            contentView.addConstraints(imgVertiConstraints)
        }
    }
    
    
}












