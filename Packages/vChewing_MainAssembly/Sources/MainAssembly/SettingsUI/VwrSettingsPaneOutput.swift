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
public struct VwrSettingsPaneOutput: View {
  // MARK: - AppStorage Variables

  @AppStorage(wrappedValue: false, UserDef.kChineseConversionEnabled.rawValue)
  private var chineseConversionEnabled: Bool

  @AppStorage(wrappedValue: false, UserDef.kShiftJISShinjitaiOutputEnabled.rawValue)
  private var shiftJISShinjitaiOutputEnabled: Bool

  @AppStorage(wrappedValue: false, UserDef.kInlineDumpPinyinInLieuOfZhuyin.rawValue)
  private var inlineDumpPinyinInLieuOfZhuyin: Bool

  @AppStorage(wrappedValue: true, UserDef.kTrimUnfinishedReadingsOnCommit.rawValue)
  private var trimUnfinishedReadingsOnCommit: Bool

  @AppStorage(wrappedValue: false, UserDef.kHardenVerticalPunctuations.rawValue)
  private var hardenVerticalPunctuations: Bool

  // MARK: - Main View

  public var body: some View {
    ScrollView {
      Form {
        Section {
          Toggle(
            LocalizedStringKey("Auto-convert traditional Chinese glyphs to KangXi characters"),
            isOn: $chineseConversionEnabled.onChange {
              if chineseConversionEnabled, shiftJISShinjitaiOutputEnabled {
                shiftJISShinjitaiOutputEnabled = false
              }
            }
          )
          Toggle(
            LocalizedStringKey("Auto-convert traditional Chinese glyphs to JIS Shinjitai characters"),
            isOn: $shiftJISShinjitaiOutputEnabled.onChange {
              if chineseConversionEnabled, shiftJISShinjitaiOutputEnabled {
                chineseConversionEnabled = false
              }
            }
          )
          Toggle(
            LocalizedStringKey("Commit Hanyu-Pinyin instead on Ctrl(+Option)+Command+Enter"),
            isOn: $inlineDumpPinyinInLieuOfZhuyin
          )
          Toggle(
            LocalizedStringKey("Trim unfinished readings / strokes on commit"),
            isOn: $trimUnfinishedReadingsOnCommit
          )
        }
        Section(header: Text("Experimental:")) {
          VStack(alignment: .leading) {
            Toggle(
              LocalizedStringKey("Harden vertical punctuations during vertical typing (not recommended)"),
              isOn: $hardenVerticalPunctuations
            )
            Text(
              "⚠︎ This feature is useful ONLY WHEN the font you are using doesn't support dynamic vertical punctuations. However, typed vertical punctuations will always shown as vertical punctuations EVEN IF your editor has changed the typing direction to horizontal."
            )
            .settingsDescription()
          }
        }
      }.formStyled().frame(minWidth: CtlSettingsUI.formWidth, maxWidth: ceil(CtlSettingsUI.formWidth * 1.2))
    }
    .frame(maxHeight: CtlSettingsUI.contentMaxHeight)
  }
}

@available(macOS 13, *)
struct VwrSettingsPaneOutput_Previews: PreviewProvider {
  static var previews: some View {
    VwrSettingsPaneOutput()
  }
}
