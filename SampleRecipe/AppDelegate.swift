//
//  AppDelegate.swift
//  SampleRecipe
//
//  Created by toshi0383 on 12/28/15.
//  Copyright © 2015 toshi0383. All rights reserved.
//

import UIKit
import TVMLKitchen
import JavaScriptCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        _ = prepareMyKitchen(launchOptions)
        return true
    }
}

private func prepareMyKitchen(launchOptions: [NSObject: AnyObject]?) -> Bool
{
    let cookbook = Cookbook(launchOptions: launchOptions)
    cookbook.evaluateAppJavaScriptInContext = {appController, jsContext in
        /// set Exception handler
        /// called on JS error
        jsContext.exceptionHandler = {context, value in
            #if DEBUG
            debugPrint(context)
            debugPrint(value)
            #endif
            assertionFailure("You got JS error. Check your javascript code.")
        }

        // - SeeAlso: http://nshipster.com/javascriptcore/

    }
    cookbook.actionIDHandler = { actionID in
        let identifier = actionID // parse action ID here
        dispatch_async(dispatch_get_main_queue()) {
            openViewController(identifier)
        }
    }
    cookbook.playActionIDHandler = {actionID in
        print(actionID)
    }
    cookbook.httpHeaders = [
        "hello": "world"
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

    Kitchen.prepare(cookbook)
    KitchenTabBar.sharedBar.items = [
        SearchTab(),
        CatalogTab()
    ]

    return true
}

struct SearchTab: TabItem {
    let title = "Search"
    func handler() {
        let search = MySearchRecipe(type: .TabSearch)
        Kitchen.serve(recipe: search)
    }
}

struct CatalogTab: TabItem {
    let title = "Catalog"
    func handler() {
        Kitchen.serve(recipe: catalog)
    }
    private var catalog: CatalogRecipe {
        let banner = "Movie"
        let thumbnailUrl = NSBundle.mainBundle().URLForResource("img",
            withExtension: "jpg")!.absoluteString
        let actionID = "/title?titleId=1234"
        let (width, height) = (250, 376)
        let templateURL: String? = nil
        let content: Section.ContentTuple = ("Star Wars", thumbnailUrl, actionID, templateURL, width, height)
        let section1 = Section(title: "Section 1", args: (0...100).map{_ in content})
        var catalog = CatalogRecipe(banner: banner, sections: (0...10).map{_ in section1})
        catalog.presentationType = .Tab
        return catalog
    }

}

private func openViewController(identifier: String) {
    let sb = UIStoryboard(name: "ViewController", bundle: NSBundle.mainBundle())
    let vc = sb.instantiateInitialViewController()!
    Kitchen.navigationController.pushViewController(vc, animated: true)
}
