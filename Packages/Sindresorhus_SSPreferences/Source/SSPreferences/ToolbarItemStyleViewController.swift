// (c) 2018 and onwards Sindre Sorhus (MIT License).
// ====================
// This code is released under the MIT license (SPDX-License-Identifier: MIT)

import Cocoa

final class ToolbarItemStyleViewController: NSObject, PreferencesStyleController {
  let toolbar: NSToolbar
  let centerToolbarItems: Bool
  let preferencePanes: [PreferencePane]
  var isKeepingWindowCentered: Bool { centerToolbarItems }
  weak var delegate: PreferencesStyleControllerDelegate?

  init(preferencePanes: [PreferencePane], toolbar: NSToolbar, centerToolbarItems: Bool) {
    self.preferencePanes = preferencePanes
    self.toolbar = toolbar
    self.centerToolbarItems = centerToolbarItems
  }

  func toolbarItemIdentifiers() -> [NSToolbarItem.Identifier] {
    var toolbarItemIdentifiers = [NSToolbarItem.Identifier]()

    if centerToolbarItems {
      toolbarItemIdentifiers.append(.flexibleSpace)
    }

    for preferencePane in preferencePanes {
      toolbarItemIdentifiers.append(preferencePane.toolbarItemIdentifier)
    }

    if centerToolbarItems {
      toolbarItemIdentifiers.append(.flexibleSpace)
    }

    return toolbarItemIdentifiers
  }

  func toolbarItem(preferenceIdentifier: SSPreferences.PaneIdentifier) -> NSToolbarItem? {
    guard let preference = (preferencePanes.first { $0.preferencePaneIdentifier == preferenceIdentifier }) else {
      preconditionFailure()
    }

    let toolbarItem = NSToolbarItem(itemIdentifier: preferenceIdentifier.toolbarItemIdentifier)
    toolbarItem.label = preference.preferencePaneTitle
    toolbarItem.image = preference.toolbarItemIcon
    toolbarItem.target = self
    toolbarItem.action = #selector(toolbarItemSelected)
    return toolbarItem
  }

  @IBAction private func toolbarItemSelected(_ toolbarItem: NSToolbarItem) {
    delegate?.activateTab(
      preferenceIdentifier: SSPreferences.PaneIdentifier(fromToolbarItemIdentifier: toolbarItem.itemIdentifier),
      animated: true
    )
  }

  func selectTab(index: Int) {
    toolbar.selectedItemIdentifier = preferencePanes[index].toolbarItemIdentifier
  }
}