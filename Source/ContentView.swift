import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var engine = ConversionEngine()
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 0) {
            if engine.files.isEmpty {
                // 초기 드래그 앤 드롭 영역
                VStack(spacing: 15) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 60))
                        .foregroundColor(isTargeted ? .orange : .gray.opacity(0.8))
                    Text("PPT, Word 파일을 이곳에 끌어다 놓으세요")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isTargeted ? Color.orange.opacity(0.1) : Color(NSColor.textBackgroundColor).opacity(0.5))
            } else {
                // 작업 대기열 리스트
                List {
                    ForEach(engine.files) { file in
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.orange)
                            Text(file.url.lastPathComponent)
                                .font(.body)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                            
                            switch file.status {
                            case .pending:
                                HStack(spacing: 8) {
                                    Text("대기 중").font(.caption).foregroundColor(.secondary)
                                    Button(action: {
                                        withAnimation { engine.removeFile(id: file.id) }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("목록에서 제거")
                                }
                            case .converting:
                                ProgressView().scaleEffect(0.5).frame(width: 20)
                            case .success:
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            case .failed:
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .help(file.errorMessage ?? "변환 실패")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(InsetListStyle())
            }
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
            for provider in providers {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        let ext = url.pathExtension.lowercased()
                        if ext == "ppt" || ext == "pptx" || ext == "doc" || ext == "docx" {
                            DispatchQueue.main.async {
                                engine.addFile(url: url)
                            }
                        }
                    }
                }
            }
            return true
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: openFilesPanel) {
                    Label("파일 추가", systemImage: "doc.badge.plus")
                }
                .disabled(engine.isProcessing)
            }
            ToolbarItem(placement: .automatic) {
                Button(action: engine.clearAll) {
                    Label("목록 지우기", systemImage: "trash")
                }
                .disabled(engine.isProcessing || engine.files.isEmpty)
            }
            ToolbarItem(placement: .automatic) {
                Button(action: selectOutputFolderAndConvert) {
                    Label("폴더 선택...", systemImage: "folder")
                }
                .help("저장 위치를 직접 선택하여 변환합니다.")
                .disabled(engine.files.isEmpty || engine.isProcessing)
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: defaultConvertHandler) {
                    Label("다운로드로 변환", systemImage: "arrow.down.circle.fill")
                }
                .help("기본 위치(다운로드 폴더)에 즉시 변환하여 저장합니다.")
                .disabled(engine.files.isEmpty || engine.isProcessing)
            }

        }
    }
    
    // 기본 변환 (Downloads 디렉토리 자동 지정)
    private func defaultConvertHandler() {
        if let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            engine.convertAll(to: downloadsURL)
        }
    }
    
    // 폴더 지정 변환 (NSOpenPanel)
    private func selectOutputFolderAndConvert() {
        let panel = NSOpenPanel()
        panel.title = "PDF를 저장할 폴더를 선택하세요"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "이 위치에 저장"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                engine.convertAll(to: url)
            }
        }
    }
    
    private func openFilesPanel() {
        let panel = NSOpenPanel()
        panel.title = "변환할 파일을 선택하세요"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        // PPT/Word 4종을 모두 허용 (UTType.presentation 은 Keynote 계열만 잡으므로 부적절)
        let identifiers = [
            "com.microsoft.powerpoint.ppt",
            "org.openxmlformats.presentationml.presentation",
            "com.microsoft.word.doc",
            "org.openxmlformats.wordprocessingml.document"
        ]
        panel.allowedContentTypes = identifiers.compactMap { UTType($0) }
        
        panel.begin { response in
            if response == .OK {
                for url in panel.urls {
                    let ext = url.pathExtension.lowercased()
                    if ext == "ppt" || ext == "pptx" || ext == "doc" || ext == "docx" {
                        engine.addFile(url: url)
                    }
                }
            }
        }
    }
}
