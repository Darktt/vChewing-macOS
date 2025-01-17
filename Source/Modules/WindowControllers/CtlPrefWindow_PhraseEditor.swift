// (c) 2021 and onwards The vChewing Project (MIT-NTL License).
// ====================
// This code is released under the MIT license (SPDX-License-Identifier: MIT)
// ... with NTL restriction stating that:
// No trademark license is granted to use the trade names, trademarks, service
// marks, or product names of Contributor, except as required to fulfill notice
// requirements defined in MIT License.

import AppKit
import Foundation
import LangModelAssembly
import MainAssembly
import PhraseEditorUI
import Shared

extension CtlPrefWindow: NSTextViewDelegate, NSTextFieldDelegate {
  var selInputMode: Shared.InputMode {
    switch cmbPEInputModeMenu.selectedTag() {
    case 0: return .imeModeCHS
    case 1: return .imeModeCHT
    default: return .imeModeNULL
    }
  }

  var selUserDataType: vChewingLM.ReplacableUserDataType {
    switch cmbPEDataTypeMenu.selectedTag() {
    case 0: return .thePhrases
    case 1: return .theFilter
    case 2: return .theReplacements
    case 3: return .theAssociates
    case 4: return .theSymbols
    default: return .thePhrases
    }
  }

  func updatePhraseEditor() {
    updateLabels()
    clearAllFields()
    isLoading = true
    tfdPETextEditor.string = NSLocalizedString("Loading…", comment: "")
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.tfdPETextEditor.string = LMMgr.retrieveData(mode: self.selInputMode, type: self.selUserDataType)
      self.tfdPETextEditor.toolTip = PETerms.TooltipTexts.sampleDictionaryContent(for: self.selUserDataType)
      self.isLoading = false
    }
  }

  func setPEUIControlAvailability() {
    btnPEReload.isEnabled = selInputMode != .imeModeNULL && !isLoading
    btnPEConsolidate.isEnabled = selInputMode != .imeModeNULL && !isLoading
    btnPESave.isEnabled = true // 暫時沒辦法捕捉到 TextView 的內容變更事件，故作罷。
    btnPEAdd.isEnabled =
      !txtPEField1.isEmpty && !txtPEField2.isEmpty && selInputMode != .imeModeNULL && !isLoading
    tfdPETextEditor.isEditable = selInputMode != .imeModeNULL && !isLoading
    txtPEField1.isEnabled = selInputMode != .imeModeNULL && !isLoading
    txtPEField2.isEnabled = selInputMode != .imeModeNULL && !isLoading
    txtPEField3.isEnabled = selInputMode != .imeModeNULL && !isLoading
    txtPEField3.isHidden = selUserDataType != .thePhrases || isLoading
    txtPECommentField.isEnabled = selUserDataType != .theAssociates && !isLoading
  }

  func updateLabels() {
    clearAllFields()
    switch selUserDataType {
    case .thePhrases:
      txtPEField1.placeholderString = PETerms.AddPhrases.locPhrase.localized.0
      txtPEField2.placeholderString = PETerms.AddPhrases.locReadingOrStroke.localized.0
      txtPEField3.placeholderString = PETerms.AddPhrases.locWeight.localized.0
      txtPECommentField.placeholderString = PETerms.AddPhrases.locComment.localized.0
    case .theFilter:
      txtPEField1.placeholderString = PETerms.AddPhrases.locPhrase.localized.0
      txtPEField2.placeholderString = PETerms.AddPhrases.locReadingOrStroke.localized.0
      txtPEField3.placeholderString = ""
      txtPECommentField.placeholderString = PETerms.AddPhrases.locComment.localized.0
    case .theReplacements:
      txtPEField1.placeholderString = PETerms.AddPhrases.locReplaceTo.localized.0
      txtPEField2.placeholderString = PETerms.AddPhrases.locReplaceTo.localized.1
      txtPEField3.placeholderString = ""
      txtPECommentField.placeholderString = PETerms.AddPhrases.locComment.localized.0
    case .theAssociates:
      txtPEField1.placeholderString = PETerms.AddPhrases.locInitial.localized.0
      txtPEField2.placeholderString = {
        let result = PETerms.AddPhrases.locPhrase.localized.0
        return (result == "Phrase") ? "Phrases" : result
      }()
      txtPEField3.placeholderString = ""
      txtPECommentField.placeholderString = NSLocalizedString(
        "Inline comments are not supported in associated phrases.", comment: ""
      )
    case .theSymbols:
      txtPEField1.placeholderString = PETerms.AddPhrases.locPhrase.localized.0
      txtPEField2.placeholderString = PETerms.AddPhrases.locReadingOrStroke.localized.0
      txtPEField3.placeholderString = ""
      txtPECommentField.placeholderString = PETerms.AddPhrases.locComment.localized.0
    }
  }

  func clearAllFields() {
    txtPEField1.stringValue = ""
    txtPEField2.stringValue = ""
    txtPEField3.stringValue = ""
    txtPECommentField.stringValue = ""
  }

  func initPhraseEditor() {
    // InputMode combobox.
    cmbPEInputModeMenu.menu?.removeAllItems()
    let menuItemCHS = NSMenuItem()
    menuItemCHS.title = NSLocalizedString("Simplified Chinese", comment: "")
    menuItemCHS.tag = 0
    let menuItemCHT = NSMenuItem()
    menuItemCHT.title = NSLocalizedString("Traditional Chinese", comment: "")
    menuItemCHT.tag = 1
    cmbPEInputModeMenu.menu?.addItem(menuItemCHS)
    cmbPEInputModeMenu.menu?.addItem(menuItemCHT)
    switch IMEApp.currentInputMode {
    case .imeModeCHS: cmbPEInputModeMenu.select(menuItemCHS)
    case .imeModeCHT: cmbPEInputModeMenu.select(menuItemCHT)
    case .imeModeNULL: cmbPEInputModeMenu.select(menuItemCHT)
    }

    // DataType combobox.
    cmbPEDataTypeMenu.menu?.removeAllItems()
    var defaultDataTypeMenuItem: NSMenuItem?
    for (i, neta) in vChewingLM.ReplacableUserDataType.allCases.enumerated() {
      let newMenuItem = NSMenuItem()
      newMenuItem.title = neta.localizedDescription
      newMenuItem.tag = i
      cmbPEDataTypeMenu.menu?.addItem(newMenuItem)
      if i == 0 { defaultDataTypeMenuItem = newMenuItem }
    }
    guard let defaultDataTypeMenuItem = defaultDataTypeMenuItem else { return }
    cmbPEDataTypeMenu.select(defaultDataTypeMenuItem)

    // Buttons.
    btnPEReload.title = NSLocalizedString("Reload", comment: "")
    btnPEConsolidate.title = NSLocalizedString("Consolidate", comment: "")
    btnPESave.title = NSLocalizedString("Save", comment: "")
    btnPEAdd.title = PETerms.AddPhrases.locAdd.localized.0
    btnPEOpenExternally.title = NSLocalizedString("...", comment: "")

    // Text Editor View
    tfdPETextEditor.font = NSFont.systemFont(ofSize: 13, weight: .regular)

    // Tab key targets.
    tfdPETextEditor.delegate = self
    txtPECommentField.nextKeyView = txtPEField1
    txtPEField1.nextKeyView = txtPEField2
    txtPEField2.nextKeyView = txtPEField3
    txtPEField3.nextKeyView = btnPEAdd

    // Delegates.
    tfdPETextEditor.delegate = self
    txtPECommentField.delegate = self
    txtPEField1.delegate = self
    txtPEField2.delegate = self
    txtPEField3.delegate = self

    // Tooltip.
    txtPEField3.toolTip = PETerms.TooltipTexts.weightInputBox.localized
    tfdPETextEditor.toolTip = PETerms.TooltipTexts.sampleDictionaryContent(for: selUserDataType)

    // Finally, update the entire editor UI.
    updatePhraseEditor()
  }

  func controlTextDidChange(_: Notification) { setPEUIControlAvailability() }

  @IBAction func inputModePEMenuDidChange(_: NSPopUpButton) { updatePhraseEditor() }

  @IBAction func dataTypePEMenuDidChange(_: NSPopUpButton) { updatePhraseEditor() }

  @IBAction func reloadPEButtonClicked(_: NSButton) { updatePhraseEditor() }

  @IBAction func consolidatePEButtonClicked(_: NSButton) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.isLoading = true
      vChewingLM.LMConsolidator.consolidate(text: &self.tfdPETextEditor.string, pragma: false)
      if self.selUserDataType == .thePhrases {
        LMMgr.shared.tagOverrides(in: &self.tfdPETextEditor.string, mode: self.selInputMode)
      }
      self.isLoading = false
    }
  }

  @IBAction func savePEButtonClicked(_: NSButton) {
    let toSave = tfdPETextEditor.string
    isLoading = true
    tfdPETextEditor.string = NSLocalizedString("Loading…", comment: "")
    let newResult = LMMgr.saveData(mode: selInputMode, type: selUserDataType, data: toSave)
    tfdPETextEditor.string = newResult
    isLoading = false
  }

  @IBAction func openExternallyPEButtonClicked(_: NSButton) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      let app: String = NSEvent.keyModifierFlags.contains(.option) ? "TextEdit" : "Finder"
      LMMgr.shared.openPhraseFile(mode: self.selInputMode, type: self.selUserDataType, appIdentifier: app)
    }
  }

  @IBAction func addPEButtonClicked(_: NSButton) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.txtPEField1.stringValue.removeAll { "　 \t\n\r".contains($0) }
      if self.selUserDataType != .theAssociates {
        self.txtPEField2.stringValue.regReplace(pattern: #"( +|　+| +|\t+)+"#, replaceWith: "-")
      }
      self.txtPEField2.stringValue.removeAll {
        self.selUserDataType == .theAssociates ? "\n\r".contains($0) : "　 \t\n\r".contains($0)
      }
      self.txtPEField3.stringValue.removeAll { !"0123456789.-".contains($0) }
      self.txtPECommentField.stringValue.removeAll { "\n\r".contains($0) }
      guard !self.txtPEField1.stringValue.isEmpty, !self.txtPEField2.stringValue.isEmpty else { return }
      var arrResult: [String] = [self.txtPEField1.stringValue, self.txtPEField2.stringValue]
      if let weightVal = Double(self.txtPEField3.stringValue), weightVal < 0 {
        arrResult.append(weightVal.description)
      }
      if !self.txtPECommentField.stringValue.isEmpty { arrResult.append("#" + self.txtPECommentField.stringValue) }
      if LMMgr.shared.checkIfPhrasePairExists(
        userPhrase: self.txtPEField1.stringValue, mode: self.selInputMode, key: self.txtPEField2.stringValue
      ) {
        arrResult.append(" #𝙾𝚟𝚎𝚛𝚛𝚒𝚍𝚎")
      }
      if let lastChar = self.tfdPETextEditor.string.last, !"\n".contains(lastChar) {
        arrResult.insert("\n", at: 0)
      }
      self.tfdPETextEditor.string.append(arrResult.joined(separator: " ") + "\n")
      self.clearAllFields()
    }
  }
}

private extension NSTextField {
  var isEmpty: Bool { stringValue.isEmpty }
}
