import Cocoa
import FlutterMacOS
import XCTest

class RunnerTests: XCTestCase {

  func testDidFinishLaunchingDoesNotDispatchUnsupportedSuperclassSelector() throws {
    // Exercise the real launch callback, including a window-less launch. A
    // super call to the optional unimplemented ObjC callback raises an AppKit
    // exception instead of letting this test finish.
    let delegateType = try XCTUnwrap(NSClassFromString("Singbook.AppDelegate") as? NSObject.Type)
    let delegate = delegateType.init()
    let callback = NSSelectorFromString("applicationDidFinishLaunching:")
    XCTAssertTrue(delegate.responds(to: callback))
    delegate.perform(callback, with: Notification(name: NSApplication.didFinishLaunchingNotification) as NSNotification)
  }

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
