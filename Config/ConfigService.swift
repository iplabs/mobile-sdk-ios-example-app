import Foundation

class ConfigService {
    
    static let shared = ConfigService()
    
    func getInfoPlistString(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              value.count > 0 else {
            return nil
        }
        
        return value
    }
    
    func getInfoPlistURL(for key: String) -> URL? {
        guard let string = getInfoPlistString(for: key) else {
            return nil
        }
        
        return URL(string: string.replacingOccurrences(of: "\\", with: ""))
    }
}
