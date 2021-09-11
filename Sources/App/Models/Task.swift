import Fluent
import Vapor

final class Task: Model, Content {

    enum Key {
        static let id: FieldKey = "id"
        static let title: FieldKey = "title"
        static let body: FieldKey = "body"
        static let due_date: FieldKey = "due_date"
        static let state: FieldKey = "state"
        static let created_at: FieldKey = "created_at"
        static let updated_at: FieldKey = "updated_at"
        static let deleted_at: FieldKey = "deleted_at"
    }

    static let schema = "task"

    @ID(custom: Key.id, generatedBy: .user)
    var id: UUID?

    @Field(key: Key.title)
    var title: String

    @Field(key: Key.body)
    var body: String?

    @Field(key: Key.due_date)
    var due_date: Int

    @Field(key: Key.state)
    var state: String

    @Timestamp(key: Key.created_at, on: .create, format: .unix)
    var created_at: Date?

    @Timestamp(key: Key.updated_at, on: .update, format: .unix)
    var updated_at: Date?

    @Timestamp(key: Key.deleted_at, on: .delete, format: .unix)
    var deleted_at: Date?

    init() { }

    init(id: UUID, title: String, body: String? = nil, due_date: Int, state: String) {
        self.id = id
        self.title = title
        self.body = body
        self.due_date = due_date
        self.state = state
    }

    init(from postTask: PostTask) {
        id = postTask.id
        title = postTask.title
        body = postTask.body
        due_date = postTask.due_date
        state = postTask.state
    }
}
