//
//  AppTests.swift
//
//
//  Created by Ryan-Son on 2021/08/07.
//

@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    
    private var app: Application!
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
        app = nil
    }
    
    func testTasksCanBeRetrievedFromAPI() throws {
        try TestAsset.dummyTask.save(on: app.db).wait()
        
        try app.test(.GET, TestAsset.tasksURI, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            
            let receivedTasks = try response.content.decode([Task].self)
            XCTAssertEqual(receivedTasks.count, 1)
            XCTAssertEqual(receivedTasks.first?.id, TestAsset.expectedID)
            XCTAssertEqual(receivedTasks.first?.title, TestAsset.expectedTitle)
            XCTAssertEqual(receivedTasks.first?.body, TestAsset.expectedBody)
            XCTAssertEqual(receivedTasks.first?.due_date, TestAsset.expectedDueDate)
            XCTAssertEqual(receivedTasks.first?.state, TestAsset.expectedState)
        })
    }
    
    func testTaskCanBeCreatedWithAPI() throws {
        try app.test(.POST, TestAsset.taskURI, beforeRequest: { request in
            try request.content.encode(TestAsset.dummyTask)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            
            let receivedTask = try response.content.decode(Task.self)
            XCTAssertEqual(receivedTask.id, TestAsset.expectedID)
            XCTAssertEqual(receivedTask.title, TestAsset.expectedTitle)
            XCTAssertEqual(receivedTask.body, TestAsset.expectedBody)
            XCTAssertEqual(receivedTask.due_date, TestAsset.expectedDueDate)
            XCTAssertEqual(receivedTask.state, TestAsset.expectedState)
            
            try app.test(.GET, TestAsset.tasksURI, afterResponse: { secondResponse in
                XCTAssertEqual(secondResponse.status, .ok)
                
                let receivedTasks = try secondResponse.content.decode([Task].self)
                XCTAssertEqual(receivedTasks.count, 1)
                XCTAssertEqual(receivedTasks.first?.id, TestAsset.expectedID)
                XCTAssertEqual(receivedTasks.first?.title, TestAsset.expectedTitle)
                XCTAssertEqual(receivedTasks.first?.body, TestAsset.expectedBody)
                XCTAssertEqual(receivedTasks.first?.due_date, TestAsset.expectedDueDate)
                XCTAssertEqual(receivedTasks.first?.state, TestAsset.expectedState)
            })
        })
    }
    
    func testTaskCanBeUpdatedWithAPI() throws {
        let dummyTask = TestAsset.dummyTask
        try dummyTask.save(on: app.db).wait()
        let patchTask = PatchTask(id: dummyTask.id!,
                                  title: TestAsset.expectedPatchTitle,
                                  body: TestAsset.expectedPatchBody,
                                  due_date: TestAsset.expectedPatchDueDate,
                                  state: TestAsset.expectedPatchState)
        
        try app.test(.PATCH, TestAsset.taskURI, beforeRequest: { request in
            try request.content.encode(patchTask)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            
            let receivedTask = try response.content.decode(Task.self)
            XCTAssertEqual(receivedTask.id, patchTask.id)
            XCTAssertEqual(receivedTask.title, patchTask.title)
            XCTAssertEqual(receivedTask.body, patchTask.body)
            XCTAssertEqual(receivedTask.due_date, patchTask.due_date)
            XCTAssertEqual(receivedTask.state, patchTask.state)
            
            try app.test(.GET, TestAsset.tasksURI, afterResponse: { secondResponse in
                XCTAssertEqual(secondResponse.status, .ok)
                
                let receivedTasks = try secondResponse.content.decode([Task].self)
                XCTAssertEqual(receivedTasks.count, 1)
                XCTAssertEqual(receivedTasks.first?.id, patchTask.id)
                XCTAssertEqual(receivedTasks.first?.title, patchTask.title)
                XCTAssertEqual(receivedTasks.first?.body, patchTask.body)
                XCTAssertEqual(receivedTasks.first?.due_date, patchTask.due_date)
                XCTAssertEqual(receivedTasks.first?.state, patchTask.state)
            })
        })
    }

    func testTaskCanBeDeletedWithAPI() throws {
        let dummyTask = TestAsset.dummyTask
        try dummyTask.save(on: app.db).wait()
        let deleteTask = DeleteTask(id: dummyTask.id!)

        try app.test(.DELETE, TestAsset.taskURI, beforeRequest: { request in
            try request.content.encode(deleteTask)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            
            try app.test(.GET, TestAsset.tasksURI, afterResponse: { secondResponse in
                XCTAssertEqual(secondResponse.status, .ok)

                let receivedTasks = try secondResponse.content.decode([Task].self)
                XCTAssertEqual(receivedTasks.count, .zero)
            })
        })
    }

    func testFailedToPostWithAPIDueToInvalidContentType() throws {
        try app.test(.POST, TestAsset.taskURI, beforeRequest: { request in
            request.headers.contentType = .plainText
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }

    func testFailedToPatchWithAPIDueToInvalidContentType() throws {
        try app.test(.PATCH, TestAsset.taskURI, beforeRequest: { request in
            request.headers.contentType = .plainText
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }

    func testFailedToDeleteWithAPIDueToInvalidContentType() throws {
        try app.test(.DELETE, TestAsset.taskURI, beforeRequest: { request in
            request.headers.contentType = .plainText
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }

    func testFailedToPostWithAPIDueToNotContainingID() throws {
        let dummyTask = TestAsset.dummyTask
        dummyTask.id = nil

        try app.test(.POST, TestAsset.taskURI, beforeRequest: { request in
            try request.content.encode(dummyTask)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }

    func testFailedToUpdateWithAPIDueToInvalidID() throws {
        let invalidUUID = UUID()
        let patchTask = PatchTask(id: invalidUUID,
                                  title: "난 실패할거에요..",
                                  body: nil,
                                  due_date: 71293261,
                                  state: "todo")

        try app.test(.PATCH, TestAsset.taskURI, beforeRequest: { request in
            try request.content.encode(patchTask)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .notFound)
        })
    }

    func testFailedToDeleteWithAPIDueToInvalidID() throws {
        let invalidUUID = UUID()
        let deleteProjectItem = DeleteTask(id: invalidUUID)

        try app.test(.DELETE, TestAsset.taskURI, beforeRequest: { request in
            try request.content.encode(deleteProjectItem)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .notFound)
        })
    }

    func testFailedToPassValidationDueToContentExceeds1000Characters() throws {
        try app.test(.POST, TestAsset.taskURI, beforeRequest: { request in
            try request.content.encode(TestAsset.dummyTaskWithLongBody)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }

    func testFailedToPassValidationDueToEnteredInvalidURI() throws {
        try app.test(.GET, "/someInvalidURI", afterResponse: { response in
            XCTAssertEqual(response.status, .notFound)
        })
    }
}
