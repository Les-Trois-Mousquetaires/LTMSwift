//
//  EqualCellSpaceFlowLayout.swift
//  FBSnapshotTestCase
//
//  Created by 柯南 on 2022/11/30.
//

import Foundation
public enum AlignType : NSInteger {
    case left = 0
    case center = 1
    case right = 2
}

public class EqualCellSpaceFlowLayout: UICollectionViewFlowLayout {
    //两个Cell之间的距离
    private var itemSpace : CGFloat{
        didSet{
            self.minimumInteritemSpacing = itemSpace
        }
    }
    //cell对齐方式
    private var alignType : AlignType = AlignType.center
    //在居中对齐的时候需要知道这行所有cell的宽度总和
    public var cellWidthInLine : CGFloat = 0.0
    
    override init() {
        itemSpace = 10.0
        super.init()
        scrollDirection = UICollectionView.ScrollDirection.vertical
        estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    public convenience init(_ cellType:AlignType){
        self.init()
        self.alignType = cellType
    }
    public convenience init(_ cellType: AlignType, _ itemSpace: CGFloat){
        self.init()
        self.alignType = cellType
        self.itemSpace = itemSpace
    }
    
    required init?(coder aDecoder: NSCoder) {
        itemSpace = 10.0
        super.init(coder: aDecoder)
        scrollDirection = UICollectionView.ScrollDirection.vertical
        sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        let layoutAttributes_super : [UICollectionViewLayoutAttributes] = super.layoutAttributesForElements(in: rect) ?? [UICollectionViewLayoutAttributes]()
        let layoutAttributes:[UICollectionViewLayoutAttributes] = NSArray(array: layoutAttributes_super, copyItems:true)as! [UICollectionViewLayoutAttributes]
        var layoutAttributes_t : [UICollectionViewLayoutAttributes] = [UICollectionViewLayoutAttributes]()
        for index in 0..<layoutAttributes.count{
            
//            print("index in 0..<layoutAttributes.count ==============")
            
            let currentAttr = layoutAttributes[index]
            let previousAttr = index == 0 ? nil : layoutAttributes[index-1]
            let nextAttr = index + 1 == layoutAttributes.count ?
                nil : layoutAttributes[index+1]
            
            layoutAttributes_t.append(currentAttr)
            cellWidthInLine += currentAttr.frame.size.width
            
            let previousY :CGFloat = previousAttr == nil ? 0 : previousAttr!.frame.maxY
            let currentY :CGFloat = currentAttr.frame.maxY
            let nextY:CGFloat = nextAttr == nil ? 0 : nextAttr!.frame.maxY
            
            if currentY != previousY && currentY != nextY{
                if currentAttr.representedElementKind == UICollectionView.elementKindSectionHeader{
                    layoutAttributes_t.removeAll()
                    cellWidthInLine = 0.0
//                    print("currentAttr.representedElementKind == UICollectionView.elementKindSectionHeader =========== Header")
                }else if currentAttr.representedElementKind == UICollectionView.elementKindSectionFooter{
                    layoutAttributes_t.removeAll()
                    cellWidthInLine = 0.0
//                    print("currentAttr.representedElementKind == UICollectionView.elementKindSectionFooter ============ Footer")
                }else{
                    self.setCellFrame(with: layoutAttributes_t)
                    layoutAttributes_t.removeAll()
                    cellWidthInLine = 0.0
//                    print("currentY != previousY && currentY != nextY ============== Item")
                }
            } else if currentY != nextY { //这里currentY == previousY 说明和上一个项目在同一行，currentY != nextY说明下一个项目要换行了，这种情况直接计算本行的对齐方式
                self.setCellFrame(with: layoutAttributes_t)
                layoutAttributes_t.removeAll()
                cellWidthInLine = 0.0
//                print("currentY != nextY ======== Else")
            }
        }
        return layoutAttributes
    }
    
    /// 调整Cell的Frame
    ///
    /// - Parameter layoutAttributes: layoutAttribute 数组
    func setCellFrame(with layoutAttributes : [UICollectionViewLayoutAttributes]){
        var nowWidth : CGFloat = 0.0
        switch alignType {
        case AlignType.left:
            nowWidth = self.sectionInset.left
            for attributes in layoutAttributes {
                var nowFrame = attributes.frame
                nowFrame.origin.x = nowWidth
                attributes.frame = nowFrame
                nowWidth += nowFrame.size.width + self.itemSpace
            }
            break;
        case AlignType.center:
            nowWidth = (self.collectionView!.frame.size.width - cellWidthInLine - (CGFloat(layoutAttributes.count - 1) * itemSpace)) / 2
            for attributes in layoutAttributes{
                var nowFrame = attributes.frame
                nowFrame.origin.x = nowWidth
                attributes.frame = nowFrame
                nowWidth += nowFrame.size.width + self.itemSpace
            }
            break;
        case AlignType.right:
            nowWidth = self.collectionView!.frame.size.width - self.sectionInset.right
            let count = layoutAttributes.count
            for var index in 0 ..< count {
                index = count - 1 - index
                let attributes = layoutAttributes[index]
                var nowFrame = attributes.frame
                let nowItemWidth = nowFrame.size.width
                nowFrame.origin.x = nowWidth - nowItemWidth
                attributes.frame = nowFrame
                nowWidth = nowWidth - nowItemWidth - itemSpace
            }
            break;
        }
    }
}
