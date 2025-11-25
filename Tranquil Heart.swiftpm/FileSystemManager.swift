import Foundation

enum FileSystemManager {
    // debug access and show available dirs
    static func debugFileSystem() {
        print("...Testing file system access...")
        
        // check document directory
        if let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
//            print("📂 Documents directory: \(docDir.path)")
            do {
                _ = try FileManager.default.contentsOfDirectory(atPath: docDir.path)
//                print("📂 Documents directory contents:")
//                docs.prefix(5).forEach { print("    - \($0)")}
            } catch {
                print("❌ Error accessing documents directory: \(error)")
            }
        }
        
        // check bundle resources
        if let resourcePath = Bundle.main.resourcePath {
//            print("📦 Resource path: \(resourcePath)")
            do {
                _ = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
//                print("📦 Bundle resources:")
//                resources.forEach { print("   - \($0)") }
            } catch {
                print("❌ Error listing bundle resources: \(error)")
            }
        }
    }
    
    // check specific file in the bundle
    static func checkFileExists(filename: String, extension ext: String) -> Bool {
        let exists = Bundle.main.url(forResource: filename, withExtension: ext) != nil
        print("🔍 ...Checking for \(filename).\(ext): \(exists ? "😄 Found" : "🥹 Not found")")
        return exists
    }
    
    static func listFiles(inDirectory directory: String) {
//        print("📂 ...Listing files in directory: \(directory)")
        if let bundleURL = Bundle.main.resourceURL?.appendingPathComponent(directory) {
            do {
                _ = try FileManager.default.contentsOfDirectory(at: bundleURL,
                                                                        includingPropertiesForKeys: nil)
//                print("📂 Files found:")
//                files.forEach { print(" - \($0.lastPathComponent)")}
            } catch {
                print("❌ Error listing files: \(error)")
            }
        }
    }
}
