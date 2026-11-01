// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest

/// The test bundle's principal class (`NSPrincipalClass` in project.yml): it forgets every level's started flag before
/// each test and once the run ends. A commit on any level that keeps progress writes one, and the test host shares its
/// defaults with the harness's launches on the same simulator, where a flag left behind turns a card's first try into a
/// second.
@objc(FreshDefaults) final class FreshDefaults: NSObject, XCTestObservation {
    override init() {
        super.init()
        XCTestObservationCenter.shared.addTestObserver(self)
    }

    func testCaseWillStart(_ testCase: XCTestCase) { forgetStarted() }

    func testBundleDidFinish(_ testBundle: Bundle) { forgetStarted() }
}

/// Every level's started flag, forgotten, so a test opens each level as its first try whatever ran before it.
private func forgetStarted() {
    for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix("started.") {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
