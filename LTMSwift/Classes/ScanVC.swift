//
//  ScanVC.swift
//  Alamofire
//
//  Created by 柯南 on 2023/1/18.
// 二维码条形码 扫码识别、图片识别

import UIKit
import AVKit
import SnapKit

open class ScanVC: UIViewController {
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configCaptureSession()
        self.startRunning()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "扫码"
        configBgLayer()
        configScanRectBoard()
        configScanLine()
        self.view.addSubview(self.torchBtn)
        self.view.addSubview(self.photoLibBtn)
        self.torchBtn.snp.makeConstraints { make in
            make.left.equalTo(self.view).offset(40)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-30)
        }
        self.photoLibBtn.snp.makeConstraints { make in
            make.right.equalTo(self.view).offset(-40)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-30)
        }
        self.torchBtn.addTarget(self, action: #selector(torchBtnClick), for: .touchUpInside)
        self.photoLibBtn.addTarget(self, action: #selector(photoLibBtnClick), for: .touchUpInside)
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.hasTorch {
            try? self.captureDevice?.lockForConfiguration()
            self.captureDevice?.torchMode = .off
            self.captureDevice?.unlockForConfiguration()
            self.hasTorch = false
        }
        stopRunning()
    }
    
    /// 扫码回调
    public var scanBlock: ((_ result: String) -> Void)?
    /// 信号采集硬件设备(摄像头、麦克风、屏幕等)
    private var captureDevice: AVCaptureDevice?
    /// 捕获设备输入
    private var captureInput: AVCaptureDeviceInput?
    /// 捕获元数据输出
    private var mataOutput: AVCaptureMetadataOutput?
    /// 捕获会话
    private var captureSession: AVCaptureSession?
    /// 捕获视频预览层
    private var capturePreView: AVCaptureVideoPreviewLayer?
    /// 来回扫码线
    private lazy var scanLineView: UIView = {
        let view = UIView()
        
        return view
    }()
    /// 来回扫码线颜色
    private var lineColor: UIColor = .white
    /// 来回扫码线颜色
    public var scanLineColor: UIColor{
        set{
            self.lineColor = newValue
        }get{
            self.lineColor
        }
    }
    /// 是否有闪光灯
    private var hasTorch: Bool = false
    
    /// 扫描区域
    private lazy var scanRect: CGRect = {
        let padding: CGFloat = 40
        let scanLength = UIScreen.main.bounds.size.width - padding * 2
        let rect = CGRect.init(x: padding,
                               y: (UIScreen.main.bounds.size.height - scanLength) / 2 - padding,
                               width: scanLength,
                               height: scanLength)
        return rect
    }()
    
    /// 闪光灯
    private lazy var torchBtn: UIButton = {
        let button = UIButton()
        button.setTitle("打开闪光灯", for: .normal)
        button.setTitle("关闭闪光灯", for: .selected)
        button.setTitleColor(.white)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)

        return button
    }()
   
    /// 相册
    private lazy var photoLibBtn: UIButton = {
        let button = UIButton()
        button.setTitle("相册")
        button.setTitleColor(.white)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)

        return button
    }()
}

fileprivate extension ScanVC {
    /// 设置背景Layer
    func configBgLayer() {
        let bgLayer = CALayer.init()
        bgLayer.frame = self.view.frame
        bgLayer.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.35).cgColor
        
        let maskLayer = CAShapeLayer.init()
        let path = UIBezierPath.init(rect: self.view.frame)
        let path1 = UIBezierPath.init(rect: self.scanRect).reversing()
        path.append(path1)
        maskLayer.path = path.cgPath
        bgLayer.mask = maskLayer
        self.view.layer.addSublayer(bgLayer)
    }
    
    /// 设置扫描区域
    func configScanRectBoard() {
        let scanLayer = CAShapeLayer.init()
        let rect = CGRect.init(x: self.scanRect.origin.x+0.5,
                               y: self.scanRect.origin.y+0.5,
                               width: self.scanRect.size.width-1,
                               height: self.scanRect.size.height-1)
        let path = UIBezierPath.init(rect: rect)
        scanLayer.path = path.cgPath
        scanLayer.strokeColor = UIColor.white.cgColor
        scanLayer.fillColor = UIColor.clear.cgColor
        self.view.layer.addSublayer(scanLayer)
    }
    
    /// 设置扫描线
    func configScanLine() {
        self.scanLineView = UIView.init(frame: CGRect(x: self.scanRect.origin.x+1,
                                                  y: self.scanRect.origin.y+1,
                                                  width: self.scanRect.size.width-2,
                                                  height: 3))
        self.scanLineView.backgroundColor = self.lineColor
        self.scanLineView.isHidden = true
        self.view.addSubview(self.scanLineView)
    }
    
    /// 配置会话
    func configCaptureSession(){
        self.captureDevice = AVCaptureDevice.default(for: .video)
        do {
            try self.captureInput = AVCaptureDeviceInput(device: self.captureDevice!)
        } catch  {
            
        }
        self.mataOutput = AVCaptureMetadataOutput()
        self.mataOutput?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        self.captureSession = AVCaptureSession()
        if ((self.captureSession?.canAddInput(self.captureInput!))!){
            self.captureSession?.addInput(self.captureInput!)
        }
        if((self.captureSession?.canAddOutput(self.mataOutput!))!){
            self.captureSession?.addOutput(self.mataOutput!)
        }
        if((self.captureSession?.canSetSessionPreset(AVCaptureSession.Preset.high))!){
            self.captureSession?.sessionPreset = .high
        }
        self.mataOutput?.metadataObjectTypes = [.ean13, .aztec, .qr]
        self.capturePreView = AVCaptureVideoPreviewLayer.init(session: self.captureSession!)
        self.capturePreView?.videoGravity = .resizeAspectFill
        self.capturePreView?.frame = self.view.frame
        self.view.layer.insertSublayer(self.capturePreView!, at: 0)
        self.captureSession?.startRunning()
        let rect = self.capturePreView!.metadataOutputRectConverted(fromLayerRect: self.scanRect)
        self.mataOutput?.rectOfInterest = rect
    }
    
    /// 开始扫描
    func startRunning() {
        self.scanLineView.isHidden = false
        let animation = CABasicAnimation.init(keyPath: "transform.translation.y")
        animation.fromValue = 0
        animation.toValue = self.scanRect.size.height
        animation.timingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.duration = 3
        animation.isRemovedOnCompletion = false
        animation.repeatCount = MAXFLOAT
        self.scanLineView.layer.add(animation, forKey: "y_transaltion")
        if ((self.captureSession?.isRunning)!){
            return
        }
        self.captureSession?.startRunning()
    }
    
    /// 结束扫描
    func stopRunning(){
        if (!(self.captureSession?.isRunning)!){
            return
        }
        self.captureSession?.stopRunning()
        self.scanLineView.isHidden = true
        self.scanLineView.layer.removeAnimation(forKey: "y_transaltion")
    }
}

/// 相册二维码
extension ScanVC: UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            // 取出选中的图片
            let img = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
            // 创建一个探测器
            let decteor = CIDetector.init(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
            // 利用探测器探测数据
            let ciimg = CIImage.init(cgImage: img.cgImage!)
            let fetures = decteor?.features(in: ciimg)
            if (fetures?.count)! > 0 {
                if let qrFeture = fetures?.first as? CIQRCodeFeature {
                    // 停止扫描
                    self.stopRunning()
                    // 返回二维码信息
                    if (self.scanBlock != nil) {
                        self.scanBlock!(qrFeture.messageString!)
                    }
                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                print("没有检测到二维码")
            }
        }
    }
    
    /// 打开闪光灯
    @objc func torchBtnClick() {
        if ((captureDevice?.hasTorch)!) {
            if (!self.hasTorch) {
                try? captureDevice?.lockForConfiguration()
                try? captureDevice?.setTorchModeOn(level: 0.6)
                captureDevice?.unlockForConfiguration()
                self.hasTorch = true
            } else {
                try? captureDevice?.lockForConfiguration()
                captureDevice?.torchMode = .off
                captureDevice?.unlockForConfiguration()
                self.hasTorch = false
            }
            self.torchBtn.isSelected = self.hasTorch
        }
    }
    
    /// 打开相册
    @objc func photoLibBtnClick() {
        let imageController = UIImagePickerController.init()
        imageController.sourceType = .photoLibrary
        imageController.delegate = self
        self.present(imageController, animated: true, completion: nil)
    }
}

extension ScanVC: AVCaptureMetadataOutputObjectsDelegate{
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if (metadataObjects.count == 0) {
            return
        }
        // 开启系统震动
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        // 停止扫描
        self.stopRunning()
        // 返回数据
        let object = metadataObjects.first as! AVMetadataMachineReadableCodeObject
        let result = object.stringValue
        if self.scanBlock != nil {
            self.scanBlock!(result!)
        }
        self.navigationController?.popViewController(animated: true)
    }
}
