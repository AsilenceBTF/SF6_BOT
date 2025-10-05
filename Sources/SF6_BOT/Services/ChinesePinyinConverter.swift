import Foundation

// 拼音转换器
public class ChinesePinyinConverter {
    
    // Unicode 到拼音的映射字典
    nonisolated(unsafe) private static var pinyinMap: [String: [String]] = [:]
    
    // 初始化映射表
    public static func initialize(with mapping: [String: [String]]) {
        pinyinMap = mapping
    }
    
    // 从你提供的格式解析并构建映射表
    public static func initialize(with mappingString: String) {
        var map: [String: [String]] = [:]
        
        let lines = mappingString.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty { continue }
            
            // 解析格式: "4E00 (yi1)"
            let components = trimmedLine.components(separatedBy: " (")
            guard components.count == 2,
                  let unicodePart = components.first?.trimmingCharacters(in: .whitespaces),
                  let pinyinPart = components.last?.trimmingCharacters(in: CharacterSet(charactersIn: ")")) else {
                continue
            }
            
            // 处理拼音部分
            let pinyinComponents = pinyinPart.components(separatedBy: ",")
            var pinyinArray: [String] = []
            
            for pinyin in pinyinComponents {
                if pinyin == "none0" || pinyin.isEmpty {
                    continue
                }
                // 移除音调数字，保留纯拼音
                let cleanPinyin = removeToneNumbers(from: pinyin)
                pinyinArray.append(cleanPinyin)
            }
            
            if !pinyinArray.isEmpty {
                map[unicodePart] = pinyinArray
            }
        }
        
        pinyinMap = map
    }
    
    // 移除音调数字
    private static func removeToneNumbers(from pinyin: String) -> String {
        let toneNumbers = CharacterSet(charactersIn: "12345")
        return pinyin.components(separatedBy: toneNumbers).joined()
    }
    
    // 单个汉字转拼音
    public static func pinyin(for character: Character) -> [String] {
        let unicodeScalars = character.unicodeScalars
        guard let firstScalar = unicodeScalars.first else {
            return []
        }
        
        // 将 Unicode scalar 转换为大写十六进制字符串
        let unicodeHex = String(format: "%04X", firstScalar.value)
        
        return pinyinMap[unicodeHex] ?? []
    }
    
    // 字符串转拼音
    public static func pinyin(for text: String, separator: String = " ") -> String {
        var result: [String] = []
        
        for character in text {
            let pinyins = pinyin(for: character)
            if pinyins.isEmpty {
                // 如果不是汉字，保留原字符
                result.append(String(character))
            } else {
                // 使用第一个拼音（或多个拼音用逗号连接）
                result.append(pinyins.first!)
            }
        }
        
        return result.joined(separator: separator)
    }
    
    // 获取首字母
    public static func firstLetters(for text: String, separator: String = "") -> String {
        var result: [String] = []
        
        for character in text {
            let pinyins = pinyin(for: character)
            if let firstPinyin = pinyins.first, let firstChar = firstPinyin.first {
                result.append(String(firstChar))
            } else {
                // 如果不是汉字，保留原字符的首字母
                result.append(String(character))
            }
        }
        
        return result.joined(separator: separator)
    }
}


extension ChinesePinyinConverter {
    
    // 带音调的拼音（需要原始数据包含音调信息）
    public static func pinyinWithTones(for text: String) -> [String] {
        // 这里可以实现带音调的版本
        // 需要修改映射表存储带音调的拼音
        return []
    }
    
    // 批量转换
    public static func batchConvert(_ texts: [String]) -> [String] {
        return texts.map { pinyin(for: $0) }
    }
    
    // 检查是否为汉字
    public static func isChineseCharacter(_ character: Character) -> Bool {
        let pinyins = pinyin(for: character)
        return !pinyins.isEmpty
    }
}

// 字符串扩展，提供更便捷的调用方式
extension String {
    var pinyin: String {
        return ChinesePinyinConverter.pinyin(for: self, separator: "")
    }
    
    var pinyinFirstLetters: String {
        return ChinesePinyinConverter.firstLetters(for: self)
    }
}

extension ChinesePinyinConverter {
    // 从 Bundle 资源加载
    public static func initialize(fileName: String) throws {
        // 获取资源文件的URL
        guard let fileURL = Bundle.module.url(forResource: fileName, withExtension: "txt") else {
            throw NSError(domain: "PinyinDataError", code: 404, userInfo: [NSLocalizedDescriptionKey: "未找到拼音数据文件。"])
        }
        // 将文件内容读取到字符串
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        initialize(with: content)
    }
    
    // 导出映射表
    public static func exportMapping() -> String {
        var result = ""
        for (unicode, pinyins) in pinyinMap.sorted(by: { $0.key < $1.key }) {
            result += "\(unicode) (\(pinyins.joined(separator: ",")))\n"
        }
        return result
    }
}
