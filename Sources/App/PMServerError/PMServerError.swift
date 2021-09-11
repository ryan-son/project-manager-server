//
//  PMServerError.swift
//  
//
//  Created by Ryan-Son on 2021/08/07.
//

import Vapor

enum PMServerError {

    case unsupportedContentType
    case invalidID
}

extension PMServerError: AbortError {

    var reason: String {
        switch self {
        case .unsupportedContentType:
            return "지원되지 않는 Content-Type입니다. Content-Type을 application/json으로 설정해주세요."
        case .invalidID:
            return "존재하지 않는 ID입니다."
        }
    }
    
    var status: HTTPResponseStatus {
        switch self {
        case .unsupportedContentType:
            return .badRequest
        case .invalidID:
            return .notFound
        }
    }
}
