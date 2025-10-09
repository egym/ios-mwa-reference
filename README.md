### Install capacitor plugins

Capacitor preferences plugin is installed via git submodules

`git submodule add https://github.com/ionic-team/capacitor-plugins.git Vendor/capacitor-plugins`

then `File -> Add Package Dependencies -> Add Local -> add Vendor/capacitor-plugins/preferences (folder containing Package.swift)`

Once initializing portal, import the plugin and add to the portal's `plugins` list:
See ContentView.swift for example:

```swift
import PreferencesPlugin
...
plugins: [.type(PreferencesPlugin.self)],

```
