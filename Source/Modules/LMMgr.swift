// (c) 2021 and onwards The vChewing Project (MIT-NTL License).
// ====================
// This code is released under the MIT license (SPDX-License-Identifier: MIT)
// ... with NTL restriction stating that:
// No trademark license is granted to use the trade names, trademarks, service
// marks, or product names of Contributor, except as required to fulfill notice
// requirements defined in MIT License.

import BookmarkManager
import LangModelAssembly
import Megrez
import Shared

/// 使用者辭典資料預設範例檔案名稱。
private let kTemplateNameUserPhrases = "template-userphrases"
private let kTemplateNameUserReplacements = "template-replacements"
private let kTemplateNameUserExclusions = "template-exclusions"
private let kTemplateNameUserSymbolPhrases = "template-usersymbolphrases"
private let kTemplateNameUserAssociatesCHS = "template-associatedPhrases-chs"
private let kTemplateNameUserAssociatesCHT = "template-associatedPhrases-cht"

public enum LMMgr {
  public private(set) static var lmCHS = vChewingLM.LMInstantiator(isCHS: true)
  public private(set) static var lmCHT = vChewingLM.LMInstantiator(isCHS: false)
  public private(set) static var uomCHS = vChewingLM.LMUserOverride(
    dataURL: LMMgr.userOverrideModelDataURL(.imeModeCHS))
  public private(set) static var uomCHT = vChewingLM.LMUserOverride(
    dataURL: LMMgr.userOverrideModelDataURL(.imeModeCHT))

  public static func currentLM() -> vChewingLM.LMInstantiator {
    switch IMEApp.currentInputMode {
      case .imeModeCHS:
        return Self.lmCHS
      case .imeModeCHT:
        return Self.lmCHT
      case .imeModeNULL:
        return .init()
    }
  }

  public static func currentUOM() -> vChewingLM.LMUserOverride {
    switch IMEApp.currentInputMode {
      case .imeModeCHS:
        return Self.uomCHS
      case .imeModeCHT:
        return Self.uomCHT
      case .imeModeNULL:
        return .init(dataURL: Self.userOverrideModelDataURL(IMEApp.currentInputMode))
    }
  }

  // MARK: - Functions reacting directly with language models.

  public static func initUserLangModels() {
    Self.chkUserLMFilesExist(.imeModeCHT)
    Self.chkUserLMFilesExist(.imeModeCHS)
    // LMMgr 的 loadUserPhrases 等函式在自動讀取 dataFolderPath 時，
    // 如果發現自訂目錄不可用，則會自動抹去自訂目錄設定、改採預設目錄。
    // 所以這裡不需要特別處理。
    if PrefMgr.shared.associatedPhrasesEnabled { Self.loadUserAssociatesData() }
    if PrefMgr.shared.phraseReplacementEnabled { Self.loadUserPhraseReplacement() }
    if PrefMgr.shared.useSCPCTypingMode { Self.loadUserSCPCSequencesData() }
    Self.loadUserPhrasesData()
  }

  public static func loadCoreLanguageModelFile(
    filenameSansExtension: String, langModel lm: inout vChewingLM.LMInstantiator
  ) {
    let dataPath: String = Self.getBundleDataPath(filenameSansExtension)
    lm.loadLanguageModel(path: dataPath)
  }

  public static func loadDataModels() {
    if !Self.lmCHT.isCNSDataLoaded {
      Self.lmCHT.loadCNSData(path: getBundleDataPath("data-cns"))
    }
    if !Self.lmCHT.isMiscDataLoaded {
      Self.lmCHT.loadMiscData(path: getBundleDataPath("data-zhuyinwen"))
    }
    if !Self.lmCHT.isSymbolDataLoaded {
      Self.lmCHT.loadSymbolData(path: getBundleDataPath("data-symbols"))
    }
    if !Self.lmCHS.isCNSDataLoaded {
      Self.lmCHS.loadCNSData(path: getBundleDataPath("data-cns"))
    }
    if !Self.lmCHS.isMiscDataLoaded {
      Self.lmCHS.loadMiscData(path: getBundleDataPath("data-zhuyinwen"))
    }
    if !Self.lmCHS.isSymbolDataLoaded {
      Self.lmCHS.loadSymbolData(path: getBundleDataPath("data-symbols"))
    }
    if !Self.lmCHT.isLanguageModelLoaded {
      NotifierController.notify(
        message: NSLocalizedString("Loading CHT Core Dict...", comment: "")
      )
      loadCoreLanguageModelFile(filenameSansExtension: "data-cht", langModel: &Self.lmCHT)
      NotifierController.notify(
        message: NSLocalizedString("Core Dict loading complete.", comment: "")
      )
    }
    if !Self.lmCHS.isLanguageModelLoaded {
      NotifierController.notify(
        message: NSLocalizedString("Loading CHS Core Dict...", comment: "")
      )
      loadCoreLanguageModelFile(filenameSansExtension: "data-chs", langModel: &Self.lmCHS)
      NotifierController.notify(
        message: NSLocalizedString("Core Dict loading complete.", comment: "")
      )
    }
  }

  public static func loadDataModel(_ mode: InputMode) {
    switch mode {
      case .imeModeCHS:
        if !Self.lmCHS.isMiscDataLoaded {
          Self.lmCHS.loadMiscData(path: getBundleDataPath("data-zhuyinwen"))
        }
        if !Self.lmCHS.isSymbolDataLoaded {
          Self.lmCHS.loadSymbolData(path: getBundleDataPath("data-symbols"))
        }
        if !Self.lmCHS.isCNSDataLoaded {
          Self.lmCHS.loadCNSData(path: getBundleDataPath("data-cns"))
        }
        if !Self.lmCHS.isLanguageModelLoaded {
          NotifierController.notify(
            message: NSLocalizedString("Loading CHS Core Dict...", comment: "")
          )
          loadCoreLanguageModelFile(filenameSansExtension: "data-chs", langModel: &Self.lmCHS)
          NotifierController.notify(
            message: NSLocalizedString("Core Dict loading complete.", comment: "")
          )
        }
      case .imeModeCHT:
        if !Self.lmCHT.isMiscDataLoaded {
          Self.lmCHT.loadMiscData(path: getBundleDataPath("data-zhuyinwen"))
        }
        if !Self.lmCHT.isSymbolDataLoaded {
          Self.lmCHT.loadSymbolData(path: getBundleDataPath("data-symbols"))
        }
        if !Self.lmCHT.isCNSDataLoaded {
          Self.lmCHT.loadCNSData(path: getBundleDataPath("data-cns"))
        }
        if !Self.lmCHT.isLanguageModelLoaded {
          NotifierController.notify(
            message: NSLocalizedString("Loading CHT Core Dict...", comment: "")
          )
          loadCoreLanguageModelFile(filenameSansExtension: "data-cht", langModel: &Self.lmCHT)
          NotifierController.notify(
            message: NSLocalizedString("Core Dict loading complete.", comment: "")
          )
        }
      case .imeModeNULL:
        break
    }
  }

  public static func loadUserPhrasesData() {
    Self.lmCHT.loadUserPhrasesData(
      path: userPhrasesDataURL(InputMode.imeModeCHT).path,
      filterPath: userFilteredDataURL(InputMode.imeModeCHT).path
    )
    Self.lmCHS.loadUserPhrasesData(
      path: userPhrasesDataURL(InputMode.imeModeCHS).path,
      filterPath: userFilteredDataURL(InputMode.imeModeCHS).path
    )
    Self.lmCHT.loadUserSymbolData(path: userSymbolDataURL(InputMode.imeModeCHT).path)
    Self.lmCHS.loadUserSymbolData(path: userSymbolDataURL(InputMode.imeModeCHS).path)

    Self.uomCHT.loadData(fromURL: userOverrideModelDataURL(InputMode.imeModeCHT))
    Self.uomCHS.loadData(fromURL: userOverrideModelDataURL(InputMode.imeModeCHS))

    CandidateNode.load(url: Self.userSymbolMenuDataURL())
  }

  public static func loadUserAssociatesData() {
    Self.lmCHT.loadUserAssociatesData(
      path: Self.userAssociatesDataURL(InputMode.imeModeCHT).path
    )
    Self.lmCHS.loadUserAssociatesData(
      path: Self.userAssociatesDataURL(InputMode.imeModeCHS).path
    )
  }

  public static func loadUserPhraseReplacement() {
    Self.lmCHT.loadReplacementsData(
      path: Self.userReplacementsDataURL(InputMode.imeModeCHT).path
    )
    Self.lmCHS.loadReplacementsData(
      path: Self.userReplacementsDataURL(InputMode.imeModeCHS).path
    )
  }

  public static func loadUserSCPCSequencesData() {
    Self.lmCHT.loadUserSCPCSequencesData(
      path: Self.userSCPCSequencesURL(InputMode.imeModeCHT).path
    )
    Self.lmCHS.loadUserSCPCSequencesData(
      path: Self.userSCPCSequencesURL(InputMode.imeModeCHS).path
    )
  }

  public static func checkIfUserPhraseExist(
    userPhrase: String,
    mode: InputMode,
    key unigramKey: String
  ) -> Bool {
    let unigrams: [Megrez.Unigram] =
      (mode == InputMode.imeModeCHT)
      ? Self.lmCHT.unigramsFor(key: unigramKey) : Self.lmCHS.unigramsFor(key: unigramKey)
    for unigram in unigrams {
      if unigram.value == userPhrase {
        return true
      }
    }
    return false
  }

  public static func setPhraseReplacementEnabled(_ state: Bool) {
    Self.lmCHT.isPhraseReplacementEnabled = state
    Self.lmCHS.isPhraseReplacementEnabled = state
  }

  public static func setCNSEnabled(_ state: Bool) {
    Self.lmCHT.isCNSEnabled = state
    Self.lmCHS.isCNSEnabled = state
  }

  public static func setSymbolEnabled(_ state: Bool) {
    Self.lmCHT.isSymbolEnabled = state
    Self.lmCHS.isSymbolEnabled = state
  }

  public static func setSCPCEnabled(_ state: Bool) {
    Self.lmCHS.isSCPCEnabled = state
    Self.lmCHT.isSCPCEnabled = state
  }

  public static func setDeltaOfCalendarYears(_ delta: Int) {
    Self.lmCHS.deltaOfCalendarYears = delta
    Self.lmCHT.deltaOfCalendarYears = delta
  }

  // MARK: - 獲取當前輸入法封包內的原廠核心語彙檔案所在路徑

  public static func getBundleDataPath(_ filenameSansExt: String) -> String {
    Bundle.main.path(forResource: filenameSansExt, ofType: "plist")!
  }

  // MARK: - 使用者語彙檔案的具體檔案名稱路徑定義

  // Swift 的 appendingPathComponent 需要藉由 URL 完成，最後再用 .path 轉為路徑。

  /// 使用者語彙辭典資料路徑。
  /// - Parameter mode: 簡繁體輸入模式。
  /// - Returns: 資料路徑（URL）。
  public static func userPhrasesDataURL(_ mode: InputMode) -> URL {
    let fileName = (mode == InputMode.imeModeCHT) ? "userdata-cht.txt" : "userdata-chs.txt"
    return URL(fileURLWithPath: dataFolderPath(isDefaultFolder: false)).appendingPathComponent(fileName)
  }

  /// 使用者繪文字符號辭典資料路徑。
  /// - Parameter mode: 簡繁體輸入模式。
  /// - Returns: 資料路徑（URL）。
  public static func userSymbolDataURL(_ mode: InputMode) -> URL {
    let fileName = (mode == InputMode.imeModeCHT) ? "usersymbolphrases-cht.txt" : "usersymbolphrases-chs.txt"
    return URL(fileURLWithPath: dataFolderPath(isDefaultFolder: false)).appendingPathComponent(fileName)
  }

  /// 使用者聯想詞資料路徑。
  /// - Parameter mode: 簡繁體輸入模式。
  /// - Returns: 資料路徑（URL）。
  public static func userAssociatesDataURL(_ mode: InputMode) -> URL {
    let fileName = (mode == InputMode.imeModeCHT) ? "associatedPhrases-cht.txt" : "associatedPhrases-chs.txt"
    return URL(fileURLWithPath: dataFolderPath(isDefaultFolder: false)).appendingPathComponent(fileName)
  }

  /// 使用者語彙濾除表資料路徑。
  /// - Parameter mode: 簡繁體輸入模式。
  /// - Returns: 資料路徑（URL）。
  public static func userFilteredDataURL(_ mode: InputMode) -> URL {
    let fileName = (mode == InputMode.imeModeCHT) ? "exclude-phrases-cht.txt" : "exclude-phrases-chs.txt"
    return URL(fileURLWithPath: dataFolderPath(isDefaultFolder: false)).appendingPathComponent(fileName)
  }

  /// 使用者語彙置換表資料路徑。
  /// - Parameter mode: 簡繁體輸入模式。
  /// - Returns: 資料路徑（URL）。
  public static func userReplacementsDataURL(_ mode: InputMode) -> URL {
    let fileName = (mode == InputMode.imeModeCHT) ? "phrases-replacement-cht.txt" : "phrases-replacement-chs.txt"
    return URL(fileURLWithPath: dataFolderPath(isDefaultFolder: false)).appendingPathComponent(fileName)
  }

  /// 使用者逐字選字模式候選字詞順序資料路徑。
  /// - Parameter mode: 簡繁體輸入模式。
  /// - Returns: 資料路徑（URL）。
  public static func userSCPCSequencesURL(_ mode: InputMode) -> URL {
    let fileName = (mode == InputMode.imeModeCHT) ? "data-plain-bpmf-cht.plist" : "data-plain-bpmf-chs.plist"
    return URL(fileURLWithPath: dataFolderPath(isDefaultFolder: false)).appendingPathComponent(fileName)
  }

  /// 使用者波浪符號選單資料路徑。
  /// - Returns: 資料路徑（URL）。
  public static func userSymbolMenuDataURL() -> URL {
    let fileName = "symbols.dat"
    return URL(fileURLWithPath: dataFolderPath(isDefaultFolder: false)).appendingPathComponent(fileName)
  }

  /// 使用者半衰記憶模組資料的存取頻次特別高，且資料新陳代謝速度快，所以只適合放在預設的使用者資料目錄下。
  /// 也就是「~/Library/Application Support/vChewing/」目錄下，且不會隨著使用者辭典目錄的改變而改變。
  /// - Parameter mode: 簡繁體輸入模式。
  /// - Returns: 資料路徑（URL）。
  public static func userOverrideModelDataURL(_ mode: InputMode) -> URL {
    let fileName: String = {
      switch mode {
        case .imeModeCHS: return "vChewing_override-model-data-chs.dat"
        case .imeModeCHT: return "vChewing_override-model-data-cht.dat"
        case .imeModeNULL: return "vChewing_override-model-data-dummy.dat"
      }
    }()

    return URL(
      fileURLWithPath: dataFolderPath(isDefaultFolder: true)
    ).deletingLastPathComponent().appendingPathComponent(fileName)
  }

  // MARK: - 檢查具體的使用者語彙檔案是否存在

  public static func ensureFileExists(
    _ fileURL: URL, populateWithTemplate templateBasename: String = "1145141919810",
    extension ext: String = "txt"
  ) -> Bool {
    let filePath = fileURL.path
    if !FileManager.default.fileExists(atPath: filePath) {
      let templateURL = Bundle.main.url(forResource: templateBasename, withExtension: ext)
      var templateData = Data("".utf8)
      if templateBasename != "" {
        do {
          try templateData = Data(contentsOf: templateURL ?? URL(fileURLWithPath: ""))
        } catch {
          templateData = Data("".utf8)
        }
        do {
          try templateData.write(to: URL(fileURLWithPath: filePath))
        } catch {
          vCLog("Failed to write template data to: \(filePath)")
          return false
        }
      }
    }
    return true
  }

  @discardableResult public static func chkUserLMFilesExist(_ mode: InputMode) -> Bool {
    if !userDataFolderExists {
      return false
    }
    /// CandidateNode 資料與 UserOverrideModel 半衰模組資料檔案不需要強行確保存在。
    /// 前者的話，需要該檔案存在的人自己會建立。
    /// 後者的話，你在敲字時自己就會建立。
    if !ensureFileExists(userPhrasesDataURL(mode), populateWithTemplate: kTemplateNameUserPhrases)
      || !ensureFileExists(
        userAssociatesDataURL(mode),
        populateWithTemplate: mode == .imeModeCHS ? kTemplateNameUserAssociatesCHS : kTemplateNameUserAssociatesCHT
      )
      || !ensureFileExists(userSCPCSequencesURL(mode))
      || !ensureFileExists(userFilteredDataURL(mode), populateWithTemplate: kTemplateNameUserExclusions)
      || !ensureFileExists(userReplacementsDataURL(mode), populateWithTemplate: kTemplateNameUserReplacements)
      || !ensureFileExists(userSymbolDataURL(mode), populateWithTemplate: kTemplateNameUserSymbolPhrases)
    {
      return false
    }

    return true
  }

  // MARK: - 使用者語彙檔案專用目錄的合規性檢查

  // 一次性檢查給定的目錄是否存在寫入合規性（僅用於偏好設定檢查等初步檢查場合，不做任何糾偏行為）
  public static func checkIfSpecifiedUserDataFolderValid(_ folderPath: String?) -> Bool {
    var isFolder = ObjCBool(false)
    let folderExist = FileManager.default.fileExists(atPath: folderPath ?? "", isDirectory: &isFolder)
    // The above "&" mutates the "isFolder" value to the real one received by the "folderExist".

    // 路徑沒有結尾斜槓的話，會導致目錄合規性判定失準。
    // 出於每個型別每個函式的自我責任原則，這裡多檢查一遍也不壞。
    var folderPath = folderPath  // Convert the incoming constant to a variable.
    if isFolder.boolValue {
      folderPath?.ensureTrailingSlash()
    }
    let isFolderWritable = FileManager.default.isWritableFile(atPath: folderPath ?? "")
    // vCLog("mgrLM: Exist: \(folderExist), IsFolder: \(isFolder.boolValue), isWritable: \(isFolderWritable)")
    if ((folderExist && !isFolder.boolValue) || !folderExist) || !isFolderWritable {
      return false
    }

    return true
  }

  // 檢查給定的目錄是否存在寫入合規性、且糾偏，不接受任何傳入變數。
  public static var userDataFolderExists: Bool {
    let folderPath = Self.dataFolderPath(isDefaultFolder: false)
    var isFolder = ObjCBool(false)
    var folderExist = FileManager.default.fileExists(atPath: folderPath, isDirectory: &isFolder)
    // The above "&" mutates the "isFolder" value to the real one received by the "folderExist".
    // 發現目標路徑不是目錄的話：
    // 如果要找的目標路徑是原廠目標路徑的話，先將這個路徑的所指對象更名、再認為目錄不存在。
    // 如果要找的目標路徑不是原廠目標路徑的話，則直接報錯。
    if folderExist, !isFolder.boolValue {
      do {
        if dataFolderPath(isDefaultFolder: false)
          == dataFolderPath(isDefaultFolder: true)
        {
          let formatter = DateFormatter()
          formatter.dateFormat = "YYYYMMDD-HHMM'Hrs'-ss's'"
          let dirAlternative = folderPath + formatter.string(from: Date())
          try FileManager.default.moveItem(atPath: folderPath, toPath: dirAlternative)
        } else {
          throw folderPath
        }
      } catch {
        print("Failed to make path available at: \(error)")
        return false
      }
      folderExist = false
    }
    if !folderExist {
      do {
        try FileManager.default.createDirectory(
          atPath: folderPath,
          withIntermediateDirectories: true,
          attributes: nil
        )
      } catch {
        print("Failed to create folder: \(error)")
        return false
      }
    }
    return true
  }

  // MARK: - 用以讀取使用者語彙檔案目錄的函式，會自動對 PrefMgr 當中的參數糾偏。

  // 當且僅當 PrefMgr 當中的參數不合規（比如非實在路徑、或者無權限寫入）時，才會糾偏。

  public static let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]

  public static func dataFolderPath(isDefaultFolder: Bool) -> String {
    var userDictPathSpecified = PrefMgr.shared.userDataFolderSpecified.expandingTildeInPath
    var userDictPathDefault =
      Self.appSupportURL.appendingPathComponent("vChewing").path.expandingTildeInPath

    userDictPathDefault.ensureTrailingSlash()
    userDictPathSpecified.ensureTrailingSlash()

    if (userDictPathSpecified == userDictPathDefault)
      || isDefaultFolder
    {
      return userDictPathDefault
    }
    if UserDefaults.standard.object(forKey: UserDef.kUserDataFolderSpecified.rawValue) != nil {
      BookmarkManager.shared.loadBookmarks()
      if Self.checkIfSpecifiedUserDataFolderValid(userDictPathSpecified) {
        return userDictPathSpecified
      }
      UserDefaults.standard.removeObject(forKey: UserDef.kUserDataFolderSpecified.rawValue)
    }
    return userDictPathDefault
  }

  // MARK: - 重設使用者語彙檔案目錄

  public static func resetSpecifiedUserDataFolder() {
    UserDefaults.standard.removeObject(forKey: UserDef.kUserDataFolderSpecified.rawValue)
    LMMgr.initUserLangModels()
  }

  // MARK: - 寫入使用者檔案

  public static func writeUserPhrase(
    _ userPhrase: String?, inputMode mode: InputMode, areWeDuplicating: Bool, areWeDeleting: Bool
  ) -> Bool {
    if var currentMarkedPhrase: String = userPhrase {
      if !chkUserLMFilesExist(InputMode.imeModeCHS)
        || !chkUserLMFilesExist(InputMode.imeModeCHT)
      {
        return false
      }

      let theURL = areWeDeleting ? userFilteredDataURL(mode) : userPhrasesDataURL(mode)

      if areWeDuplicating, !areWeDeleting {
        // Do not use ASCII characters to comment here.
        // Otherwise, it will be scrambled by cnvHYPYtoBPMF
        // module shipped in the vChewing Phrase Editor.
        currentMarkedPhrase += "\t#𝙾𝚟𝚎𝚛𝚛𝚒𝚍𝚎"
      }

      if let writeFile = FileHandle(forUpdatingAtPath: theURL.path),
        let data = currentMarkedPhrase.data(using: .utf8),
        let endl = "\n".data(using: .utf8)
      {
        writeFile.seekToEndOfFile()
        writeFile.write(endl)
        writeFile.write(data)
        writeFile.write(endl)
        writeFile.closeFile()
      } else {
        return false
      }

      // We enforce the format consolidation here, since the pragma header
      // will let the UserPhraseLM bypasses the consolidating process on load.
      if !vChewingLM.LMConsolidator.consolidate(path: theURL.path, pragma: false) {
        return false
      }

      // The new FolderMonitor module does NOT monitor cases that files are modified
      // by the current application itself, requiring additional manual loading process here.
      // if !PrefMgr.shared.shouldAutoReloadUserDataFiles {}
      loadUserPhrasesData()
      return true
    }
    return false
  }

  // MARK: - 藉由語彙編輯器開啟使用者檔案

  public static func checkIfUserFilesExistBeforeOpening() -> Bool {
    if !Self.chkUserLMFilesExist(InputMode.imeModeCHS)
      || !Self.chkUserLMFilesExist(InputMode.imeModeCHT)
    {
      let content = String(
        format: NSLocalizedString(
          "Please check the permission at \"%@\".", comment: ""
        ),
        Self.dataFolderPath(isDefaultFolder: false)
      )
      DispatchQueue.main.async {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Unable to create the user phrase file.", comment: "")
        alert.informativeText = content
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.runModal()
        NSApp.setActivationPolicy(.accessory)
      }
      return false
    }
    return true
  }

  public static func openPhraseFile(fromURL url: URL) {
    if !Self.checkIfUserFilesExistBeforeOpening() { return }
    DispatchQueue.main.async {
      NSWorkspace.shared.openFile(url.path, withApplication: "vChewingPhraseEditor")
    }
  }

  // MARK: UOM

  public static func saveUserOverrideModelData() {
    DispatchQueue.main.async {
      Self.uomCHT.saveData(toURL: userOverrideModelDataURL(InputMode.imeModeCHT))
    }
    DispatchQueue.main.async {
      Self.uomCHS.saveData(toURL: userOverrideModelDataURL(InputMode.imeModeCHS))
    }
  }

  public static func removeUnigramsFromUserOverrideModel(_ mode: InputMode) {
    switch mode {
      case .imeModeCHS:
        Self.uomCHT.bleachUnigrams(saveCallback: { Self.uomCHT.saveData() })
      case .imeModeCHT:
        Self.uomCHS.bleachUnigrams(saveCallback: { Self.uomCHS.saveData() })
      case .imeModeNULL:
        break
    }
  }

  public static func clearUserOverrideModelData(_ mode: InputMode = .imeModeNULL) {
    switch mode {
      case .imeModeCHS:
        Self.uomCHS.clearData(withURL: userOverrideModelDataURL(InputMode.imeModeCHS))
      case .imeModeCHT:
        Self.uomCHT.clearData(withURL: userOverrideModelDataURL(InputMode.imeModeCHT))
      case .imeModeNULL:
        break
    }
  }
}
