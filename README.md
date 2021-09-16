# Project manager server

프로젝트 관리 앱 데이터 관리를 위해 Server-side Swift web framework인 Vapor를 이용해 구현한 REST API 제공 서버

## API 문서

API 사용자를 위해 발행한 문서입니다.

[Project Manager API Documentation](https://documenter.getpostman.com/view/15771494/U16oq4DG)

# Table of Contents

- [1. 프로젝트 개요](#1-프로젝트-개요)
  + [적용된 기술 스택 일람](#적용된-기술-스택-일람)
- [2. 기능](#2-기능)
- [3. 설계 및 구현](#3-설계-및-구현)
- [4. 테스트](#4-테스트)
- [5. Trouble shooting](#5-trouble-shooting)

---

<img width="701" alt="image" src="https://user-images.githubusercontent.com/69730931/133538890-37f6b017-b207-4b02-95ae-7e22dd55ff18.png">

![image](https://user-images.githubusercontent.com/69730931/133540769-8dbaccbf-9be2-4b3a-8b3b-e9c7c4219e33.png)

---


# 1. 프로젝트 개요

## 적용된 기술 스택 일람

| Category            | Stacks                         |
| ------------------- | ------------------------------ |
| Server-side web     | - Vapor                        |
| ORM                 | - Fluent                       |
| DBMS                | - PostgreSQL                   |
| Deployment          | - Heroku                       |
| Encoding / Decoding | - JSONEncoder<br>- JSONDecoder |
| Test                | - XCTVapor                     |

# 2. 기능



## Task 목록 제공

서버 DB에 등록된 task의 목록을 제공합니다.



<img width="700" alt="image" src="https://user-images.githubusercontent.com/69730931/133558525-8324cf3c-eb68-4dd2-9966-90720fb1496d.png">



## Task 등록

새로운 task를 등록할 수 있습니다.

<img width="700" alt="image" src="https://user-images.githubusercontent.com/69730931/133558634-7aa816d6-0196-4cd5-b8b9-033cd43a49e6.png">



## Task 수정

등록된 task를 수정할 수 있습니다.

<img width="700" alt="image" src="https://user-images.githubusercontent.com/69730931/133558706-a601900a-8a30-4a5d-a471-278be962234d.png">



## Task 삭제

등록된 task를 삭제할 수 있습니다.

<img width="700" alt="image" src="https://user-images.githubusercontent.com/69730931/133558789-a8983d9c-4b9c-426e-9b2e-a28f6db92b47.png">



## Request body 검증

Client의 Request body를 검증하여 적절하지 않은 경우 적절한 실패 응답을 반환합니다.



### 본문 최대 글자수 초과 여부

Request body에서 본문이 최대 글자수 (1,000 자)를 초과한 경우 안내 문구와 함께 400 번의 상태 코드로 실패 응답을 반환합니다.

<img width="700" alt="image" src="https://user-images.githubusercontent.com/69730931/133559305-881da32e-a7b7-4aeb-a5a6-c45d8393ed1e.png">



### 지정된 Task state에 해당하는지 여부

state가 todo, doing, done에 해당하는지를 판단하여 해당하지 않을 경우 안내 문구와 함께 400 번의 상태 코드로 실패 응답을 반환합니다.

<img width="700" alt="image" src="https://user-images.githubusercontent.com/69730931/133559356-12223b01-3889-4378-9f88-b7e62b58b9e6.png">



### 마감 기한 타입

마감 기한의 타입이 정수형이 아닌 경우 안내 문구와 함께 400 번의 상태 코드로 실패 응답을 반환합니다.

<img width="700" alt="image" src="https://user-images.githubusercontent.com/69730931/133559398-9b693024-b37f-4182-91b5-fd7d24a32b5b.png">

# 3. 설계 및 구현

## Routing

- Task 목록 조회는 resource collection의 의미를 가지는 복수형으로 path를 설정하였습니다 `~/tasks`.
- Task 등록, 수정 및 삭제는 개별 resource에 대한 접근임을 짐작할 수 있도록 path를 단수형으로 짓되, body에 id를 제공하는 방식으로 특정 resource를 가리키도록 합니다.

```swift
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
}
```

## Task 목록 제공

DB에 등록된 모든 Task 인스턴스를 쿼리하여 반환합니다.

```swift
func read(request: Request) throws -> EventLoopFuture<[Task]> {
    return Task.query(on: request.db).all()
}
```

## Task 등록

등록 작업은 아래와 같은 순서로 진행됩니다.

1. `Content-Type` 검증
2. Request body 검증
3. DTO 타입 (`PostTask`) 디코딩
4. DTO → 모델 타입 변환
5. DB에 새로운 task 인스턴스 생성 및 해당 인스턴스를 response body로 반환



```swift
func create(request: Request) throws -> EventLoopFuture<Task> {
    guard request.headers.contentType == .json else {
        throw PMServerError.unsupportedContentType
    }

    try PostTask.validate(content: request)
    let posted = try request.content.decode(PostTask.self)
    let willCreate = Task(from: posted)
    return willCreate.create(on: request.db).map { willCreate }
}
```

## Task 수정

수정 작업은 아래와 같은 순서로 수행됩니다.

1. `Content-Type` 검증
2. Request body 검증
3. DTO 타입 (`PatchTask`) 디코딩
4. DTO → 모델 타입 변환
5. 변환된 인스턴스의 id를 키값으로 DB에서 기존 인스턴스를 탐색한 후 Request body에 존재하는 값으로 대체
6. 기존 task 인스턴스 수정 및 해당 인스턴스를 response body로 반환

```swift
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
```

## Task 삭제

삭제 작업은 아래와 같은 순서로 이루어집니다.

1. `Content-Type` 검증
2. Request body 검증
3. DTO 타입 (`DeleteTask`) 디코딩
4. DTO → 모델 타입 변환
5. 변환된 인스턴스의 id를 키값으로 DB에서 기존 인스턴스를 탐색하여 삭제
6. 삭제 작업이 성공했음을 상태 코드 200 번으로 반환

```swift
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
```

## Request body 검증

`Validatable` 프로토콜의 `validations(_:)` 메서드를 통해 키 값의 타입과 조건, 필수 여부를 정의합니다.

```swift
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

```

Request를 처리하는 Controller 메서드에서 `validate(content:)` 메서드를 호출하여 디코딩 전에 Request body를 검증합니다.

```swift
func create(request: Request) throws -> EventLoopFuture<Task> {
    guard request.headers.contentType == .json else {
        throw PMServerError.unsupportedContentType
    }

    try PostTask.validate(content: request) // request body 검증
    let posted = try request.content.decode(PostTask.self)
    let willCreate = Task(from: posted)
    return willCreate.create(on: request.db).map { willCreate }
}
```

## 로컬 환경 DBMS 계정 보안

원격 환경에 서버를 배포하기 전 로컬 환경에서 기능을 점검합니다. 이 때 로컬 환경에서 사용되는 host, userName, password를 gitignore를 통해 의도적으로 제외함으로써 원격 환경에 로컬 환경 정보를 배포하지 않도록 설정합니다.

![image](https://user-images.githubusercontent.com/69730931/133565864-fe3b4d83-366b-4805-b05c-4bcbd583de0e.png)

# 4. 테스트

로컬 환경 내 테스트를 위한 별도 DB 구성

# 5. Trouble shooting
