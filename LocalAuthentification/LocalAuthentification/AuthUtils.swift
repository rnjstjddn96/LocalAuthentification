//
//  AuthUtils.swift
//  LocalAuthentification
//
//  Created by IMFORM-MM-2122 on 2022/06/15.
//

import Foundation
import LocalAuthentication

enum Strings {
    struct Auth {
        static let AUTH_FAILED = "인증에 실패하였습니다."
        static let AUTH_SUCCEED = "인증에 성공하였습니다."
        static let CANCELED_BY_USER = "인증이 취소되었습니다."
        
        struct Bio {
            static let BIO_AUTH_ACTIVATED = "생체 인증을 사용합니다."
            static let BIO_AUTH_DEACTIVATED = "생체 인증 사용이 중지되었습니다."
            static let SET_BIO_AUTH = "생체 인증 설정"
            static let CHECK = "생체 인증을 확인합니다."
            static let NO_BIOMETRIC = "생체인증을 지원하지 않는 기기입니다."
            static let ACTIVATE_BIO_IN_SETTING = "휴대폰에 생체인증 등록 후 이용하실 수 있습니다. '휴대폰 설정 > Face ID(TouchID) 및 암호'에서 등록해주세요."
            static let NOT_AVAILABLE = "기기에서 생체 인증을 사용할 수 없습니다."
            static let NO_PASSCODE = "기기에 설정된 암호가 없습니다\n 암호를 설정하고 생체인증 기능을 활성화해주세요."
            static let CANCELED = "생체인증을 취소했습니다."
            static let AUTH_FAILED = "생체 인증에 실패하셨습니다."
            static let CONTEXT_NOT_DEFINED = "생체 인증 정보 조회에 실패하였습니다."
            static let BIO_LOCK = "생체인증 인증 실패 횟수를 초과했습니다.\n 생체인증 잠금 해제 후 다시 시도해주세요."
            static let INVALID_CONTEXT = "생체인증 과정 중 오류가 발생했습니다.\n 앱 종료 후 다시 시도해주세요."
            
            static let DOMAIN_STATE_CHANGED = "생체 정보가 변경되었습니다."
            static let REACTIVATE_BIO = "생체 정보를 다시 등록해 주시기 바랍니다."
        }
    }
}


final class ErrorHandler {
    class func handleLAContextError(error: Error) -> String {
        switch error {
        case LAError.passcodeNotSet:
            return Strings.Auth.Bio.NO_PASSCODE
        case LAError.invalidContext:
            return Strings.Auth.Bio.INVALID_CONTEXT
        case LAError.biometryLockout:
            return Strings.Auth.Bio.BIO_LOCK
        case LAError.biometryNotAvailable:
            return Strings.Auth.Bio.NOT_AVAILABLE
        case LAError.biometryNotEnrolled:
            return Strings.Auth.Bio.ACTIVATE_BIO_IN_SETTING
        case LAError.userCancel:
            return Strings.Auth.Bio.CANCELED
        default:
            return Strings.Auth.Bio.AUTH_FAILED
        }
    }
}

final class AuthUtils {
    class func getBioStatus() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        //        deviceOwnerAuthenticationWithBiometrics :
        //        사용자가 생체 인식을 사용하여 인증해야 함을 나타냅니다. Touch ID 또는 Face ID를 사용할 수 없거나 등록하지 않은 경우, policy evaluation이 실패합니다.
        //        Touch ID 및 Face ID인증은 모두 5회 이상 실패하면 다시 사용할 수 없으므로 다시 사용할려면 장치 암호를 입력해야 합니다.

        //        deviceOwnerAuthentication : device password.
        //        Touch ID 또는 Face ID가 등록되어 있고, 사용 중지 되지 않은 경우, 사용자에게 먼저 터치하라는 메세지가 표시됩니다.
        //        그렇지 않은 경우, 장치 암호를 입력하라는 메세지가 표시됩니다. 장치 암호가 활성화되어 있지 않으면, policy evaluation이 실패합니다.
        //        패스코드 인증은 6회 실패 이후에 비활성화 되며, 지연은 점진적으로 증가합니다.
        let _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                          error: &error)
        if let error = error {
            print("생체인증을 사용할 수 없습니다: \(ErrorHandler.handleLAContextError(error: error))")
            return .NOT_AVAILABLE(reason: ErrorHandler.handleLAContextError(error: error))
        } else {
            switch context.biometryType {
            case .none:
                print("생체 인증을 지원하지 않는 기기입니다.")
                return .NONE
            case .touchID:
                print("Touch ID 로 인증")
                return .TOUCH_ID
            case .faceID:
                print("Face ID 로 인증")
                return .FACE_ID
            @unknown default:
                return .NONE
            }
        }
    }
    
    // 현재는 하나의 기기 당 하나의 생체인증을 지원하지만 추후 두가지를 모두 지원하는 경우를 대비하여 인증 타입을 입력
    class func requestBioAuth(
            purpose: AuthPurpose,
            context: LAContext = LAContext(),
            type: BiometricType,
            completion: @escaping ((AuthResult) -> Void)
    )  {
        switch purpose {
        case .ACTIVATION:
            //bioActivation => skip detecting context change
            AuthUtils.getBioContext(context: context) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let authSucceeded):
                        switch authSucceeded {
                        case true:
                            guard let newContext = context.evaluatedPolicyDomainState?.base64EncodedString() else {
                                completion(.FAILURE("Failed to get evaluatedPolicyDomainState"))
                                return
                            }
                            prefs.setValue(newContext, forKey: "localAuthentication")
                            completion(.SUCCESS)
                            
                        case false:
                            completion(.FAILURE("Failed to evaluate policy"))
                        }
                        
                    case .failure(let error):
                        completion(.FAILURE(ErrorHandler.handleLAContextError(error: error)))
                        
                    }
                }
            }
            
        case .AUTH:
            //bioAuth => detecting context change
            AuthUtils.getBioContext(context: context) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let authSucceeded):
                        guard let newContext = context.evaluatedPolicyDomainState?.base64EncodedString(),
                              let oldContext = prefs.value(forKey: "localAuthentication") as? String,
                              authSucceeded else {
                                  completion(.FAILURE("Failed to get context"))
                            return
                        }
                        
                        switch oldContext == newContext {
                        case true:
                            completion(.SUCCESS)
                        case false:
                            completion(.FAILURE("Changes in bio context detected"))
                        }
                        
                        
                    case .failure(let error):
                        completion(.FAILURE(ErrorHandler.handleLAContextError(error: error)))
                    }
                }
            }
        }
    }
    
    class func getBioContext(context: LAContext,
                             completion: @escaping ((Result<Bool, Error>) -> Void)) {
            context.localizedFallbackTitle = ""
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: Strings.Auth.Bio.CHECK) { result, error in
                if let error = error {
                    completion(.failure(error))
                }
                
                completion(.success(result))
            }
    }
}
