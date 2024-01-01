// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Brian Young on 1/1/24.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

@available(macOS 10.15, *)
extension Runner.RunningProcess {
    public var isRunning: Bool { process.isRunning }
    public var isComplete: Bool { !isRunning }
    public var output: String? { stdout?.buffer.text }

    public func waitUntilComplete() async throws {
        guard process.isRunning else { return }

        try await withTaskCancellationHandler {
            process.terminate()
        } operation: {
            await try withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { process in
                    if process.terminationStatus == 0 {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    fileprivate var error: Error {
        Runner.Error(
            status: process.terminationStatus,
            stdout: self.stdout?.finish() ?? "",
            stderr: self.stderr?.finish() ?? ""
        )
    }
}

extension Runner {
    public struct Error: Swift.Error {
        public var localizedDescription: String

        init(status: Int32, stdout: String, stderr: String) {
            localizedDescription = "Process failed with status \(status) with error: \(stderr)"
        }
    }
}
