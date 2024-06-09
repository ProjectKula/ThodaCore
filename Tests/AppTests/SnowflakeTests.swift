@testable import App
import XCTest
import Crypto

final class SnowflakeTests: XCTestCase {
    func testSnowflake() async throws {
        let snowflake: Snowflake = .init()
        print(snowflake.stringValue)
    }
}
