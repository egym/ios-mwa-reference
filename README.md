### Install capacitor plugins

Capacitor plugins can be installed using two methods. This repository natively supports both approaches.

#### Option 1: Standard Capacitor (NPM + CLI)

The recommended approach is to use the standard Capacitor CLI. To add a new plugin via NPM:

1. Install the plugin from NPM:
   ```bash
   npm install <plugin-name>
   ```
2. Sync the plugin to the iOS workspace:
   ```bash
   npx cap sync ios
   ```

The Capacitor CLI will automatically generate the SPM (Swift Package Manager) configuration and integrate the new native dependencies into the Xcode workspace.

#### Option 2: Git Submodules & Manual Wiring

If you prefer to vendor native dependencies or do not use the Capacitor CLI, you can wire plugins manually using Git Submodules and Xcode's SPM integration. The repo uses this manual approach for the `@capacitor/preferences` plugin as a working example.

1. Vendor the plugin's repository as a Git Submodule:
   ```bash
   # Example: official Capacitor plugins
   git submodule add https://github.com/ionic-team/capacitor-plugins.git Vendor/capacitor-plugins

   # Example: EGYM NFC Pass Wallet
   git submodule add https://github.com/egym/lib-capacitor-nfc-pass-wallet.git Vendor/lib-capacitor-nfc-pass-wallet
   ```
2. In Xcode, select `File -> Add Package Dependencies -> Add Local` and choose the folder containing the `Package.swift` file (e.g., `Vendor/capacitor-plugins/preferences` or `Vendor/lib-capacitor-nfc-pass-wallet`).

#### Registering Plugins in the Portal

Regardless of the installation method, you must register the native plugin in your Portal initialization code. See `ContentView.swift` for an example:

```swift
import PreferencesPlugin
import CapacitorNFCPassWalletPlugin
...
plugins: [.type(PreferencesPlugin.self), .type(CapacitorNFCPassWalletPlugin.self)],

```
