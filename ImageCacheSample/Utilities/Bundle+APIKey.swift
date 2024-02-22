/*
 Abstract:
 A extension for get API key from Bundle.
 */

import Foundation

// The name of API service property list.
private let tmdbServiceInfo = "TmdbService-Info"

extension Bundle {
    
    var authToken: String {
        // Bundle로부터, API key가 등록된 property list를 가져온다.
        guard let plistPath = self.path(forResource: tmdbServiceInfo, ofType: "plist")
        else {
            fatalError("\(tmdbServiceInfo).plist can not be found.")
        }
        
        // FileManager을 사용하여 Data형식으로 property list data를 가져온다.
        guard let plistData = FileManager.default.contents(atPath: plistPath)
        else {
            fatalError("Unable to read \(tmdbServiceInfo).plist")
        }
        
        do {
            // PropertyListSerialization을 이용하여 Data를 String Dictionary로 변환한다.
            guard let plist = try PropertyListSerialization.propertyList(from: plistData,
                                                                         format: nil) as? [String: String],
                  let authToken = plist["AuthToken"]
            else {
                fatalError("AuthToken not found in \(tmdbServiceInfo).plist")
            }
            return authToken
        } catch {
            fatalError("Error reading \(tmdbServiceInfo).plist: \(error.localizedDescription)")
        }
    }
}
