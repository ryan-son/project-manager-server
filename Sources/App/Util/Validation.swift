//
//  File.swift
//  
//
//  Created by Ryan-Son on 2021/08/07.
//

import Vapor

enum PMValidationCondition {

    static let maxBodyCount = 1000
}

enum PMValidationKey {

    static let id: ValidationKey = "id"
    static let title: ValidationKey = "title"
    static let body: ValidationKey  = "body"
    static let due_date: ValidationKey = "due_date"
    static let state: ValidationKey = "state"
}
