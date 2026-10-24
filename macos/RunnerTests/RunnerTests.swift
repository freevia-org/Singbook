import Cocoa
import FlutterMacOS
import XCTest

class RunnerTests: XCTestCase {

  func testReleaseIdentityAndResources() throws {
    let app = Bundle.main
    XCTAssertEqual(app.bundleIdentifier, "org.freevia.singbook")
    XCTAssertEqual(app.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String,
                   "public.app-category.music")
    XCTAssertNotNil(app.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
    let languages = try XCTUnwrap(app.object(forInfoDictionaryKey: "CFBundleLocalizations") as? [String])
    XCTAssertTrue(languages.contains("ar"))
    XCTAssertTrue(languages.contains("en"))
    XCTAssertTrue(languages.contains("uk"))
  }

}
