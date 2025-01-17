// (c) 2021 and onwards The vChewing Project (MIT-NTL License).
// ====================
// This code is released under the MIT license (SPDX-License-Identifier: MIT)
// ... with NTL restriction stating that:
// No trademark license is granted to use the trade names, trademarks, service
// marks, or product names of Contributor, except as required to fulfill notice
// requirements defined in MIT License.

import AppKit
import LangModelAssembly
import NotifierUI
import Shared
import SwiftExtension

public class LMMgr {
  public static var shared = LMMgr()
  public private(set) static var lmCHS = vChewingLM.LMInstantiator(isCHS: true)
  public private(set) static var lmCHT = vChewingLM.LMInstantiator(isCHS: false)
  public private(set) static var uomCHS = vChewingLM.LMUserOverride(
    dataURL: LMMgr.userOverrideModelDataURL(.imeModeCHS))
  public private(set) static var uomCHT = vChewingLM.LMUserOverride(
    dataURL: LMMgr.userOverrideModelDataURL(.imeModeCHT))

  public static var currentLM: vChewingLM.LMInstantiator {
    Self.getLM(mode: IMEApp.currentInputMode)
  }

  public static var currentUOM: vChewingLM.LMUserOverride {
    Self.getUOM(mode: IMEApp.currentInputMode)
  }

  public static func getLM(mode: Shared.InputMode) -> vChewingLM.LMInstantiator {
    switch mode {
    case .imeModeCHS:
      return Self.lmCHS
    case .imeModeCHT:
      return Self.lmCHT
    case .imeModeNULL:
      return .init()
    }
  }

  public static func getUOM(mode: Shared.InputMode) -> vChewingLM.LMUserOverride {
    switch mode {
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
    Self.loadUserPhrasesData()
  }

  public static func loadCoreLanguageModelFile(
    filenameSansExtension: String, langModel lm: vChewingLM.LMInstantiator
  ) {
    lm.loadLanguageModel(json: Self.getDictionaryData(filenameSansExtension))
  }

  public static func loadDataModelsOnAppDelegate() {
    let globalQueue = DispatchQueue(label: "vChewingLM", qos: .unspecified, attributes: .concurrent)
    var showFinishNotification = false
    let group = DispatchGroup()
    group.enter()
    globalQueue.async {
      if !Self.lmCHT.isCNSDataLoaded {
        Self.lmCHT.loadCNSData(json: Self.getDictionaryData("data-cns"))
      }
      if !Self.lmCHT.isMiscDataLoaded {
        Self.lmCHT.loadMiscData(json: Self.getDictionaryData("data-zhuyinwen"))
      }
      if !Self.lmCHT.isSymbolDataLoaded {
        Self.lmCHT.loadSymbolData(json: Self.getDictionaryData("data-symbols"))
      }
      if !Self.lmCHS.isCNSDataLoaded {
        Self.lmCHS.loadCNSData(json: Self.getDictionaryData("data-cns"))
      }
      if !Self.lmCHS.isMiscDataLoaded {
        Self.lmCHS.loadMiscData(json: Self.getDictionaryData("data-zhuyinwen"))
      }
      if !Self.lmCHS.isSymbolDataLoaded {
        Self.lmCHS.loadSymbolData(json: Self.getDictionaryData("data-symbols"))
      }
      group.leave()
    }
    if !Self.lmCHT.isCoreLMLoaded {
      showFinishNotification = true
      Notifier.notify(
        message: NSLocalizedString("Loading CHT Core Dict...", comment: "")
      )
      group.enter()
      globalQueue.async {
        loadCoreLanguageModelFile(filenameSansExtension: "data-cht", langModel: Self.lmCHT)
        group.leave()
      }
    }
    if !Self.lmCHS.isCoreLMLoaded {
      showFinishNotification = true
      Notifier.notify(
        message: NSLocalizedString("Loading CHS Core Dict...", comment: "")
      )
      group.enter()
      globalQueue.async {
        loadCoreLanguageModelFile(filenameSansExtension: "data-chs", langModel: Self.lmCHS)
        group.leave()
      }
    }
    group.notify(queue: DispatchQueue.main) {
      if showFinishNotification {
        Notifier.notify(
          message: NSLocalizedString("Core Dict loading complete.", comment: "")
        )
      }
    }
  }

  public static func loadDataModel(_ mode: Shared.InputMode) {
    let globalQueue = DispatchQueue(label: "vChewingLM_Lazy", qos: .unspecified, attributes: .concurrent)
    var showFinishNotification = false
    let group = DispatchGroup()
    group.enter()
    globalQueue.async {
      let lm = Self.getLM(mode: mode)
      if !lm.isCNSDataLoaded {
        lm.loadCNSData(json: Self.getDictionaryData("data-cns"))
      }
      if !lm.isMiscDataLoaded {
        lm.loadMiscData(json: Self.getDictionaryData("data-zhuyinwen"))
      }
      if !lm.isSymbolDataLoaded {
        lm.loadSymbolData(json: Self.getDictionaryData("data-symbols"))
      }
      group.leave()
    }
    switch mode {
    case .imeModeCHS:
      if !Self.lmCHS.isCoreLMLoaded {
        showFinishNotification = true
        Notifier.notify(
          message: NSLocalizedString("Loading CHS Core Dict...", comment: "")
        )
        group.enter()
        globalQueue.async {
          loadCoreLanguageModelFile(filenameSansExtension: "data-chs", langModel: Self.lmCHS)
          group.leave()
        }
      }
    case .imeModeCHT:
      if !Self.lmCHT.isCoreLMLoaded {
        showFinishNotification = true
        Notifier.notify(
          message: NSLocalizedString("Loading CHT Core Dict...", comment: "")
        )
        group.enter()
        globalQueue.async {
          loadCoreLanguageModelFile(filenameSansExtension: "data-cht", langModel: Self.lmCHT)
          group.leave()
        }
      }
    default: break
    }
    group.notify(queue: DispatchQueue.main) {
      if showFinishNotification {
        Notifier.notify(
          message: NSLocalizedString("Core Dict loading complete.", comment: "")
        )
      }
    }
  }

  public static func reloadFactoryDictionaryFiles() {
    Broadcaster.shared.eventForReloadingRevLookupData = .init()
    LMMgr.lmCHS.resetFactoryJSONModels()
    LMMgr.lmCHT.resetFactoryJSONModels()
    if PrefMgr.shared.onlyLoadFactoryLangModelsIfNeeded {
      LMMgr.loadDataModel(IMEApp.currentInputMode)
    } else {
      LMMgr.loadDataModelsOnAppDelegate()
    }
  }

  /// 載入磁帶資料。
  /// - Remark: cassettePath() 會在輸入法停用磁帶時直接返回
  public static func loadCassetteData() {
    vChewingLM.LMInstantiator.loadCassetteData(path: cassettePath())
  }

  public static func loadUserPhrasesData(type: vChewingLM.ReplacableUserDataType? = nil) {
    guard let type = type else {
      Self.lmCHT.loadUserPhrasesData(
        path: userDictDataURL(mode: .imeModeCHT, type: .thePhrases).path,
        filterPath: userDictDataURL(mode: .imeModeCHT, type: .theFilter).path
      )
      Self.lmCHS.loadUserPhrasesData(
        path: userDictDataURL(mode: .imeModeCHS, type: .thePhrases).path,
        filterPath: userDictDataURL(mode: .imeModeCHS, type: .theFilter).path
      )
      Self.lmCHT.loadUserSymbolData(path: userDictDataURL(mode: .imeModeCHT, type: .theSymbols).path)
      Self.lmCHS.loadUserSymbolData(path: userDictDataURL(mode: .imeModeCHS, type: .theSymbols).path)

      if PrefMgr.shared.associatedPhrasesEnabled { Self.loadUserAssociatesData() }
      if PrefMgr.shared.phraseReplacementEnabled { Self.loadUserPhraseReplacement() }
      if PrefMgr.shared.useSCPCTypingMode { Self.loadSCPCSequencesData() }

      Self.uomCHT.loadData(fromURL: userOverrideModelDataURL(.imeModeCHT))
      Self.uomCHS.loadData(fromURL: userOverrideModelDataURL(.imeModeCHS))

      CandidateNode.load(url: Self.userSymbolMenuDataURL())
      return
    }
    switch type {
    case .thePhrases:
      Self.lmCHT.loadUserPhrasesData(
        path: userDictDataURL(mode: .imeModeCHT, type: .thePhrases).path,
        filterPath: nil
      )
      Self.lmCHS.loadUserPhrasesData(
        path: userDictDataURL(mode: .imeModeCHS, type: .thePhrases).path,
        filterPath: nil
      )
    case .theFilter:
      DispatchQueue.main.async {
        Self.reloadUserFilterDirectly(mode: IMEApp.currentInputMode)
      }
      DispatchQueue.main.async {
        Self.reloadUserFilterDirectly(mode: IMEApp.currentInputMode.reversed)
      }
    case .theReplacements:
      if PrefMgr.shared.phraseReplacementEnabled { Self.loadUserPhraseReplacement() }
    case .theAssociates:
      if PrefMgr.shared.associatedPhrasesEnabled { Self.loadUserAssociatesData() }
    case .theSymbols:
      Self.lmCHT.loadUserSymbolData(
        path: Self.userDictDataURL(mode: .imeModeCHT, type: .theSymbols).path
      )
      Self.lmCHS.loadUserSymbolData(
        path: Self.userDictDataURL(mode: .imeModeCHS, type: .theSymbols).path
      )
    }
  }

  public static func loadUserAssociatesData() {
    Self.lmCHT.loadUserAssociatesData(
      path: Self.userDictDataURL(mode: .imeModeCHT, type: .theAssociates).path
    )
    Self.lmCHS.loadUserAssociatesData(
      path: Self.userDictDataURL(mode: .imeModeCHS, type: .theAssociates).path
    )
  }

  public static func loadUserPhraseReplacement() {
    Self.lmCHT.loadReplacementsData(
      path: Self.userDictDataURL(mode: .imeModeCHT, type: .theReplacements).path
    )
    Self.lmCHS.loadReplacementsData(
      path: Self.userDictDataURL(mode: .imeModeCHS, type: .theReplacements).path
    )
  }

  public static func loadSCPCSequencesData() {
    Self.lmCHT.loadSCPCSequencesData(
      path: Self.etenSCPCSequencesURL(.imeModeCHT).path
    )
    Self.lmCHS.loadSCPCSequencesData(
      path: Self.etenSCPCSequencesURL(.imeModeCHS).path
    )
  }

  public static func reloadUserFilterDirectly(mode: Shared.InputMode) {
    Self.getLM(mode: mode).reloadUserFilterDirectly(path: userDictDataURL(mode: mode, type: .theFilter).path)
  }

  public static func checkIfPhrasePairExists(
    userPhrase: String,
    mode: Shared.InputMode,
    keyArray: [String],
    factoryDictionaryOnly: Bool = false
  ) -> Bool {
    Self.getLM(mode: mode).hasKeyValuePairFor(
      keyArray: keyArray, value: userPhrase, factoryDictionaryOnly: factoryDictionaryOnly
    )
  }

  public static func checkIfPhrasePairIsFiltered(
    userPhrase: String,
    mode: Shared.InputMode,
    keyArray: [String]
  ) -> Bool {
    Self.getLM(mode: mode).isPairFiltered(pair: .init(keyArray: keyArray, value: userPhrase))
  }

  public static func countPhrasePairs(
    keyArray: [String],
    mode: Shared.InputMode,
    factoryDictionaryOnly: Bool = false
  ) -> Int {
    Self.getLM(mode: mode).countKeyValuePairs(
      keyArray: keyArray, factoryDictionaryOnly: factoryDictionaryOnly
    )
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
    Self.lmCHT.isSCPCEnabled = state
    Self.lmCHS.isSCPCEnabled = state
  }

  public static func setCassetteEnabled(_ state: Bool) {
    Self.lmCHT.isCassetteEnabled = state
    Self.lmCHS.isCassetteEnabled = state
  }

  public static func setDeltaOfCalendarYears(_ delta: Int) {
    Self.lmCHT.deltaOfCalendarYears = delta
    Self.lmCHS.deltaOfCalendarYears = delta
  }

  // MARK: UOM

  public static func saveUserOverrideModelData() {
    let globalQueue = DispatchQueue(label: "vChewingLM_UOM", qos: .unspecified, attributes: .concurrent)
    let group = DispatchGroup()
    group.enter()
    globalQueue.async {
      Self.uomCHT.saveData(toURL: userOverrideModelDataURL(.imeModeCHT))
      group.leave()
    }
    group.enter()
    globalQueue.async {
      Self.uomCHS.saveData(toURL: userOverrideModelDataURL(.imeModeCHS))
      group.leave()
    }
    _ = group.wait(timeout: .distantFuture)
    group.notify(queue: DispatchQueue.main) {}
  }

  public static func bleachSpecifiedSuggestions(targets: [String], mode: Shared.InputMode) {
    Self.getUOM(mode: mode).bleachSpecifiedSuggestions(targets: targets, saveCallback: { Self.getUOM(mode: mode).saveData() })
  }

  public static func removeUnigramsFromUserOverrideModel(_ mode: Shared.InputMode) {
    Self.getUOM(mode: mode).bleachUnigrams(saveCallback: { Self.getUOM(mode: mode).saveData() })
  }

  public static func relocateWreckedUOMData() {
    func dateStringTag(date givenDate: Date) -> String {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyyMMdd-HHmm"
      dateFormatter.timeZone = .current
      let strDate = dateFormatter.string(from: givenDate)
      return strDate
    }

    let urls: [URL] = [userOverrideModelDataURL(.imeModeCHS), userOverrideModelDataURL(.imeModeCHT)]
    let folderURL = URL(fileURLWithPath: dataFolderPath(isDefaultFolder: true)).deletingLastPathComponent()
    urls.forEach { oldURL in
      let newFileName = "[UOM-CRASH][\(dateStringTag(date: .init()))]\(oldURL.lastPathComponent)"
      let newURL = folderURL.appendingPathComponent(newFileName)
      try? FileManager.default.moveItem(at: oldURL, to: newURL)
    }
  }

  public static func clearUserOverrideModelData(_ mode: Shared.InputMode = .imeModeNULL) {
    Self.getUOM(mode: mode).clearData(withURL: userOverrideModelDataURL(mode))
  }
}
