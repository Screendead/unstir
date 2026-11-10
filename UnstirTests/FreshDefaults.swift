// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest

/// The test bundle's principal class (`NSPrincipalClass` in project.yml): it forgets every level's started flag, saved
/// try and best before each test and once the run ends. A commit on any level that keeps progress writes the first two
/// and a solve the third, and the test host shares its defaults with the harness's launches and every earlier run on
/// the same simulator, where any of them left behind turns a card's first try into a second.
@objc(FreshDefaults) final class FreshDefaults: NSObject, XCTestObservation {
    override init() {
        super.init()
        XCTestObservationCenter.shared.addTestObserver(self)
    }

    func testCaseWillStart(_ testCase: XCTestCase) { forgetProgress() }

    func testBundleDidFinish(_ testBundle: Bundle) { forgetProgress() }
}

/// Every level's started flag, saved try and best, forgotten, so a test opens each level as its first try whatever ran
/// before it.
private func forgetProgress() {
    let prefixes = ["started.", "resume.", "best."]
    for key in UserDefaults.standard.dictionaryRepresentation().keys where prefixes.contains(where: key.hasPrefix) {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
