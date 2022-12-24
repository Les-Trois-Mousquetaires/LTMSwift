//
//  PopVC.swift
//  FBSnapshotTestCase
//
//  Created by 柯南 on 2022/11/30.
//

import Foundation
public class PopVC: NSObject {
    
    public enum PopType {
        // 居左
        case left
        // 居友
        case right
        // 居顶
        case top
        // 居底
        case bottom
        // 居中
        case center
    }
    
    /**
     视图弹回
     
     - parameter view 被弹回视图
     */
    public class func dismiss(view: UIView) {
        view.popupView()?.dismiss(animated: true, completion: nil)
    }
    
    /**
     视图弹出
     
     - parameter view 被弹出视图
     - parameter poptype 弹出方式
     - parameter space 间距
     */
    public class func popView(view: UIView, poptype: PopType, space: CGFloat? = 0) {
        var layout: BaseAnimator.Layout
        var animator: PopupViewAnimator
        switch poptype {
        case .left:
            layout = .trailing(.init(trailingMargin: space!))
            animator =  RightwardAnimator(layout: layout)
        case .right:
            layout = .leading(.init(leadingMargin: space!))
            animator = LeftwardAnimator(layout: layout)
        case .top:
            layout = .top(.init(topMargin: space!))
            animator = DownwardAnimator(layout: layout)
        case .bottom:
            layout = .bottom(.init(bottomMargin: space!))
            animator =  UpwardAnimator(layout: layout)
        case .center:
            layout = .center(.init())
            animator =  ZoomInOutAnimator(layout: layout)
        }
        
        let window = UIApplication.shared.windows.filter({ $0.isKeyWindow }).last
        let popupView = PopupView(containerView: window!.rootViewController?.view ?? UIView(), contentView: view, animator: animator)
        //配置交互
        popupView.isDismissible = true
        popupView.isInteractive = true
        popupView.isPenetrable = true
        //可以设置为false，再点击弹框中的button试试？
        //        popupView.isInteractive = false
        //        popupView.isPenetrable = true
        //- 配置背景
        //        popupView.backgroundView.style = self.backgroundStyle
        //        popupView.backgroundView.blurEffectStyle = self.backgroundEffectStyle
        popupView.backgroundView.color = UIColor.init(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 0.3)
        
        popupView.display(animated: true, completion: nil)
    }
}
