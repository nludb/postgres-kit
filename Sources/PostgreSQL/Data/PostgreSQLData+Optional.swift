import Async
import Foundation

extension OptionalType {
    /// FIXME: conditional conformance

    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        guard let convertible = WrappedType.self as? PostgreSQLDataCustomConvertible.Type else {
            throw PostgreSQLError(identifier: "optional", reason: "Optional wrapped type \(WrappedType.self) is not PostgreSQLDataCustomConvertible")
        }
        let wrapped = try convertible.convertFromPostgreSQLData(data) as! WrappedType
        return Self.makeOptionalType(wrapped)
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        if let wrapped = self.wrapped {
            guard let convertible = wrapped as? PostgreSQLDataCustomConvertible else {
                throw PostgreSQLError(identifier: "optional", reason: "Optional wrapped type \(WrappedType.self) is not PostgreSQLDataCustomConvertible")
            }
            return try convertible.convertToPostgreSQLData()
        } else {
            return PostgreSQLData(type: .void, format: .binary, data: nil)
        }
    }
}

extension Optional: PostgreSQLDataCustomConvertible {
    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataType`
    public static var postgreSQLDataType: PostgreSQLDataType {
        guard let wrapped = Wrapped.self as? PostgreSQLDataCustomConvertible.Type else {
            fatalError("Optional wrapped type `\(Wrapped.self)` does not conform to `PostgreSQLDataCustomConvertible`")
        }
        return wrapped.postgreSQLDataType
    }


    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataArrayType`
    public static var postgreSQLDataArrayType: PostgreSQLDataType {
        guard let wrapped = Wrapped.self as? PostgreSQLDataCustomConvertible.Type else {
            fatalError("Optional wrapped type `\(Wrapped.self)` does not conform to `PostgreSQLDataCustomConvertible`")
        }
        return wrapped.postgreSQLDataArrayType
    }
}

