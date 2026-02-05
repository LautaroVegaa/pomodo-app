import FamilyControls
import Flutter
import ManagedSettings
import SwiftUI
import UIKit
import os.log

@available(iOS 16.0, *)
final class AppBlockingChannel {
  private enum StorageKey {
    static let selection = "app_blocking_selection"
  }

  private let channel: FlutterMethodChannel
  private let store: ManagedSettingsStore
  private let defaults: UserDefaults
  private let logger = Logger(subsystem: "pomodo.app", category: "AppBlocking")
  private let pickerPresenter = PickerPresenter()
  private let appGroupIdentifier = "group.com.example.pomodoApp"

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "pomodo/app_blocking", binaryMessenger: messenger)
    store = ManagedSettingsStore(named: ManagedSettingsStore.Name("pomodoBlocker"))
    defaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    channel.setMethodCallHandler(handle)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestAuthorization":
      requestAuthorization(result: result)
    case "getAuthorizationStatus":
      result(AuthorizationCenter.shared.authorizationStatus == .approved)
    case "presentPicker":
      presentPicker(result: result)
    case "getSelectionSummary":
      result(selectionSummaryPayload())
    case "applyBlock":
      applyBlock(result: result)
    case "clearBlock":
      clearShield()
      result(nil)
    case "clearAllOnStartup":
      clearShield()
      store.clearAllSettings()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestAuthorization(result: @escaping FlutterResult) {
    Task {
      do {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        DispatchQueue.main.async {
          result(true)
        }
      } catch {
        self.logger.error("Authorization request failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
          result(false)
        }
      }
    }
  }

  private func presentPicker(result: @escaping FlutterResult) {
    guard AuthorizationCenter.shared.authorizationStatus == .approved else {
      result(nil)
      return
    }
    let existingSelection = loadSelection() ?? FamilyActivitySelection()
    let guidance = PickerGuidance()

    pickerPresenter.present(initialSelection: existingSelection, guidance: guidance) { [weak self] newSelection in
      guard let self else {
        result(nil)
        return
      }
      if let selection = newSelection {
        self.save(selection: selection)
        result(self.selectionSummaryPayload())
      } else {
        result(nil)
      }
    }
  }

  private func applyBlock(result: @escaping FlutterResult) {
    guard let selection = loadSelection() else {
      logger.error("No stored selection available")
      result(false)
      return
    }

    store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
    if selection.categoryTokens.isEmpty {
      store.shield.applicationCategories = .none
    } else {
      store.shield.applicationCategories = .specific(selection.categoryTokens)
    }
    store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    result(true)
  }

  private func loadSelection() -> FamilyActivitySelection? {
    guard let data = defaults.data(forKey: StorageKey.selection) else {
      return nil
    }
    do {
      return try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    } catch {
      logger.error("Failed to decode selection: \(error.localizedDescription)")
      defaults.removeObject(forKey: StorageKey.selection)
      return nil
    }
  }

  private func save(selection: FamilyActivitySelection) {
    do {
      let data = try JSONEncoder().encode(selection)
      defaults.set(data, forKey: StorageKey.selection)
    } catch {
      logger.error("Failed to encode selection: \(error.localizedDescription)")
    }
  }

  private func selectionSummaryPayload() -> [String: Any] {
    return [
      "custom": summaryDictionary(for: loadSelection()),
    ]
  }

  private func summaryDictionary(for selection: FamilyActivitySelection?) -> [String: Int] {
    guard let selection else {
      return ["applications": 0, "categories": 0]
    }
    return [
      "applications": selection.applications.count,
      "categories": selection.categories.count,
    ]
  }

  private func clearShield() {
    store.shield.applications = nil
    store.shield.applicationCategories = .none
    store.shield.webDomains = nil
  }
}

@available(iOS 16.0, *)
private struct PickerGuidance {
  let header: String?
  let footer: String?

  init() {
    header = "Choose the apps to block"
    footer = "Pick any app or site you want blocked during sessions."
  }
}

@available(iOS 16.0, *)
private final class PickerPresenter {
  private var completion: ((FamilyActivitySelection?) -> Void)?
  private var controller: UIViewController?

  func present(initialSelection: FamilyActivitySelection, guidance: PickerGuidance, completion: @escaping (FamilyActivitySelection?) -> Void) {
    guard self.completion == nil else {
      completion(nil)
      return
    }
    self.completion = completion
    let view = AppBlockingPickerView(initialSelection: initialSelection, guidance: guidance) { [weak self] selection in
      self?.completion?(selection)
      self?.completion = nil
      self?.controller = nil
    }
    let host = UIHostingController(rootView: view)
    host.modalPresentationStyle = .pageSheet
    host.isModalInPresentation = false
    controller = host

    DispatchQueue.main.async {
      guard let presenter = Self.topViewController(from: nil) else {
        self.completion?(nil)
        self.completion = nil
        self.controller = nil
        return
      }
      presenter.present(host, animated: true)
    }
  }

  private static func topViewController(from base: UIViewController?) -> UIViewController? {
    let current = base ?? keyWindow()?.rootViewController
    guard let current else {
      return nil
    }
    if let nav = current as? UINavigationController {
      return topViewController(from: nav.visibleViewController)
    }
    if let tab = current as? UITabBarController, let selected = tab.selectedViewController {
      return topViewController(from: selected)
    }
    if let presented = current.presentedViewController {
      return topViewController(from: presented)
    }
    return current
  }

  private static func keyWindow() -> UIWindow? {
    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }
}

@available(iOS 16.0, *)
private struct AppBlockingPickerView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var selection: FamilyActivitySelection
  private let guidance: PickerGuidance
  private let onComplete: (FamilyActivitySelection?) -> Void

  init(initialSelection: FamilyActivitySelection, guidance: PickerGuidance, onComplete: @escaping (FamilyActivitySelection?) -> Void) {
    _selection = State(initialValue: initialSelection)
    self.guidance = guidance
    self.onComplete = onComplete
  }

  var body: some View {
    NavigationView {
      FamilyActivityPicker(headerText: guidance.header, footerText: guidance.footer, selection: $selection)
        .navigationTitle("Choose apps")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              dismiss()
              onComplete(nil)
            }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
              dismiss()
              onComplete(selection)
            }
          }
        }
    }
  }
}
