import Foundation
import Network

class TerminalService: ObservableObject {
    @Published var isConnected = false
    @Published var output: String = ""
    @Published var errorMessage: String?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    
    func connect(to url: URL) {
        session = URLSession(configuration: .default)
        
        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()
        
        isConnected = true
        receiveMessage()
    }
    
    func send(command: String) {
        guard let webSocketTask = webSocketTask else { return }
        
        let message = URLSessionWebSocketTask.Message.string(command)
        webSocketTask.send(message) { error in
            if let error = error {
                Task { @MainActor in
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func receiveMessage() {
        guard let webSocketTask = webSocketTask else { return }
        
        webSocketTask.receive { result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    Task { @MainActor in
                        self.output.append(text)
                    }
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        Task { @MainActor in
                            self.output.append(text)
                        }
                    }
                @unknown default:
                    break
                }
                self.receiveMessage()
            case .failure(let error):
                Task { @MainActor in
                    self.errorMessage = error.localizedDescription
                    self.isConnected = false
                }
            }
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        session = nil
        isConnected = false
    }
    
    func clearOutput() {
        output = ""
    }
}
