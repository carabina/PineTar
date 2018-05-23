//
//  Step.swift
//  UIPlayground
//
//  Created by Tommy Martin on 5/9/18.
//  Copyright © 2018 Diamond Kinetics. All rights reserved.
//

import Foundation
import UIKit

enum State {
    case incomplete
    case complete
    case current
}

public protocol EnableStepDelegate {
    func enableStep(step: Step)
    func disableStep(step: Step)
}

public class Step: NSObject {
    var skippable: Bool
    var text: String
    public var value: Any?
    var resultView: UIView?
    var delegate: EnableStepDelegate? { didSet {correct()} }
    var readyToContinue: Bool { didSet { correct() }}
    var state: State = .incomplete { didSet {if self.state == .current { select() }} }
    
    // Need action
    public init(skippable: Bool, text: String) {
        self.skippable = skippable
        self.text = text
        readyToContinue = skippable
    }
    
    private func correct() {
        guard !skippable else {return}
        
        if readyToContinue {
            delegate?.enableStep(step: self)
        } else {
            delegate?.disableStep(step: self)
        }
    }
    
    func createView(vc: UIViewController) -> UIView {
        return UIView()
    }
    
    func select() {
        resultView?.becomeFirstResponder()
    }
    func deselect() {
        resultView?.resignFirstResponder()
    }
}

public class ImageStep: Step, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private var vc: UIViewController!
    private var imageView: MaterialCardView!
    
    override func createView(vc: UIViewController) -> UIView {
        resultView?.removeFromSuperview()
        self.vc = vc
        let view = UIView()
        
        let imageView = MaterialImageCardView(frame: CGRect.zero)
        imageView.backgroundColor = UIColor.gray
        let image = UIImage(named: "outline_photo_white_48pt", in: Bundle(for: type(of: self)), compatibleWith: nil)
        imageView.update(forConfig: MaterialCardConfig(cornerRadius: 10, dividerConfig: DividerConfig(divideImage: image), headerConfig: HeaderConfig(header: "")))
        self.imageView = imageView
        imageView.cardPressedAction = {card in
            self.imageTapped()
        }

        
        view.addSubview(imageView)
        imageView.snp.makeConstraints{make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(imageView.snp.height)
            make.centerX.equalToSuperview()
        }
        
        self.resultView = view
        return view
    }
    
    @objc func imageTapped() {
        let imagePicker = UIImagePickerController()
        guard UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) else {return}
        imagePicker.delegate = self
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.allowsEditing = false
        
        vc.present(imagePicker, animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {return}
        readyToContinue = true
        vc.dismiss(animated: true, completion: nil)
        imageView.update(forConfig: MaterialCardConfig(dividerConfig: DividerConfig(divideImage: image)))
    }
}

public class TextStep: Step, UITextFieldDelegate {
    override func createView(vc: UIViewController) -> UIView {
        resultView?.removeFromSuperview()
        if value == nil {value = ""}
        
        let label = UITextField()
        label.delegate = self
        label.text = value as? String
        label.textColor = ThemeManager.textColor
        label.textAlignment = .center
        label.font = ThemeManager.font.withSize(24)
        label.autocorrectionType = .no
        label.autocapitalizationType = .none
        self.resultView = label
        
        return label
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let result = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
        readyToContinue = !(result.count == 0)
        return true
    }
}

public class NumberStep: Step, UITextFieldDelegate {
    override func createView(vc: UIViewController) -> UIView {
        resultView?.removeFromSuperview()
        let textField = UITextField()
        textField.delegate = self
        textField.textColor = ThemeManager.textColor
        textField.textAlignment = .center
        textField.font = ThemeManager.font.withSize(24)
        textField.keyboardType = .numberPad
        self.resultView = textField
        
        return textField
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let result = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
        readyToContinue = !(result.count == 0)
        return true
    }
}
