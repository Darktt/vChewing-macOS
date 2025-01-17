// (c) 2021 and onwards The vChewing Project (MIT-NTL License).
// ====================
// This code is released under the MIT license (SPDX-License-Identifier: MIT)
// ... with NTL restriction stating that:
// No trademark license is granted to use the trade names, trademarks, service
// marks, or product names of Contributor, except as required to fulfill notice
// requirements defined in MIT License.

import InputMethodKit
import Shared
import SwiftUI

// MARK: ObservableProject.

@available(macOS 10.15, *)
extension PrefMgr: ObservableObject {}

extension PrefMgr {
  func sendObjWillChange() {
    if #available(macOS 10.15, *) {
      objectWillChange.send()
    }
  }
}

// MARK: Auto parameter fix procedures, executed everytime on SessionCtl.activateServer().

public extension PrefMgr {
  func fixOddPreferences() {
    if #unavailable(macOS 12) {
      showNotificationsWhenTogglingCapsLock = false
    }
    if appleLanguages.isEmpty {
      UserDefaults.current.removeObject(forKey: UserDef.kAppleLanguages.rawValue)
    }
    // 自動糾正選字鍵 (利用其 didSet 特性)
    candidateKeys = candidateKeys
    // 客體黑名單資料類型升級。
    if let clients = UserDefaults.current.object(
      forKey: UserDef.kClientsIMKTextInputIncapable.rawValue
    ) as? [String] {
      UserDefaults.current.removeObject(forKey: UserDef.kClientsIMKTextInputIncapable.rawValue)
      clients.forEach { neta in
        guard !clientsIMKTextInputIncapable.keys.contains(neta) else { return }
        clientsIMKTextInputIncapable[neta] = true
      }
    }
    // 注拼槽注音排列選項糾錯。
    if KeyboardParser(rawValue: keyboardParser) == nil {
      keyboardParser = 0
    }
    // 基礎鍵盤排列選項糾錯。
    if TISInputSource.generate(from: basicKeyboardLayout) == nil {
      basicKeyboardLayout = Self.kDefaultBasicKeyboardLayout
    }
    if TISInputSource.generate(from: alphanumericalKeyboardLayout) == nil {
      alphanumericalKeyboardLayout = Self.kDefaultAlphanumericalKeyboardLayout
    }
    // 其它多元選項參數自動糾錯。
    if ![0, 1, 2].contains(specifyIntonationKeyBehavior) {
      specifyIntonationKeyBehavior = 0
    }
    if ![0, 1, 2].contains(specifyShiftBackSpaceKeyBehavior) {
      specifyShiftBackSpaceKeyBehavior = 0
    }
    if ![0, 1, 2, 3, 4].contains(upperCaseLetterKeyBehavior) {
      upperCaseLetterKeyBehavior = 0
    }
  }
}
