// (c) 2021 and onwards The vChewing Project (MIT-NTL License).
// ====================
// This code is released under the MIT license (SPDX-License-Identifier: MIT)
// ... with NTL restriction stating that:
// No trademark license is granted to use the trade names, trademarks, service
// marks, or product names of Contributor, except as required to fulfill notice
// requirements defined in MIT License.

import Shared
import SwiftExtension
import SwiftUI

@available(macOS 13, *)
public struct VwrSettingsPaneGeneral: View {
  @Binding var appleLanguageTag: String

  public init() {
    _appleLanguageTag = .init(
      get: {
        let loadedValue = (UserDefaults.standard.array(forKey: UserDef.kAppleLanguages.rawValue) as? [String] ?? ["auto"]).joined()
        let plistValueNotExist = (UserDefaults.standard.object(forKey: UserDef.kAppleLanguages.rawValue) == nil)
        let targetToCheck = (plistValueNotExist || loadedValue.isEmpty) ? "auto" : loadedValue
        return Shared.arrSupportedLocales.contains(targetToCheck) ? (plistValueNotExist ? "auto" : loadedValue) : "auto"
      }, set: { newValue in
        var newValue = newValue
        if newValue.isEmpty || newValue == "auto" {
          UserDefaults.standard.removeObject(forKey: UserDef.kAppleLanguages.rawValue)
        }
        if newValue == "auto" { newValue = "" }
        guard PrefMgr.shared.appleLanguages.joined() != newValue else { return }
        if !newValue.isEmpty { PrefMgr.shared.appleLanguages = [newValue] }
        NSLog("vChewing App self-terminated due to UI language change.")
        NSApp.terminate(nil)
      }
    )
  }

  // MARK: - AppStorage Variables

  @AppStorage(wrappedValue: true, UserDef.kAutoCorrectReadingCombination.rawValue)
  private var autoCorrectReadingCombination: Bool

  @AppStorage(wrappedValue: false, UserDef.kKeepReadingUponCompositionError.rawValue)
  private var keepReadingUponCompositionError: Bool

  @AppStorage(wrappedValue: false, UserDef.kShowHanyuPinyinInCompositionBuffer.rawValue)
  private var showHanyuPinyinInCompositionBuffer: Bool

  @AppStorage(wrappedValue: false, UserDef.kClassicHaninKeyboardSymbolModeShortcutEnabled.rawValue)
  private var classicHaninKeyboardSymbolModeShortcutEnabled: Bool

  @AppStorage(wrappedValue: false, UserDef.kUseSCPCTypingMode.rawValue)
  private var useSCPCTypingMode: Bool

  @AppStorage(wrappedValue: true, UserDef.kShouldNotFartInLieuOfBeep.rawValue)
  private var shouldNotFartInLieuOfBeep: Bool

  @AppStorage(wrappedValue: false, UserDef.kCheckUpdateAutomatically.rawValue)
  private var checkUpdateAutomatically: Bool

  @AppStorage(wrappedValue: false, UserDef.kIsDebugModeEnabled.rawValue)
  private var isDebugModeEnabled: Bool

  // MARK: - Main View

  public var body: some View {
    ScrollView {
      Form {
        VStack(alignment: .leading) {
          Text(
            "\u{2022} "
              + NSLocalizedString(
                "Please use mouse wheel to scroll each page if needed. The CheatSheet is available in the IME menu.",
                comment: ""
              ) + "\n\u{2022} "
              + NSLocalizedString(
                "Note: The “Delete ⌫” key on Mac keyboard is named as “BackSpace ⌫” here in order to distinguish the real “Delete ⌦” key from full-sized desktop keyboards. If you want to use the real “Delete ⌦” key on a Mac keyboard with no numpad equipped, you have to press “Fn+⌫” instead.",
                comment: ""
              )
          )
          .settingsDescription()
          Picker("UI Language:", selection: $appleLanguageTag) {
            Text(LocalizedStringKey("Follow OS settings")).tag("auto")
            Text(LocalizedStringKey("Simplified Chinese")).tag("zh-Hans")
            Text(LocalizedStringKey("Traditional Chinese")).tag("zh-Hant")
            Text(LocalizedStringKey("Japanese")).tag("ja")
            Text(LocalizedStringKey("English")).tag("en")
          }
          Text(LocalizedStringKey("Change user interface language (will reboot the IME)."))
            .settingsDescription()
        }

        // MARK: (header: Text("Typing Settings:"))

        Section {
          Toggle(
            LocalizedStringKey("Automatically correct reading combinations when typing"),
            isOn: $autoCorrectReadingCombination
          )
          Toggle(
            LocalizedStringKey("Show Hanyu-Pinyin in the inline composition buffer"),
            isOn: $showHanyuPinyinInCompositionBuffer
          )
          Toggle(
            LocalizedStringKey("Allow backspace-editing miscomposed readings"),
            isOn: $keepReadingUponCompositionError
          )
          Toggle(
            LocalizedStringKey("Also use “\\” or “¥” key for Hanin Keyboard Symbol Input"),
            isOn: $classicHaninKeyboardSymbolModeShortcutEnabled
          )
          VStack(alignment: .leading) {
            Toggle(
              LocalizedStringKey("Emulating select-candidate-per-character mode"),
              isOn: $useSCPCTypingMode.onChange {
                guard useSCPCTypingMode else { return }
                LMMgr.loadSCPCSequencesData()
              }
            )
            Text(LocalizedStringKey("An accommodation for elder computer users."))
              .settingsDescription()
          }
          if Date.isTodayTheDate(from: 0401) {
            Toggle(
              LocalizedStringKey("Stop farting (when typed phonetic combination is invalid, etc.)"),
              isOn: $shouldNotFartInLieuOfBeep.onChange {
                let content = String(
                  format: NSLocalizedString(
                    "You are about to uncheck this fart suppressor. You are responsible for all consequences lead by letting people nearby hear the fart sound come from your computer. We strongly advise against unchecking this in any public circumstance that prohibits NSFW netas.",
                    comment: ""
                  ))
                let alert = NSAlert(error: NSLocalizedString("Warning", comment: ""))
                alert.informativeText = content
                alert.addButton(withTitle: NSLocalizedString("Uncheck", comment: ""))
                alert.buttons.forEach { button in
                  button.hasDestructiveAction = true
                }
                alert.addButton(withTitle: NSLocalizedString("Leave it checked", comment: ""))
                if let window = CtlSettingsUI.shared?.window, !shouldNotFartInLieuOfBeep {
                  shouldNotFartInLieuOfBeep = true
                  alert.beginSheetModal(for: window) { result in
                    switch result {
                    case .alertFirstButtonReturn:
                      shouldNotFartInLieuOfBeep = false
                    case .alertSecondButtonReturn:
                      shouldNotFartInLieuOfBeep = true
                    default: break
                    }
                    IMEApp.buzz()
                  }
                  return
                }
                IMEApp.buzz()
              }
            )
          }
        }

        // MARK: (header: Text("Misc Settings:"))

        Section {
          Toggle(
            LocalizedStringKey("Check for updates automatically"),
            isOn: $checkUpdateAutomatically
          )
          Toggle(
            LocalizedStringKey("Debug Mode"),
            isOn: $isDebugModeEnabled
          )
        }
      }.formStyled().frame(minWidth: CtlSettingsUI.formWidth, maxWidth: ceil(CtlSettingsUI.formWidth * 1.2))
    }
    .frame(maxHeight: CtlSettingsUI.contentMaxHeight)
  }
}

@available(macOS 13, *)
struct VwrSettingsPaneGeneral_Previews: PreviewProvider {
  static var previews: some View {
    VwrSettingsPaneGeneral()
  }
}
