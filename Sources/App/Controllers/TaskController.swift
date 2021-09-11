//
//  TaskController.swift
//  
//
//  Created by Ryan-Son on 2021/08/07.
//

import Fluent
import Vapor

struct TaskController: RouteCollection {

    enum RouteGroup {
        static let tasks: PathComponent = "tasks"
        static let task: PathComponent = "task"
    }

    func boot(routes: RoutesBuilder) throws {
        let tasks = routes.grouped(RouteGroup.tasks)
        tasks.get(use: read(request:))

        let task = routes.grouped(RouteGroup.task)
        task.post(use: create(request:))
        task.patch(use: update(request:))
        task.delete(use: delete(request:))
    }

    func read(request: Request) throws -> EventLoopFuture<[Task]> {
        return Task.query(on: request.db).all()
    }

    func create(request: Request) throws -> EventLoopFuture<Task> {
        guard request.headers.contentType == .json else {
            throw PMServerError.unsupportedContentType
        }

        try PostTask.validate(content: request)
        let posted = try request.content.decode(PostTask.self)
        let willCreate = Task(from: posted)
        return willCreate.create(on: request.db).map { willCreate }
    }

    func update(request: Request) throws -> EventLoopFuture<Task> {
        guard request.headers.contentType == .json else {
            throw PMServerError.unsupportedContentType
        }

        try PatchTask.validate(content: request)
        let updated = try request.content.decode(PatchTask.self)
        return Task.find(updated.id, on: request.db)
            .unwrap(or: PMServerError.invalidID)
            .flatMap { task in
                if let title = updated.title { task.title = title }
                if let body = updated.body { task.body = body }
                if let due_date = updated.due_date { task.due_date = due_date }
                if let state = updated.state { task.state = state }
                task.updated_at = Date()
                return task.update(on: request.db).map { task }
            }
    }

    func delete(request: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard request.headers.contentType == .json else {
            throw PMServerError.unsupportedContentType
        }

        try DeleteTask.validate(content: request)
        let deleted = try request.content.decode(DeleteTask.self)
        return Task.find(deleted.id, on: request.db)
            .unwrap(or: PMServerError.invalidID)
            .flatMap { $0.delete(on: request.db) }
            .transform(to: .ok)
    }
}
