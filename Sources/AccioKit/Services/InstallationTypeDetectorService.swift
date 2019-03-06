import Foundation
import SwiftShell

final class InstallationTypeDetectorService {
    static let shared = InstallationTypeDetectorService()

    func detectInstallationType(for framework: Framework) -> InstallationType {
        switch run(bash: "swift build --package-path \(framework.directory)").exitcode {
        case 0:
            return .swiftPackageManager

        default:
            return .carthage
        }
    }
}