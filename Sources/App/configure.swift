import Authentication
import Vapor
import FluentPostgreSQL

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentPostgreSQLProvider())
//    try services.register(AuthenticationProvider())
    try services.register(AuthenticationProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
//    try services.register(PostgreSQLProvider())

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(SessionsMiddleware.self) // Enables sessions.
     middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    
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
    let databaseConfig = PostgreSQLDatabaseConfig(url: Environment.get("DATABASE_URL")!,transport: .unverifiedTLS)!
//    let sqlite = try SQLiteDatabase(storage: .memory)
    let psql = PostgreSQLDatabase(config: databaseConfig)

    

    let poolConfig = DatabaseConnectionPoolConfig(maxConnections: Int(Environment.get("DATABASE_POOL_MAXCONNECTIONS")!)!
    )
    services.register(poolConfig)
    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
//    databases.enableLogging(on: .mysql)
    databases.add(database: psql, as: .psql)
    
    services.register(databases)

    
    
    /// Configure migrations
    var migrations = MigrationConfig()
//
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: UserToken.self, database: .psql)
    migrations.add(model: Project.self, database: .psql)
    migrations.add(model: Link.self, database: .psql)
    migrations.add(model: LabelEnum.self, database: .psql)
    migrations.add(model: ProjectLabel.self, database: .psql)
    migrations.add(migration: LabelEnumDefaultData.self, database: .psql)
    migrations.add(model: Contact.self, database: .psql)
    migrations.add(model: ContactEnum.self, database: .psql)
    migrations.add(migration: ContactEnumDefaultData.self, database: .psql)
    migrations.add(model: Vacancy.self, database: .psql)
    migrations.add(model: Vacancy.ShareType.self, database: .psql)
    migrations.add(migration: ShareTypeDefaultData.self, database: .psql)
    migrations.add(model: UserProject.self, database: .psql)
    migrations.add(model: FavoriteUser.self, database: .psql)
    migrations.add(migration: UserEmailUnicMigration.self, database: .psql)
    services.register(migrations)

}
