@testable import App
import XCTest
import Crypto

final class SaltHashTests: XCTestCase {
    func testSalt() async throws {
        let salt1: [UInt8] = .init("world".utf8)
        let pass1: String = "hello"
        let hash1 = try combineSaltAndHash(pw: pass1, salt: salt1).hex
        XCTAssertEqual("936a185caaa266bb9cbe981e9e05cb78cd732b0b3280eb944412bb6f8f8f07af", hash1)
        
        let salt2: [UInt8] = .init("me trying".utf8)
        let pass2: String = "this is "
        let hash2 = try combineSaltAndHash(pw: pass2, salt: salt2).hex
        XCTAssertEqual("2525b4e2527c178daaf67e99900f56cde5f3ddaa07a71f42bbe37fa38b22acef", hash2)
        
        let salt3: [UInt8] = .init("swift".utf8)
        let pass3: String = "objectivec"
        let hash3 = try combineSaltAndHash(pw: pass3, salt: salt3).hex
        XCTAssertEqual("e3200e37ea913241d7151d3f56791b0b05988bf71794ee9c32b5b5ca7cb92788", hash3)
    }
}
