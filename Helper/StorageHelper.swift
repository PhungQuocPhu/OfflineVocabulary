// Existing content of the file

import Foundation

func checkJSONFileExists(fileName: String) {
    let fileManager = FileManager.default
    let path = Bundle.main.path(forResource: fileName, ofType: "json")
    if let path = path {
        print("JSON file exists at path: \(path)")
    } else {
        print("JSON file does not exist.")
    }
}

// Call the function with the desired JSON file name
checkJSONFileExists(fileName: "exampleFile")