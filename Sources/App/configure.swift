import Authentication
import FluentSQLite
import Vapor
import FluentMySQL

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentSQLiteProvider())
//    try services.register(AuthenticationProvider())
    try services.register(AuthenticationProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    try services.register(MySQLProvider())

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(SessionsMiddleware.self) // Enables sessions.
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
    middlewares.use(corsMiddleware)
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
    
//    let sqlite = try SQLiteDatabase(storage: .memory)
    let mySQL = MySQLDatabase(config: MySQLDatabaseConfig(hostname: "team2project.tk", port: 3306, username: "team2project_user", password: "10$*nv5&XC6v7i4c^vB", database: "team2project", capabilities: .default, characterSet: .utf8mb4_unicode_ci, transport: .cleartext))

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
//    databases.enableLogging(on: .mysql)
    databases.add(database: mySQL, as: .mysql)
    services.register(databases)

    
    
    /// Configure migrations
    var migrations = MigrationConfig()
//
    migrations.add(model: User.self, database: .mysql)
    migrations.add(model: UserToken.self, database: .mysql)
    migrations.add(model: Project.self, database: .mysql)
    migrations.add(model: Link.self, database: .mysql)
    migrations.add(model: LabelEnum.self, database: .mysql)
    migrations.add(model: ProjectLabel.self, database: .mysql)
    migrations.add(migration: LabelEnumDefaultData.self, database: .mysql)
    migrations.add(model: ContactEnum.self, database: .mysql)
    migrations.add(migration: ContactEnumDefaultData.self, database: .mysql)
    services.register(migrations)

}
