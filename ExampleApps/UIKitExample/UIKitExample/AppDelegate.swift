//
//  AppDelegate.swift
//  UIKitExample
//
//  Created by Tyler Thompson on 11/24/20.
//  Copyright © 2021 WWT and Tyler Thompson. All rights reserved.
//

import UIKit
import Echo
import SwiftCurrent

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // No implementation necessary as it would only include boilerplate.
    func applicationDidFinishLaunching(_ application: UIApplication) {
        print(flowRepresentableClassTypes)
    }

    var flowRepresentableClassTypes: [Any.Type] {
        types
            .filter { !$0.flags.isGeneric }
            .compactMap { $0 as? TypeContextDescriptor }
            .compactMap { $0.accessor(MetadataRequest(state: .abstract)) }
            .compactMap { $0.metadata as? TypeMetadata }
            .filter { $0.conformances.contains { $0.protocol.name == String(describing: FlowRepresentable.self) }}
            .compactMap { $0.type }
    }

    private var flowRepresentableViewTable: [String : Any.Type] {
        types
            .filter { !$0.flags.isGeneric }
            .compactMap { $0 as? TypeContextDescriptor }
            .compactMap { $0.accessor(MetadataRequest(state: .abstract)) }
            .compactMap { $0.metadata as? TypeMetadata }
            .filter { $0.conformances.contains { $0.protocol.name == String(describing: FlowRepresentable.self) }}
            .reduce(into: [:]) { $0[$1.contextDescriptor.name] = $1.type }
    }
}
