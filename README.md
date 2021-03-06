# TVMLKitchen😋🍴  [![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/Carthage/Carthage/master/LICENSE.md) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![CocoaPods](https://img.shields.io/cocoapods/v/TVMLKitchen.svg)]() [![CocoaPods](https://img.shields.io/cocoapods/p/TVMLKitchen.svg)]() [![Build Status](https://www.bitrise.io/app/de994b854e5c425f.svg?token=GZp-KU8RDjmewA2Hdj27fQ)](https://www.bitrise.io/app/de994b854e5c425f)

[TVML](https://developer.apple.com/library/tvos/documentation/LanguagesUtilities/Conceptual/ATV_Template_Guide/) is a good choice, when you prefer simplicity over dynamic UIKit implementation. TVMLKitchen helps to manage your TVML **with or without additional client-server**.  Put TVML templates in Main Bundle, then you're ready to go.

Loading a TVML view is in this short.

```
Kitchen.serve(xmlFile:"Catalog.xml")
```

Kitchen automatically looks for the xmlFile in your Main Bundle, parse it, then finally pushes it to navigationController.

# Getting Started

## Showing a Template from main bundle

1. Put your Sample.xml to your app's main bundle.

2. Prepare your Kitchen in AppDelegate's `didFinishLaunchingWithOptions:`.
    ```
    let cookbook = Cookbook(launchOptions: launchOptions)
    Kitchen.prepare(cookbook)
    ```

3. Launch the template from anywhere.
    ```
    Kitchen.serve(xmlFile: "Sample.xml")
    ```

## Showing a Template from client-server

<ol start="4">
<li><p>Got TVML server ? Just pass the URL String and you're good to go.</p>
    <pre><code>Kitchen.serve(urlString: "https://raw.githubusercontent.com/toshi0383/TVMLKitchen/master/SampleRecipe/Catalog.xml")</code></pre>

</li></ol>

## Open Other TVML from TVML

Set URL to `template` attributes of focusable element. Kitchen will send asynchronous request and present TVML. You can specify preferred `presentationType` too. Note that if `actionID` present, these attributes are ignored.

```
<lockup
    template="https://raw.githubusercontent.com/toshi0383/TVMLKitchen/master/SampleRecipe/Oneup.xml"
    presentationType="Modal"
>
```

## Presentation Styles

There are currently three presentation styles that can be used when serving views: Default, Modal and Tab. The default style acts as a "Push" and will change the current view. Modal will overlay the new view atop the existing view and is commonly used for alerts. Tab is only to be used when defining the first view in a tabcontroller.

````swift
Kitchen.serve(xmlFile: "Sample.xml")
Kitchen.serve(xmlFile: "Sample.xml", type: .Default)
Kitchen.serve(xmlFile: "Sample.xml", type: .Modal)
Kitchen.serve(xmlFile: "Sample.xml", type: .Tab)
````

## Tab Controller

Should you wish to use tabs within your application you can use `KitchenTabBar` recipe. First, create a `TabItem` struct with a title and a `handler` method. The `handler` method will be called every time the tab becomes active.

**Note:** The `PresentationType` for initial view should always be set to `.Tab`.

````swift
struct MoviesTab: TabItem {

    let title = "Movies"

    func handler() {
        Kitchen.serve(xmlFile: "Sample.xml", type: .Tab)
    }

}
````

Present tabbar using `serve(recipe:)` method.

````swift
let tabbar = KitchenTabBar(items:[
    MoviesTab(),
    MusicsTab()
])
Kitchen.serve(recipe: tabbar)
````

# Advanced setup

## Add error handlers
```
cookbook.onError = { error in
    let title = "Error Launching Application"
    let message = error.localizedDescription
    let alertController = UIAlertController(title: title, message: message, preferredStyle:.Alert )

    Kitchen.navigationController.presentViewController(alertController, animated: true) { }
}
```

## Inject native code into TVML(javascript) context
```
cookbook.evaluateAppJavaScriptInContext = {appController, jsContext in
    /// set Exception handler
    /// called on JS error
    jsContext.exceptionHandler = {context, value in
        debugPrint(context)
        debugPrint(value)
        assertionFailure("You got JS error. Check your javascript code.")
    }

    /// - SeeAlso: http://nshipster.com/javascriptcore/
    /// Inject native code block named 'debug'.
    let consoleLog: @convention(block) String -> Void = { message in
        print(message)
    }
    jsContext.setObject(unsafeBitCast(consoleLog, AnyObject.self),
        forKeyedSubscript: "debug")
}
```

## Handling Actions
You can set `actionID` and `playActionID` attributes in your focusable elements. (e.g. `lockup` or `button` SeeAlso: https://forums.developer.apple.com/thread/17704 ) Kitchen receives Select or Play events, then fires `actionIDHandler` or `playActionHandler` if exists.

```
<lockup actionID="showDescription" playActionID="playContent">
```

```
cookbook.actionIDHandler = { actionID in
    print(actionID)
}
cookbook.playActionIDHandler = {actionID in
    print(actionID)
}
```

Handlers are currently globally shared. This is just an idea, but we can pass parameters via actions like this,

```
actionID="showHogeView,12345678,hogehoge"
```

then parse it in Swift side.
```
actionID.componentsSeparatedByString(",")
```

## Customize URL Request
You can set `httpHeaders` and `responseObjectHandler` to `Cookbook` configuration object. So for example you can manage custom Cookies.

```
cookbook.httpHeaders = [
    "Cookie": "Hello;"
]

cookbook.responseObjectHandler = { response in
    /// Save cookies
    if let fields = response.allHeaderFields as? [String: String],
        let url = response.URL
    {
        let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(fields, forURL: url)
        for c in cookies {
            NSHTTPCookieStorage.sharedCookieStorageForGroupContainerIdentifier(
                "group.jp.toshi0383.tvmlkitchen.samplerecipe").setCookie(c)
        }
    }
    return true
}
```

# Kitchen Recipes
Though TVML is static xmls, we can generate TVML dynamically by defining **Recipe**.
Built-in Recipes are still middle of the way. You can send PRs!

## AlertRecipe
```
let alert = AlertRecipe(
    title: Sample.title,
    description: Sample.description)
)
Kitchen.serve(recipe: alert)
```

## SearchRecipe
SearchRecipe supports dynamic view manipulation.

#### Configuring SearchRecipe
Subclass `SearchRecipe` and override `filterSearchText` method.
SeeAlso: [SampleRecipe/MySearchRecipe.swift](https://github.com/toshi0383/TVMLKitchen/blob/master/SampleRecipe/MySearchRecipe.swift), [SearchResult.xml](https://github.com/toshi0383/TVMLKitchen/blob/master/Sources/Templates/SearchResult.xml)

#### SearchRecipe as TabItem
Use `PresentationType.TabSearch`. This will create keyboard observer in addition to `.Tab` behavior.
```
struct SearchTab: TabItem {
    let title = "Search"
    func handler() {
        let search = MySearchRecipe(type: .TabSearch)
        Kitchen.serve(recipe: search)
    }
}
```

## Available Recipes

- [x] Catalog
- [x] Catalog with select action handler
- [x] Alert with button handler
- [x] Descriptive Alert with button handler
- [x] Search
- [ ] Rating with handler
- [ ] Compilation with select action handler
- [ ] Product with select action handler
- [ ] Product Bundle with select action handler
- [ ] Stack with select action handler
- [ ] Stack Room with select action handler
- [ ] Stack Separator with select action handler

and more...

## Note
We don't support dynamic view reloading in most cases.
For now, if you need 100% dynamic behavior, go ahead and use UIKit.

# Installation

## Carthage
Put this to your Cartfile,
```
github "toshi0383/TVMLKitchen"
```

Follow the instruction in [carthage's Getting Started section](https://github.com/Carthage/Carthage#getting-started).

## Cocoapods
Add the following to your Podfile
```
pod 'TVMLKitchen'
```

# References
For implementation details, my slide is available.  
[TVML + Native = Hybrid](https://speakerdeck.com/toshi0383/tvml-plus-native-equals-hybrid)

# Contribution
Any contribution is welcomed🎉
