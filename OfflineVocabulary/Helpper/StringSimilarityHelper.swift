import Foundation

// Mapping chữ ↔ số cho tiếng Anh phổ biến
let numberWords: [String: String] = [
    "zero": "0", "one": "1", "two": "2", "three": "3", "four": "4",
    "five": "5", "six": "6", "seven": "7", "eight": "8", "nine": "9",
    "ten": "10", "eleven": "11", "twelve": "12", "thirteen": "13", "fourteen": "14",
    "fifteen": "15", "sixteen": "16", "seventeen": "17", "eighteen": "18", "nineteen": "19",
    "twenty": "20", "thirty": "30", "forty": "40", "fifty": "50", "sixty": "60",
    "seventy": "70", "eighty": "80", "ninety": "90", "hundred": "100"
]

// Chuyển chữ sang số
func wordsToNumbers(_ text: String) -> String {
    var t = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    for (word, num) in numberWords {
        t = t.replacingOccurrences(of: word, with: num)
    }
    return t
}

// Chuyển số sang chữ
func numbersToWords(_ text: String) -> String {
    var t = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    let numberKeys = numberWords.values.sorted { $0.count > $1.count }
    for num in numberKeys {
        if let word = numberWords.first(where: { $0.value == num })?.key {
            t = t.replacingOccurrences(of: num, with: word)
        }
    }
    return t
}

// Jaro–Winkler distance (cực nhanh, phù hợp với so sánh từ/cụm từ) - ĐÃ FIX CRASH
func jaroWinkler(_ s1: String, _ s2: String) -> Double {
    let s1 = Array(s1)
    let s2 = Array(s2)
    let len1 = s1.count
    let len2 = s2.count
    if len1 == 0 { return len2 == 0 ? 1.0 : 0.0 }
    if len2 == 0 { return len1 == 0 ? 1.0 : 0.0 }
    let matchDistance = max(max(len1, len2) / 2 - 1, 0)
    var s1Matches = Array(repeating: false, count: len1)
    var s2Matches = Array(repeating: false, count: len2)
    var matches = 0
    for i in 0..<len1 {
        let start = max(0, i - matchDistance)
        let end = min(i + matchDistance + 1, len2)
        if start >= end { continue } // FIX: tránh Range lỗi khi start > end
        for j in start..<end {
            if s2Matches[j] { continue }
            if s1[i] != s2[j] { continue }
            s1Matches[i] = true
            s2Matches[j] = true
            matches += 1
            break
        }
    }
    if matches == 0 { return 0.0 }
    var t = 0
    var k = 0
    for i in 0..<len1 {
        if !s1Matches[i] { continue }
        while k < len2 && !s2Matches[k] { k += 1 }
        if k < len2 && s1[i] != s2[k] { t += 1 }
        k += 1
    }
    let m = Double(matches)
    let jaro = (m / Double(len1) + m / Double(len2) + (m - Double(t) / 2.0) / m) / 3.0
    // Winkler bonus
    var prefix = 0
    for i in 0..<min(4, min(len1, len2)) {
        if s1[i] == s2[i] { prefix += 1 } else { break }
    }
    return jaro + 0.1 * Double(prefix) * (1.0 - jaro)
}

// Soundex đơn giản cho tiếng Anh (giúp nhận diện phát âm gần đúng)
func soundex(_ s: String) -> String {
    let map: [Character: Character] = [
        "b": "1", "f": "1", "p": "1", "v": "1",
        "c": "2", "g": "2", "j": "2", "k": "2", "q": "2", "s": "2", "x": "2", "z": "2",
        "d": "3", "t": "3",
        "l": "4",
        "m": "5", "n": "5",
        "r": "6"
    ]
    let s = s.lowercased().filter { $0.isLetter }
    guard let first = s.first else { return "" }
    var result = String(first).uppercased()
    var prev: Character = "0"
    for c in s.dropFirst() {
        let code = map[c] ?? "0"
        if code != "0" && code != prev {
            result.append(code)
        }
        prev = code
    }
    // Đảm bảo độ dài 4 ký tự
    while result.count < 4 { result.append("0") }
    return String(result.prefix(4))
}

// So sánh tối ưu: exact match, Jaro-Winkler, và Soundex
func similarityPercent(_ a: String, _ b: String) -> Int {
    let a1 = wordsToNumbers(a)
    let b1 = wordsToNumbers(b)
    if a1 == b1 { return 100 }
    let a2 = numbersToWords(a)
    let b2 = numbersToWords(b)
    if a2 == b2 { return 100 }
    let percent1 = Int(jaroWinkler(a1, b1) * 100)
    let percent2 = Int(jaroWinkler(a2, b2) * 100)
    // Nếu phát âm gần giống (Soundex giống nhau), cho 85%
    if soundex(a1) == soundex(b1), !soundex(a1).isEmpty {
        return max(percent1, percent2, 85)
    }
    return max(percent1, percent2)
}

// Ví dụ test
func testSimilarity() {
    let pairs = [
        ("nine", "9"),
        ("eleven", "11"),
        ("thirty", "30"),
        ("nice", "nine"),
        ("two", "to"),
        ("forty", "40"),
        ("twenty", "20"),
        ("eight", "ate"),
        ("twelve", "12"),
        ("hundred", "100"),
        ("", ""),
        ("", "abc"),
        ("abc", "")
    ]
    for (a, b) in pairs {
        print("Compare: \"\(a)\" vs \"\(b)\" => \(similarityPercent(a, b))%")
    }
}

// testSimilarity() // Uncomment để test
