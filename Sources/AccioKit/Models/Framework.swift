import Foundation
import SwiftShell

enum FrameworkError: Error {
    case noSharedSchemes
}

struct Framework {
    let projectName: String
    let libraryName: String
    let projectDirectory: String
    let requiredFrameworks: [Framework]

    var commitHash: String {
        return run(bash: "git -C '\(projectDirectory)' rev-parse HEAD").stdout
    }

    var generatedXcodeProjectPath: String {
        return URL(fileURLWithPath: projectDirectory).appendingPathComponent("\(projectName).xcodeproj").path
    }

    func xcodeProjectPaths(in directory: String) throws -> [String] {
        let directoryUrl: URL = URL(fileURLWithPath: directory)
        let visibleContentNames: [String] = try FileManager.default.contentsOfDirectory(atPath: directoryUrl.path).filter { !$0.hasPrefix(".") }
        let visibleContentPaths: [String] = visibleContentNames.map { directoryUrl.appendingPathComponent($0).path }

        let directoryPaths: [String] = try visibleContentPaths.filter { try FileManager.default.isDirectory(atPath: $0) && !pathIsProjectFile($0) }
        let projectFilePaths: [String] = visibleContentPaths.filter { pathIsProjectFile($0) && !$0.isAliasFile }

        let projectFilePathsInDirectories: [String] = try directoryPaths.reduce([]) { $0 + (try xcodeProjectPaths(in: $1)) }
        return projectFilePaths + projectFilePathsInDirectories
    }

    func sharedSchemePaths() throws -> [String] {
        return try xcodeProjectPaths(in: projectDirectory).reduce([]) { result, xcodeProjectPath in
            // TODO: doesn't find existing shared framework in AlignedCollectionViewFlowLayout project, debug
            let schemesDirUrl: URL = URL(fileURLWithPath: xcodeProjectPath).appendingPathComponent("xcshareddata/xcschemes")
            guard FileManager.default.fileExists(atPath: schemesDirUrl.path) else { return result }

            let sharedSchemeFileNames: [String] = try FileManager.default.contentsOfDirectory(atPath: schemesDirUrl.path).filter { $0.hasSuffix(".xcscheme") }
            return result + sharedSchemeFileNames.map { schemesDirUrl.appendingPathComponent($0).path }
        }
    }

    func librarySchemePaths(in schemePaths: [String]) -> [String] {
        let nonLibrarySchemeSubstrings: [String] = ["Example", "Demo", "Sample"]
        return schemePaths.filter { schemePath in
            return !nonLibrarySchemeSubstrings.contains { schemePath.contains($0) }
        }
    }

    private func pathIsProjectFile(_ path: String) -> Bool {
        return path.hasSuffix(".xcodeproj") || path.hasSuffix(".xcworkspace")
    }
}
