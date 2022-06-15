//
//  BiometricType.swift
//  LocalAuthentification
//
//  Created by IMFORM-MM-2122 on 2022/06/15.
//

import Foundation

enum BiometricType {
    case NONE
    case TOUCH_ID
    case FACE_ID
    case NOT_AVAILABLE(reason: String)
    
    var isAvailable: Bool {
        switch self {
        case .FACE_ID, .TOUCH_ID:
            return true
        default:
            return false
        }
    }
}

enum AuthPurpose {
    case ACTIVATION
    case AUTH
}

enum AuthResult {
    case SUCCESS
    case FAILURE(_ reason: String)
}
