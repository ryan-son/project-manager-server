//
//  DeleteTask.swift
//  
//
//  Created by Ryan-Son on 2021/08/07.
//

import Vapor

struct DeleteTask: Content {

    let id: UUID
}

extension DeleteTask: Validatable {

    static func validations(_ validations: inout Validations) {
        validations.add(PMValidationKey.id, as: UUID.self, required: true)
    }
}
