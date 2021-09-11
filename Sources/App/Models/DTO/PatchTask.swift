//
//  PatchTask.swift
//  
//
//  Created by Ryan-Son on 2021/08/07.
//

import Vapor

struct PatchTask: Content {

    let id: UUID
    let title: String?
    let body: String?
    let due_date: Int?
    let state: String?
}

extension PatchTask: Validatable {

    static func validations(_ validations: inout Validations) {
        validations.add(PMValidationKey.id, as: UUID.self, required: true)
        validations.add(PMValidationKey.title, as: String.self, required: false)
        validations.add(PMValidationKey.body,
                        as: String.self,
                        is: .count(...PMValidationCondition.maxBodyCount), required: false)
        validations.add(PMValidationKey.due_date, as: Int.self, required: false)
        validations.add(PMValidationKey.state, as: String.self, is: .in("todo", "doing", "done"), required: false)
    }
}
