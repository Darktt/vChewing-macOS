// (c) 2021 and onwards The vChewing Project (MIT-NTL License).
// ====================
// This code is released under the MIT license (SPDX-License-Identifier: MIT)
// ... with NTL restriction stating that:
// No trademark license is granted to use the trade names, trademarks, service
// marks, or product names of Contributor, except as required to fulfill notice
// requirements defined in MIT License.

import MainAssembly
import SwiftExtension
import SwiftUI

@available(macOS 10.15, *)
extension PrefUITabs {
  @ViewBuilder
  var suiView: some View {
    switch self {
    case .tabGeneral: VwrPrefPaneGeneral()
    case .tabCandidates: VwrPrefPaneCandidates()
    case .tabBehavior: VwrPrefPaneBehavior()
    case .tabOutput: VwrPrefPaneOutput()
    case .tabDictionary: VwrPrefPaneDictionary()
    case .tabPhrases: VwrPrefPanePhrases()
    case .tabCassette: VwrPrefPaneCassette()
    case .tabKeyboard: VwrPrefPaneKeyboard()
    case .tabDevZone: VwrPrefPaneDevZone()
    }
  }
}

@available(macOS 10.15, *)
class CtlPrefUIShared {
  static var sharedWindow: NSWindow? {
    CtlPrefUI.shared?.window
  }

  static let shared = CtlPrefUIShared()
  static let sentenceSeparator: String = {
    switch PrefMgr.shared.appleLanguages[0] {
    case "ja":
      return ""
    default:
      if PrefMgr.shared.appleLanguages[0].contains("zh-Han") {
        return ""
      } else {
        return " "
      }
    }
  }()

  static let contentMaxHeight: Double = 490

  static let formWidth: Double = {
    switch PrefMgr.shared.appleLanguages[0] {
    case "ja":
      return 520
    default:
      if PrefMgr.shared.appleLanguages[0].contains("zh-Han") {
        return 500
      } else {
        return 580
      }
    }
  }()

  static var isCJKInterface: Bool {
    PrefMgr.shared.appleLanguages[0].contains("zh-Han") || PrefMgr.shared.appleLanguages[0] == "ja"
  }
}

@available(macOS 10.15, *)
public extension View {
  func settingsDescription(maxWidth: CGFloat? = .infinity) -> some View {
    controlSize(.small)
      .frame(maxWidth: maxWidth, alignment: .leading)
      // TODO: Use `.foregroundStyle` when targeting macOS 12.
      .foregroundColor(.secondary)
  }
}

@available(macOS 10.15, *)
public extension View {
  func formStyled() -> some View {
    if #available(macOS 13, *) { return self.formStyle(.grouped) }
    return padding()
  }
}
