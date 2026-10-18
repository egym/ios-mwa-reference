### Build from a fresh clone

On this branch, Ionic Portals, Live Updates, Capacitor and the Capacitor plugins come from one EGYM package, `@egym/capacitor-mwa-navigation`, the proof of concept of BMACG-751. The package is not published yet, so npm installs it from a local folder.

1. Install the package's own npm packages in its folder:
   ```bash
   cd <path to lib-capacitor-mwa-navigation>
   npm install
   ```
2. Install the npm packages here:
   ```bash
   npm ci
   ```
   `package.json` points at the package by the relative path `../../libs/lib-capacitor-mwa-navigation`. If your checkout sits elsewhere, run `npm install <path to lib-capacitor-mwa-navigation>` instead, and do not commit the changed path.
3. Open `egym-ios-mwa-reference.xcodeproj` in Xcode and run the app on a simulator. Xcode links the package as a local Swift package from `node_modules/@egym/capacitor-mwa-navigation`.

Run `npm ci` again after any change to `package.json` or `package-lock.json`. The package's Swift code comes from `node_modules`, so Xcode builds whatever version is installed there.

Each MWA button calls `EgymMwa.open` from the package (`ContentView.swift`). The package shows the MWA full screen and closes it on `dismiss`. Before each open it syncs the MWA's live update, as the BMA apps do, so the first open on a fresh install is not empty: a loading view shows until the newest build is on the device. The sync waits at most 30 seconds. After that, or when the sync fails, the package opens a build downloaded earlier, and with none it shows "Try again" and "Close".

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

The app then logs in at Galaxy, gets the member's MWA token from Galaxy, and passes it as `authToken` in the initial context of Workouts and NFC, as the BMA apps do. When an MWA asks for a new token, the app gets a fresh one from Galaxy and publishes it on the shared Portals channel, and the package passes it on to the MWA. Bioage keeps the sample context and the `reference` channel.

`BMALogin.json` is git-ignored and holds no password or token. Never commit it. Without it, the app starts with no login screen, exactly as before.

### Open one MWA from another (proof of concept)

- Each MWA that `EgymMwa.open` shows gets the `EgymMwaNavigation` plugin and the nine Capacitor plugins that the package carries (Preferences, App, Haptics, Keyboard, Status Bar, Browser, Device, SQLite and the EGYM NFC wallet plugin).
- An MWA calls `EgymMwaNavigation.open` to open the NFC MWA full screen, and the plugin closes it again when NFC sends `dismiss`. The host has no code for this.
- The package screen runs its Portal edge to edge. With the carried Status Bar plugin, the MWAs pad the safe area themselves.
- To call the plugin by hand, open Workouts in a debug build and use the Simulator's WebKit inspector (Safari, Develop menu) on its WebView. Run `Capacitor.Plugins.EgymMwaNavigation.open({ appId: 'dcbe378a', channel: 'reference', startingRoute: '/nfc/home', initialContext: { ...window.portalInitialContext.value, startingRoute: '/nfc/home' } })`. NFC opens full screen, and its back arrow resolves the call with `closedBy: 'dismiss'`.

### Install capacitor plugins

Capacitor plugins can be installed using two methods. This repository natively supports both approaches.

#### Option 1: NPM package linked as a local Swift package

This is how the repo links `@egym/capacitor-mwa-navigation`, which brings the nine plugins above. To add another plugin via NPM:

1. Install the plugin from NPM:
   ```bash
   npm install <plugin-name>
   ```
2. In Xcode, select `File -> Add Package Dependencies -> Add Local` and choose `node_modules/<plugin-name>` (the folder containing its `Package.swift` file).
3. Add the plugin's library product to the `egym-ios-mwa-reference` target.
4. Register the plugin on a Portal of your own, see below. The package screen of `EgymMwa.open` registers only the package's plugins, so a plugin that the EGYM MWAs need goes into the package.

#### Option 2: Git Submodules & Manual Wiring

If you prefer to vendor native dependencies, you can wire plugins manually using Git Submodules and Xcode's SPM integration.

1. Vendor the plugin's repository as a Git Submodule:
   ```bash
   # Example: official Capacitor plugins
   git submodule add https://github.com/ionic-team/capacitor-plugins.git Vendor/capacitor-plugins

   # Example: EGYM NFC Pass Wallet
   git submodule add https://github.com/egym/lib-capacitor-nfc-pass-wallet.git Vendor/lib-capacitor-nfc-pass-wallet
   ```
2. In Xcode, select `File -> Add Package Dependencies -> Add Local` and choose the folder containing the `Package.swift` file (e.g., `Vendor/capacitor-plugins/preferences` or `Vendor/lib-capacitor-nfc-pass-wallet`).

#### Registering Plugins in the Portal

Regardless of the installation method, a Portal that your app builds itself must register the native plugin in its initialization code:

```swift
import EgymMwaNavigationPlugin
...
plugins: EgymMwa.portalPlugins + [.type(MyOtherPlugin.self)],
```
