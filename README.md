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

Before each open the app syncs the MWA's live update, as the BMA apps do, so the first open on a fresh install is not empty: a loading view shows until the newest build is on the device (`LiveUpdatePortalView.swift`). The sync waits at most 30 seconds. After that, or when the sync fails, the app opens a build downloaded earlier, and with none it shows "Try again" and "Close".

### Log in as a BMA user (optional, EGYM internal)

By default the app opens the MWAs with a sample context and no login. To run Workouts and NFC as a real member of a BMA (Galaxy) brand, add a local config file before you build:

1. Copy the example into the app folder:
   ```bash
   cp BMALogin.example.json egym-ios-mwa-reference/BMALogin.json
   ```
2. Set its three keys:
   - `galaxyURL`: the Galaxy host of the member's brand.
   - `mwaApiURL`: the mwa-api host of the same environment. The MWAs send every request there.
   - `liveUpdateChannel`: the Appflow channel that Workouts and NFC load from.
3. Run the app and log in with the member's email and password.

The app then logs in at Galaxy, gets the member's MWA token from Galaxy, and passes it as `authToken` in the initial context of Workouts and NFC, as the BMA apps do. When an MWA asks for a new token, the app gets a fresh one from Galaxy. Bioage keeps the sample context and the `reference` channel.

`BMALogin.json` is git-ignored and holds no password or token. Never commit it. Without it, the app starts with no login screen, exactly as before.

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
