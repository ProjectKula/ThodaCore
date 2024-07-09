//
//  012_CreateVectors.swift
//
//
//  Created by Shrish Deshpande on 05/07/24.
//

import Fluent
import FluentPostgresDriver

struct CreateVectors: AsyncMigration {
    enum Error: Swift.Error {
        case notPostgresDatabase
    }
    
    func prepare(on database: Database) async throws {
        guard let pgdb = database as? PostgresDatabase else {
            throw Error.notPostgresDatabase
        }
        
        try await database.schema("registeredUsers")
          .field("tsv", .custom("tsvector"))
          .update()
        try await database.schema("posts")
          .field("tsv", .custom("tsvector"))
          .update()
        try await database.schema("confessions")
          .field("tsv", .custom("tsvector"))
          .update()

        try await pgdb.sql().execute(sql: SQLRaw("""
                                                   UPDATE "registeredUsers"
                                                   SET tsv = setweight(to_tsvector(coalesce(collegeid, '')), 'A') ||
                                                   setweight(to_tsvector(coalesce(name, '')), 'A') ||
                                                   setweight(to_tsvector(coalesce(phone, '')), 'B') ||
                                                   setweight(to_tsvector(coalesce(email, '')), 'A') ||
                                                   setweight(to_tsvector(coalesce(personal_email, '')), 'B') ||
                                                   setweight(to_tsvector(coalesce(branch, '')), 'B') ||
                                                   setweight(to_tsvector(coalesce(gender, '')), 'B') ||
                                                   setweight(to_tsvector(coalesce(pronouns, '')), 'B') ||
                                                   setweight(to_tsvector(coalesce(bio, '')), 'B') ||
                                                   setweight(to_tsvector(coalesce(intake_year::text, '')), 'B');
                                                   """), { _ in })
        try await pgdb.sql().execute(sql: SQLRaw("""
                                                   UPDATE posts
                                                   SET tsv = setweight(to_tsvector(coalesce(content, '')), 'A');
                                                   """), { _ in })

        try await pgdb.sql().execute(sql: SQLRaw("""
                                                   UPDATE confessions
                                                   SET tsv = setweight(to_tsvector(coalesce(content, '')), 'A');
                                                   """), { _ in })

        try await pgdb.sql().execute(sql: SQLRaw("CREATE INDEX registeredUsers_tsv_idx ON \"registeredUsers\" USING gin(tsv);"), { _ in })
        try await pgdb.sql().execute(sql: SQLRaw("CREATE INDEX posts_tsv_idx ON posts USING gin(tsv);"), { _ in })
        try await pgdb.sql().execute(sql: SQLRaw("CREATE INDEX confessions_tsv_idx ON confessions USING gin(tsv);"), { _ in })

        try await pgdb.sql().execute(sql: SQLRaw("""
                                                   CREATE FUNCTION registeredUsers_tsv_trigger() RETURNS trigger AS $$
                                                   begin
                                                   new.tsv :=
                                                   setweight(to_tsvector(coalesce(new.collegeid, '')), 'A') ||
                                                   setweight(to_tsvector(coalesce(new.name, '')), 'A') ||
                                                       setweight(to_tsvector(coalesce(new.phone, '')), 'B') ||
                                                       setweight(to_tsvector(coalesce(new.email, '')), 'A') ||
                                                       setweight(to_tsvector(coalesce(new.personal_email, '')), 'B') ||
                                                       setweight(to_tsvector(coalesce(new.branch, '')), 'B') ||
                                                       setweight(to_tsvector(coalesce(new.gender, '')), 'B') ||
                                                       setweight(to_tsvector(coalesce(new.pronouns, '')), 'B') ||
                                                       setweight(to_tsvector(coalesce(new.bio, '')), 'B') ||
                                                       setweight(to_tsvector(coalesce(new.intake_year::text, '')), 'B');
                                                     return new;
                                                   end
                                                   $$ LANGUAGE plpgsql;
                                                   """), { _ in })
        try await pgdb.sql().execute(sql: SQLRaw("""
                                                   CREATE FUNCTION posts_tsv_trigger() RETURNS trigger AS $$
                                                   begin
                                                     new.tsv :=
                                                       setweight(to_tsvector(coalesce(new.content, '')), 'A');
                                                     return new;
                                                   end
                                                   $$ LANGUAGE plpgsql;
                                                   """), { _ in })
        try await pgdb.sql().execute(sql: SQLRaw("""
                                                   CREATE FUNCTION confessions_tsv_trigger() RETURNS trigger AS $$
                                                   begin
                                                     new.tsv :=
                                                       setweight(to_tsvector(coalesce(new.content, '')), 'A');
                                                     return new;
                                                   end
                                                   $$ LANGUAGE plpgsql;
                                                   """), { _ in })

        try await pgdb.sql().execute(sql: SQLRaw("""
                                                   CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
                                                   ON "registeredUsers" FOR EACH ROW EXECUTE FUNCTION registeredUsers_tsv_trigger()
                                                   """), { _ in })
        try await pgdb.sql().execute(sql: SQLRaw("""
                                                   CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
                                                   ON posts FOR EACH ROW EXECUTE FUNCTION posts_tsv_trigger()
                                                   """), { _ in })
        try await pgdb.sql().execute(sql: SQLRaw("""
                                                   CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
                                                   ON confessions FOR EACH ROW EXECUTE FUNCTION confessions_tsv_trigger()
                                                   """), { _ in })
    }
    
    func revert(on database: Database) async throws {
        guard let pgdb = database as? PostgresDatabase else {
            throw Error.notPostgresDatabase
        }

        try await pgdb.sql().execute(sql: SQLRaw("DROP TRIGGER tsvectorupdate ON \"confessions\";"), { _ in })
        try await pgdb.sql().execute(sql: SQLRaw("DROP TRIGGER tsvectorupdate ON posts;"), { _ in })
        try await pgdb.sql().execute(sql: SQLRaw("DROP TRIGGER tsvectorupdate ON \"registeredUsers\";"), { _ in })

        try await pgdb.sql().execute(sql: SQLRaw("DROP FUNCTION confessions_tsv_trigger();"), { _ in })
        try await pgdb.sql().execute(sql: SQLRaw("DROP FUNCTION posts_tsv_trigger();"), { _ in })
        try await pgdb.sql().execute(sql: SQLRaw("DROP FUNCTION registeredUsers_tsv_trigger();"), { _ in })

        try await pgdb.sql().execute(sql: SQLRaw("DROP INDEX confessions_tsv_idx;"), { _ in })
        try await pgdb.sql().execute(sql: SQLRaw("DROP INDEX posts_tsv_idx;"), { _ in })
        try await pgdb.sql().execute(sql: SQLRaw("DROP INDEX registeredUsers_tsv_idx;"), { _ in })

        try await database.schema("confessions")
          .deleteField("tsv")
          .update()
        try await database.schema("posts")
          .deleteField("tsv")
          .update()
        try await database.schema("registeredUsers")
          .deleteField("tsv")
          .update()
    }
}
