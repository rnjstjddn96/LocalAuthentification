//
//  ViewController.swift
//  LocalAuthentification
//
//  Created by IMFORM-MM-2122 on 2022/06/08.
//

import UIKit

class ViewController: UIViewController {

    let btnActivate: UIButton = {
        let button = UIButton()
        button.setTitle("생체인증 활성화", for: .normal)
        button.backgroundColor = .clear
        button.setTitleColor(.label, for: .normal)
        button.setTitleColor(.label.withAlphaComponent(0.5), for: .highlighted)
        return button
    }()
    
    let btnAuth: UIButton = {
        let button = UIButton()
        button.setTitle("생체인증 요청", for: .normal)
        button.backgroundColor = .clear
        button.setTitleColor(.label, for: .normal)
        button.setTitleColor(.label.withAlphaComponent(0.5), for: .highlighted)
        button.setTitleColor(.systemBackground, for: .disabled)
        button.isEnabled = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.addSubview(btnActivate)
        self.view.addSubview(btnAuth)
        
        btnActivate.translatesAutoresizingMaskIntoConstraints = false
        btnAuth.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btnActivate.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            btnActivate.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -30),
            btnActivate.widthAnchor.constraint(lessThanOrEqualTo: self.view.widthAnchor)
        ])
        
        NSLayoutConstraint.activate([
            btnAuth.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            btnAuth.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 30),
            btnAuth.widthAnchor.constraint(lessThanOrEqualTo: self.view.widthAnchor)
        ])
        
        checkStatus()
        setActions()
    }
    
    private func checkStatus() {
        if let context = prefs.value(forKey: "localAuthentication") as? String {
            print("context: \(context)")
            self.btnAuth.isEnabled = true
        } else {
            self.btnAuth.isEnabled = false
        }
    }
    
    private func setActions() {
        self.btnActivate.addTarget(self, action: #selector(activate), for: .touchUpInside)
        self.btnAuth.addTarget(self, action: #selector(auth), for: .touchUpInside)
    }
    
    @objc func activate() {
        AuthUtils.requestBioAuth(purpose: .ACTIVATION,
                                 type: AuthUtils.getBioStatus()) { result in
            switch result {
            case .FAILURE(let reason):
                AlertUtils.displayBasicAlert(
                    controller: self,
                    title: "생체인증 활성화 실패",
                    message: reason,
                    showCancelButton: false,
                    okButtonTitle: "확인",
                    cancelButtonTitle: nil,
                    okButtonCallback: nil,
                    cancelButtonCallback: nil
                )
            case .SUCCESS:
                AlertUtils.displayBasicAlert(
                    controller: self,
                    title: nil,
                    message: "생체인증 활성화 성공",
                    showCancelButton: false,
                    okButtonTitle: "확인",
                    cancelButtonTitle: nil,
                    okButtonCallback: { [weak self] in
                        guard let self = self else { return }
                        self.checkStatus()
                    },
                    cancelButtonCallback: nil
                )
            }
        }
    }
    
    @objc func auth() {
        AuthUtils.requestBioAuth(purpose: .AUTH,
                                 type: AuthUtils.getBioStatus()) { result in
            switch result {
            case .SUCCESS:
                AlertUtils.displayBasicAlert(
                    controller: self,
                    title: nil,
                    message: "생체인증 성공",
                    showCancelButton: false,
                    okButtonTitle: "확인",
                    cancelButtonTitle: nil,
                    okButtonCallback: nil,
                    cancelButtonCallback: nil
                )
            case .FAILURE(let reason):
                AlertUtils.displayBasicAlert(
                    controller: self,
                    title: "생체인증 실패",
                    message: reason,
                    showCancelButton: false,
                    okButtonTitle: "확인",
                    cancelButtonTitle: nil,
                    okButtonCallback: { [weak self] in
                        guard let self = self else { return }
                        self.checkStatus()
                    },
                    cancelButtonCallback: nil
                )
            }
        }
    }
}

final class AlertUtils {
    class func displayBasicAlert(controller: UIViewController,
                                 title: String?,
                                 message: String,
                                 showCancelButton: Bool,
                                 okButtonTitle: String,
                                 cancelButtonTitle: String?,
                                 okButtonCallback: (() -> Void)?,
                                 cancelButtonCallback: (() -> Void)?) {
        var titleString = ""
        if let title = title {
            titleString = title
        }
        
        let alert = UIAlertController(title: titleString, message: message, preferredStyle: .alert)
        let alertOkAction = UIAlertAction(title: okButtonTitle, style: .default) { (action) in
            if let okButtonCallback = okButtonCallback {
                okButtonCallback()
            }
        }
        
        if showCancelButton {
            let alertCancelAction = UIAlertAction(title: cancelButtonTitle!, style: .cancel) { (action) in
                if let cancelButtonCallback = cancelButtonCallback {
                    cancelButtonCallback()
                }
            }
            
            alert.addAction(alertCancelAction)
        }
        
        alert.addAction(alertOkAction)
        controller.present(alert, animated: true, completion: nil)
    }
}
