//
//  PostTask.swift
//  
//
//  Created by Ryan-Son on 2021/08/07.
//

import Vapor

struct PostTask: Content {

    let id: UUID
    let title: String
    let body: String?
    let due_date: Int
    let state: String
}

extension PostTask: Validatable {

    static func validations(_ validations: inout Validations) {
        validations.add(PMValidationKey.id, as: UUID.self, required: true)
        validations.add(PMValidationKey.title, as: String.self, required: true)
        validations.add(PMValidationKey.body,
                        as: String.self,
                        is: .count(...PMValidationCondition.maxBodyCount), required: false)
        validations.add(PMValidationKey.due_date, as: Int.self, required: true)
        validations.add(PMValidationKey.state, as: String.self, is: .in("todo", "doing", "done"), required: true)
    }
}
