import Async
import Foundation
import XCTest
import PostgreSQL
import TCP

class PostgreSQLClientTests: XCTestCase {
    func testVersion() throws {
        let (client, eventLoop) = try PostgreSQLClient.makeTest()
        let results = try client.query("SELECT version();").await(on: eventLoop)
        XCTAssert(results[0]["version"]?.string?.contains("10.1") == true)
    }

    func testSelectTypes() throws {
        let (client, eventLoop) = try PostgreSQLClient.makeTest()
        let results = try client.query("select * from pg_type;").await(on: eventLoop)
        XCTAssert(results.count > 350)
    }

    func testParse() throws {
        let (client, eventLoop) = try PostgreSQLClient.makeTest()
        let query = """
        select * from "pg_type" where "typlen" = $1 or "typlen" = $2
        """
        let rows = try client.parameterizedQuery(query, [
            .int32(1),
            .int32(2),
        ]).await(on: eventLoop)

        for row in rows {
            XCTAssert(row["typlen"]?.int == 1 || row["typlen"]?.int == 2)
        }
    }

    func testTypes() throws {
        let (client, eventLoop) = try PostgreSQLClient.makeTest()
        let createQuery = """
        create table kitchen_sink (
            "smallint" smallint,
            "integer" integer,
            "bigint" bigint,
            "decimal" decimal,
            "numeric" numeric,
            "real" real,
            "double" double precision,
            "varchar" varchar(64),
            "char" char(4),
            "text" text,
            "bytea" bytea,
            "timestamp" timestamp,
            "date" date,
            "time" time,
            "boolean" boolean,
            "point" point
            -- "line" line,
            -- "lseg" lseg,
            -- "box" box,
            -- "path" path,
            -- "polygon" polygon,
            -- "circle" circle,
            -- "cidr" cidr,
            -- "inet" inet,
            -- "macaddr" macaddr,
            -- "bit" bit(16),
            -- "uuid" uuid
        );
        """
        _ = try client.query("drop table if exists kitchen_sink;").await(on: eventLoop)
        let createResult = try client.query(createQuery).await(on: eventLoop)
        XCTAssertEqual(createResult.count, 0)

        let insertQuery = """
        insert into kitchen_sink values (
            1, -- "smallint" smallint
            2, -- "integer" integer
            3, -- "bigint" bigint
            4, -- "decimal" decimal
            5.3, -- "numeric" numeric
            6, -- "real" real
            7, -- "double" double precision
            '9', -- "varchar" varchar(64)
            '10', -- "char" char(4)
            '11', -- "text" text
            '12', -- "bytea" bytea
            now(), -- "timestamp" timestamp
            current_date, -- "date" date
            localtime, -- "time" time
            true, -- "boolean" boolean
            point(13.5,14) -- "point" point,
            -- "line" line,
            -- "lseg" lseg,
            -- "box" box,
            -- "path" path,
            -- "polygon" polygon,
            -- "circle" circle,
            -- "cidr" cidr,
            -- "inet" inet,
            -- "macaddr" macaddr,
            -- "bit" bit(16),
            -- "uuid" uuid
        );
        """
        let insertResult = try! client.query(insertQuery).await(on: eventLoop)
        XCTAssertEqual(insertResult.count, 0)
        let queryResult = try client.query("select * from kitchen_sink").await(on: eventLoop)
        if queryResult.count == 1 {
            let row = queryResult[0]
            XCTAssertEqual(row["smallint"], .int16(1))
            XCTAssertEqual(row["integer"], .int32(2))
            XCTAssertEqual(row["bigint"], .int64(3))
            XCTAssertEqual(row["decimal"], .double(4))
            XCTAssertEqual(row["real"], .float(6))
            XCTAssertEqual(row["double"], .double(7))
            XCTAssertEqual(row["varchar"], .string("9"))
            XCTAssertEqual(row["char"], .string("10  "))
            XCTAssertEqual(row["text"], .string("11"))
            XCTAssertEqual(row["bytea"], .data(Data([0x31, 0x32])))
            XCTAssertEqual(row["boolean"], .uint8(0x01))
            XCTAssertEqual(row["point"], .point(x: 13.5, y: 14))
        } else {
            XCTFail("query result count is: \(queryResult.count)")
        }
    }

    func testParameterizedTypes() throws {
        let (client, eventLoop) = try PostgreSQLClient.makeTest()
        let createQuery = """
        create table kitchen_sink (
            "smallint" smallint,
            "integer" integer,
            "bigint" bigint,
            "decimal" decimal,
            "numeric" numeric,
            "real" real,
            "double" double precision,
            "varchar" varchar(64),
            "char" char(4),
            "text" text,
            "bytea" bytea,
            "timestamp" timestamp,
            "date" date,
            "time" time,
            "boolean" boolean,
            "point" point
            -- "line" line,
            -- "lseg" lseg,
            -- "box" box,
            -- "path" path,
            -- "polygon" polygon,
            -- "circle" circle,
            -- "cidr" cidr,
            -- "inet" inet,
            -- "macaddr" macaddr,
            -- "bit" bit(16),
            -- "uuid" uuid
        );
        """
        _ = try client.query("drop table if exists kitchen_sink;").await(on: eventLoop)
        let createResult = try client.query(createQuery).await(on: eventLoop)
        XCTAssertEqual(createResult.count, 0)

        let insertQuery = """
        insert into kitchen_sink values (
            $1, -- "smallint" smallint
            $2, -- "integer" integer
            $3, -- "bigint" bigint
            $4, -- "decimal" decimal
            $5, -- "numeric" numeric
            $6, -- "real" real
            $7, -- "double" double precision
            $8, -- "varchar" varchar(64)
            $9, -- "char" char(4)
            $10, -- "text" text
            $11, -- "bytea" bytea
            $12, -- "timestamp" timestamp
            $13, -- "date" date
            $14, -- "time" time
            $15, -- "boolean" boolean
            $16 -- "point" point
            -- "line" line,
            -- "lseg" lseg,
            -- "box" box,
            -- "path" path,
            -- "polygon" polygon,
            -- "circle" circle,
            -- "cidr" cidr,
            -- "inet" inet,
            -- "macaddr" macaddr,
            -- "bit" bit(16),
            -- "uuid" uuid
        );
        """
        let insertResult = try! client.parameterizedQuery(insertQuery, [
            PostgreSQLData.int16(1), // smallint
            PostgreSQLData.int32(2), // integer
            PostgreSQLData.int64(3), // bigint
            PostgreSQLData.double(4), // decimal
            PostgreSQLData.double(5), // numeric
            PostgreSQLData.float(6), // real
            PostgreSQLData.double(7), // double
            PostgreSQLData.string("8"), // varchar
            PostgreSQLData.string("9"), // char
            PostgreSQLData.string("10"), // text
            PostgreSQLData.data(Data([0x31, 0x32])), // bytea
            PostgreSQLData.date(Date()), // timestamp
            PostgreSQLData.date(Date()), // date
            PostgreSQLData.date(Date()), // time
            PostgreSQLData.uint8(1), // boolean
            PostgreSQLData.point(x: 11.5, y: 12) // point
        ]).await(on: eventLoop)
        XCTAssertEqual(insertResult.count, 0)

        let parameterizedResult = try! client.parameterizedQuery("select * from kitchen_sink").await(on: eventLoop)
        if parameterizedResult.count == 1 {
            let row = parameterizedResult[0]
            XCTAssertEqual(row["smallint"], .int16(1))
            XCTAssertEqual(row["integer"], .int32(2))
            XCTAssertEqual(row["bigint"], .int64(3))
            XCTAssertEqual(row["decimal"], .double(4))
            XCTAssertEqual(row["real"], .float(6))
            XCTAssertEqual(row["double"], .double(7))
            XCTAssertEqual(row["varchar"], .string("8"))
            XCTAssertEqual(row["char"], .string("9   "))
            XCTAssertEqual(row["text"], .string("10"))
            XCTAssertEqual(row["bytea"], .data(Data([0x31, 0x32])))
            XCTAssertEqual(row["boolean"], .uint8(0x01))
            XCTAssertEqual(row["point"], .point(x: 11.5, y: 12))
        } else {
            XCTFail("parameterized result count is: \(parameterizedResult.count)")
        }
    }

    static var allTests = [
        ("testVersion", testVersion),
        ("testSelectTypes", testSelectTypes),
        ("testParse", testParse),
        ("testTypes", testTypes),
        ("testParameterizedTypes", testParameterizedTypes),
    ]
}

extension PostgreSQLClient {
    /// Creates a test event loop and psql client.
    static func makeTest() throws -> (PostgreSQLClient, EventLoop) {
        let eventLoop = try DefaultEventLoop(label: "codes.vapor.postgresql.client.test")
        let client = try PostgreSQLClient.connect(on: eventLoop)
        _ = try client.authenticate(username: "postgres").await(on: eventLoop)
        return (client, eventLoop)
    }
}
