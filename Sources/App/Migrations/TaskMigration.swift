//
//  MigrateTask.swift
//  
//
//  Created by Ryan-Son on 2021/08/07.
//

import Fluent

struct TaskMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Task.schema)
            .field(Task.Key.id, .uuid, .identifier(auto: false))
            .field(Task.Key.title, .string, .required)
            .field(Task.Key.body, .string)
            .field(Task.Key.due_date, .int, .required)
            .field(Task.Key.state, .string, .required)
            .field(Task.Key.created_at, .double, .required)
            .field(Task.Key.updated_at, .double, .required)
            .field(Task.Key.deleted_at, .double)
            .create()
    }


    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Task.schema).delete()
    }
}
