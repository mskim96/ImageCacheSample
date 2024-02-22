/*
 Abstract:
 A extension for get MovieAsset from NSCache.
 */

import Foundation

extension NSCache where KeyType == NSString, ObjectType == MovieAssetObject {
    subscript(_ id: MovieAsset.ID) -> MovieAsset? {
        get {
            let key = id as NSString
            let value = object(forKey: key)
            return value?.entry
        }
        
        set {
            let key = id as NSString
            if let entry = newValue {
                let value = MovieAssetObject(entry: entry)
                setObject(value, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }
}
