import Foundation

class FTPManager: ObservableObject {
    @Published var files: [RemoteFile] = []
    @Published var isConnected: Bool = false
    @Published var error: String? = nil
    private var url: URL?
    private var username: String = ""
    private var password: String = ""

    func connect(host: String, port: Int, username: String, password: String, completion: @escaping (Bool) -> Void) {
        self.username = username
        self.password = password
        self.url = URL(string: "ftp://\(host):\(port)/")
        // Для FTP через CFStream не требуется явное соединение, только авторизация при запросе
        self.isConnected = true
        self.error = nil
        completion(true)
    }

    func listFiles(path: String = "/", completion: @escaping ([RemoteFile]) -> Void) {
        guard let url = url?.appendingPathComponent(path) else {
            completion([])
            return
        }
        
        // Используем современный подход с URLSession
        var request = URLRequest(url: url)
        request.httpMethod = "LIST"
        
        // Добавляем базовую аутентификацию
        let authString = "\(username):\(password)"
        if let authData = authString.data(using: .utf8) {
            let base64Auth = authData.base64EncodedString()
            request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error.localizedDescription
                    completion([])
                    return
                }
                
                guard let data = data,
                      let responseString = String(data: data, encoding: .utf8) else {
                    completion([])
                    return
                }
                
                let files = self?.parseFTPListing(responseString, basePath: path) ?? []
                self?.files = files
                completion(files)
            }
        }
        task.resume()
    }
    
    private func parseFTPListing(_ listing: String, basePath: String) -> [RemoteFile] {
        var files: [RemoteFile] = []
        let lines = listing.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty {
                if let file = parseFTPLine(trimmedLine, basePath: basePath) {
                    files.append(file)
                }
            }
        }
        
        return files
    }
    
    private func parseFTPLine(_ line: String, basePath: String) -> RemoteFile? {
        // Простой парсер для стандартного формата FTP LIST
        let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        guard components.count >= 9 else { return nil }
        
        // Проверяем, является ли это директорией (начинается с 'd')
        let isDirectory = components[0].hasPrefix("d")
        
        // Имя файла - последний компонент
        let fileName = components.last ?? ""
        
        // Размер файла
        let sizeString = components[4]
        let size = Int64(sizeString) ?? 0
        
        // Дата модификации (упрощенная обработка)
        let date = Date() // В реальном приложении нужно парсить дату из строки
        
        return RemoteFile(
            name: fileName,
            path: basePath + "/" + fileName,
            isDirectory: isDirectory,
            size: size,
            modifiedDate: date,
            permissions: nil
        )
    }

    func disconnect() {
        isConnected = false
        url = nil
    }
} 