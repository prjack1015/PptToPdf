import Foundation
import Combine

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    var status: ConversionStatus
    var errorMessage: String?

    enum ConversionStatus {
        case pending, converting, success, failed
    }
}

class ConversionEngine: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var isProcessing: Bool = false

    func addFile(url: URL) {
        if !files.contains(where: { $0.url == url }) {
            files.append(FileItem(url: url, status: .pending))
        }
    }

    func clearAll() {
        files.removeAll()
    }

    func removeFile(id: UUID) {
        files.removeAll(where: { $0.id == id })
    }

    func convertAll(to outputDirectory: URL) {
        guard !isProcessing else { return }
        isProcessing = true

        // 메인 스레드에서 작업 스냅샷을 떠서 백그라운드로 넘긴다.
        // (변환 중 사용자가 항목을 추가/제거해도 안전)
        let jobs: [(id: UUID, url: URL)] = files.compactMap {
            $0.status == .success ? nil : ($0.id, $0.url)
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            for job in jobs {
                DispatchQueue.main.async {
                    self.updateStatus(id: job.id, status: .converting, error: nil)
                }

                let result = self.convertSingleFile(job.url, outputDir: outputDirectory)

                DispatchQueue.main.async {
                    self.updateStatus(id: job.id,
                                      status: result.success ? .success : .failed,
                                      error: result.error)
                }
            }

            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }
    }

    private func updateStatus(id: UUID, status: FileItem.ConversionStatus, error: String?) {
        guard let idx = files.firstIndex(where: { $0.id == id }) else { return }
        files[idx].status = status
        files[idx].errorMessage = error
    }

    private func convertSingleFile(_ inputURL: URL, outputDir: URL) -> (success: Bool, error: String?) {
        let baseName = inputURL.deletingPathExtension().lastPathComponent
        let outputURL = uniqueOutputURL(in: outputDir, baseName: baseName)

        let ext = inputURL.pathExtension.lowercased()
        let targetApp = (ext == "doc" || ext == "docx") ? "Pages" : "Keynote"

        let scriptSource = """
        on run argv
            set inputFile to POSIX file (item 1 of argv)
            set outputFile to POSIX file (item 2 of argv)
            tell application "\(targetApp)"
                launch
                set myDoc to open inputFile
                export myDoc to outputFile as PDF
                close myDoc saving no
            end tell
        end run
        """

        let tempScriptPath = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("scpt")

        do {
            try scriptSource.write(to: tempScriptPath, atomically: true, encoding: .utf8)
            defer { try? FileManager.default.removeItem(at: tempScriptPath) }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = [tempScriptPath.path, inputURL.path, outputURL.path]

            let errPipe = Pipe()
            process.standardError = errPipe

            try process.run()
            process.waitUntilExit()

            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errText = String(data: errData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            let succeeded = process.terminationStatus == 0
                && FileManager.default.fileExists(atPath: outputURL.path)

            if succeeded { return (true, nil) }

            let fallback = "변환 실패 — \(targetApp)이(가) 설치되어 있고 자동화 권한이 허용되었는지 확인하세요. (시스템 설정 → 개인정보 보호 및 보안 → 자동화)"
            return (false, errText.isEmpty ? fallback : errText)
        } catch {
            return (false, "스크립트 실행 오류: \(error.localizedDescription)")
        }
    }

    // 같은 이름의 PDF가 이미 있으면 " (1)", " (2)" ... 를 붙여 충돌을 피한다.
    private func uniqueOutputURL(in directory: URL, baseName: String) -> URL {
        var candidate = directory.appendingPathComponent(baseName).appendingPathExtension("pdf")
        var counter = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory
                .appendingPathComponent("\(baseName) (\(counter))")
                .appendingPathExtension("pdf")
            counter += 1
        }
        return candidate
    }
}
