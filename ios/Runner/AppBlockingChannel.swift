import FamilyControls
import Flutter
import ManagedSettings
import SwiftUI
import UIKit
import os.log

@available(iOS 16.0, *)
final class AppBlockingChannel {
  fileprivate enum BlockingMode: String {
    case recommended
    case custom
  }

  private enum StorageKey {
    static let blockingMode = "app_blocking_mode"
    static func selection(for mode: BlockingMode) -> String {
      "app_blocking_selection_\(mode.rawValue)"
    }
  }

  private let channel: FlutterMethodChannel
  private let store: ManagedSettingsStore
  private let defaults: UserDefaults
  private let logger = Logger(subsystem: "pomodo.app", category: "AppBlocking")
  private let pickerPresenter = PickerPresenter()
  private let appGroupIdentifier = "group.com.example.pomodoApp"
  private static let recommendedBundleIdentifiers: Set<String> = [
    "com.burbn.instagram",
    "com.zhiliaoapp.musically", // TikTok
    "com.toyopagroup.picaboo", // Snapchat
    "com.facebook.Facebook",
    "com.facebook.Messenger",
    "net.whatsapp.WhatsApp",
    "com.atebits.Tweetie2", // X / Twitter
    "com.hammerandchisel.discord",
    "pinterest",
    "com.linkedin.LinkedIn",
    "com.spotify.client",
    "com.google.ios.youtube",
    "com.google.ios.youtubekids",
    "com.netflix.Netflix",
    "com.hulu.plus",
    "com.disney.disneyplus",
    "tv.twitch",
    "com.roblox.roblox",
    "com.king.candycrushsaga",
    "com.supercell.magic", // Clash of Clans
    "com.epicgames.fortnite",
  ]
  private static let recommendedWebDomains: Set<String> = [
    "instagram.com",
    "www.instagram.com",
    "tiktok.com",
    "www.tiktok.com",
    "m.tiktok.com",
    "facebook.com",
    "www.facebook.com",
    "m.facebook.com",
    "youtube.com",
    "www.youtube.com",
    "m.youtube.com",
    "netflix.com",
    "www.netflix.com",
    "twitch.tv",
    "www.twitch.tv",
    "discord.com",
    "www.discord.com",
    "roblox.com",
    "www.roblox.com",
  ]

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
      presentPicker(arguments: call.arguments, result: result)
    case "getSelectionSummary":
      result(selectionSummaryPayload())
    case "setBlockingMode":
      setBlockingMode(arguments: call.arguments, result: result)
    case "applyBlock":
      applyBlock(arguments: call.arguments, result: result)
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

  private func presentPicker(arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any],
          let modeValue = args["mode"] as? String,
          let mode = BlockingMode(rawValue: modeValue) else {
      result(FlutterError(code: "invalid_args", message: "Invalid picker arguments", details: nil))
      return
    }
    guard AuthorizationCenter.shared.authorizationStatus == .approved else {
      result(nil)
      return
    }

    let wantsPrefill = (args["prefillRecommended"] as? Bool) ?? false
    let storedSelection = loadSelection(for: mode)
    var existingSelection = storedSelection ?? FamilyActivitySelection()
    if wantsPrefill && mode == .recommended && storedSelection == nil {
      existingSelection = FamilyActivitySelection(includeEntireCategory: true)
    }
    let guidance = PickerGuidance(mode: mode)

    pickerPresenter.present(initialSelection: existingSelection, guidance: guidance) { [weak self] newSelection in
      guard let self else {
        result(nil)
        return
      }
      if let selection = newSelection {
        self.save(selection: selection, for: mode)
        self.persistMode(mode)
        result(self.selectionSummaryPayload())
      } else {
        result(nil)
      }
    }
  }

  private func applyBlock(arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any],
          let modeValue = args["mode"] as? String,
          let mode = BlockingMode(rawValue: modeValue) else {
      result(false)
      return
    }
    guard let selection = loadSelection(for: mode) else {
      logger.error("No stored selection for mode \(mode.rawValue)")
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

  private func setBlockingMode(arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any],
          let modeValue = args["mode"] as? String,
          let mode = BlockingMode(rawValue: modeValue) else {
      result(FlutterError(code: "invalid_args", message: "Invalid mode", details: nil))
      return
    }
    persistMode(mode)
    result(nil)
  }

  private func persistMode(_ mode: BlockingMode) {
    defaults.set(mode.rawValue, forKey: StorageKey.blockingMode)
  }

  private func loadSelection(for mode: BlockingMode) -> FamilyActivitySelection? {
    guard let data = defaults.data(forKey: StorageKey.selection(for: mode)) else {
      return seedSelectionIfNeeded(for: mode)
    }
    do {
      return try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    } catch {
      logger.error("Failed to decode selection: \(error.localizedDescription)")
      defaults.removeObject(forKey: StorageKey.selection(for: mode))
      return seedSelectionIfNeeded(for: mode)
    }
  }

  private func save(selection: FamilyActivitySelection, for mode: BlockingMode) {
    do {
      let data = try JSONEncoder().encode(selection)
      defaults.set(data, forKey: StorageKey.selection(for: mode))
    } catch {
      logger.error("Failed to encode selection: \(error.localizedDescription)")
    }
  }

  private func seedSelectionIfNeeded(for mode: BlockingMode) -> FamilyActivitySelection? {
    guard mode == .recommended else {
      return nil
    }
    let selection = makeRecommendedSelection()
    save(selection: selection, for: .recommended)
    return selection
  }

  private func makeRecommendedSelection() -> FamilyActivitySelection {
    var selection = FamilyActivitySelection(includeEntireCategory: true)

    let applicationTokens: Set<ManagedSettings.ApplicationToken> = Set(
      Self.recommendedBundleIdentifiers.compactMap { bundleIdentifier in
        let application = ManagedSettings.Application(bundleIdentifier: bundleIdentifier)
        if let token = application.token {
          return token
        }
        self.logger.debug("Missing app token for \(bundleIdentifier, privacy: .public)")
        return nil
      }
    )
    selection.applicationTokens.formUnion(applicationTokens)

    let domainTokens: Set<ManagedSettings.WebDomainToken> = Set(
      Self.recommendedWebDomains.compactMap { domain in
        let webDomain = ManagedSettings.WebDomain(domain: domain)
        if let token = webDomain.token {
          return token
        }
        return nil
      }
    )
    selection.webDomainTokens.formUnion(domainTokens)

    return selection
  }

  private func selectionSummaryPayload() -> [String: Any] {
    let mode = currentMode()
    return [
      "mode": mode.rawValue,
      "recommended": summaryDictionary(for: loadSelection(for: .recommended)),
      "custom": summaryDictionary(for: loadSelection(for: .custom)),
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

  private func currentMode() -> BlockingMode {
    let stored = defaults.string(forKey: StorageKey.blockingMode) ?? BlockingMode.recommended.rawValue
    return BlockingMode(rawValue: stored) ?? .recommended
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

  init(mode: AppBlockingChannel.BlockingMode) {
    switch mode {
    case .recommended:
      header = "Recommended blocking"
      footer = "Focus on work by selecting social, entertainment, and game apps."
    case .custom:
      header = "Choose the apps to block"
      footer = "Pick any app or site you want blocked during sessions."
    }
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
