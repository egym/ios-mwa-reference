### Build from a fresh clone

1. Install the npm packages. The NFC plugin's Swift package is linked from `node_modules`:
   ```bash
   npm ci
   ```
2. Clone the official Capacitor plugins into `Vendor/` (the Preferences plugin is linked from there):
   ```bash
   git clone --depth 1 --branch "@capacitor/preferences@8.0.1" https://github.com/ionic-team/capacitor-plugins.git Vendor/capacitor-plugins
   ```
3. Open `egym-ios-mwa-reference.xcodeproj` in Xcode and run the app on a simulator.

Run `npm ci` again after any change to `package.json` or `package-lock.json`, for example after you pull a Dependabot update. The NFC plugin's Swift code comes from `node_modules`, so Xcode builds whatever version is installed there.

On a fresh install, the first open of each Portal stays empty while its live update downloads. Restart the app and open the Portal again.

### Install capacitor plugins

Capacitor plugins can be installed using two methods. This repository natively supports both approaches.

#### Option 1: NPM package linked as a local Swift package

This is how the repo links `@egym/capacitor-nfc-pass-wallet`. To add a new plugin via NPM:

1. Install the plugin from NPM:
   ```bash
   npm install <plugin-name>
   ```
2. In Xcode, select `File -> Add Package Dependencies -> Add Local` and choose `node_modules/<plugin-name>` (the folder containing its `Package.swift` file).
3. Add the plugin's library product to the `egym-ios-mwa-reference` target.
4. Register the plugin in the Portal, see below.

#### Option 2: Git Submodules & Manual Wiring

If you prefer to vendor native dependencies, you can wire plugins manually using Git Submodules and Xcode's SPM integration. The repo uses this manual approach for the `@capacitor/preferences` plugin as a working example.

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
