import Fluent
import FluentPostgresDriver
import Vapor

enum DatabaseEnvironmentKey {

    static let url = "DATABASE_URL"
    static let hostName = "DATABASE_HOST"
    static let userName = "DATABASE_USERNAME"
    static let password = "DATABASE_PASSWORD"
    static let databaseName = "DATABASE_NAME"
    
    // MARK: Local

    static let localDatabaseName = "project-manager-local"
    static let localPort = 5432
    static let localTestingDatabaseName = "project-manager-test"
    static let localTestingPort = 5433
}

public func configure(_ app: Application) throws {
    configureDatabase(app)
    configureEncoder()
    app.migrations.add(TaskMigration())
    try routes(app)
}

private func configureDatabase(_ app: Application) {
    if let databaseURL = Environment.get(DatabaseEnvironmentKey.url),
       var postgresConfig = PostgresConfiguration(url: databaseURL) {
        var clientTLSConfiguration = TLSConfiguration.makeClientConfiguration()
        clientTLSConfiguration.certificateVerification = .none
        postgresConfig.tlsConfiguration = clientTLSConfiguration
        app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
    } else {
        let databaseName: String
        let databasePort: Int
        
        if app.environment == .testing {
            databaseName = DatabaseEnvironmentKey.localTestingDatabaseName
            databasePort = DatabaseEnvironmentKey.localTestingPort
        } else {
            databaseName = DatabaseEnvironmentKey.localDatabaseName
            databasePort = DatabaseEnvironmentKey.localPort
        }

        app.databases.use(.postgres(hostname: LocalDBInfo.hostName,
                                    port: databasePort,
                                    username: LocalDBInfo.userName,
                                    password: LocalDBInfo.password,
                                    database: databaseName), as: .psql)
    }
}

private func configureEncoder() {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    encoder.dateEncodingStrategy = .iso8601

    ContentConfiguration.global.use(encoder: encoder, for: .json)
}
