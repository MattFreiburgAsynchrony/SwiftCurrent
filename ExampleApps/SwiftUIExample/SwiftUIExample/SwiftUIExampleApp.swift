//
//  SwiftUIExampleApp.swift
//  SwiftUIExample
//
//  Created by Tyler Thompson on 7/15/21.
//
//  Copyright © 2021 WWT and Tyler Thompson. All rights reserved.

import SwiftUI
import Swinject
import SwiftCurrent_SwiftUI
import SwiftCurrent

@main
struct SwiftUIExampleApp: App {
    init() {
        Container.default.register(UserDefaults.self) { _ in UserDefaults.standard }
    }

    var body: some Scene {
        WindowGroup {
            if Environment.shouldTest {
                TestView()
            } else {
                WorkflowLauncher(isLaunched: .constant(true)) {
                    thenProceed(with: SwiftCurrentOnboarding.self) {
                        thenProceed(with: ContentView.self)
                            .applyModifiers { $0.transition(.slide) }
                    }.applyModifiers { $0.transition(.slide) }
                }
                .preferredColorScheme(.dark)
            }
        }
    }

    // Deleted the explitive filled code of trying to convert a string to an FR,
    // instead lets convert a string into a FlowRepresentableMetadata that uses that FR.

    /// This one works through explicit naming.  This would probably live as a delegate method to some sort of OBJ-C
    /// or delegate being handed to the data processor.
    func convert(name fr: String) -> FlowRepresentableMetadata {
        if fr == "SwiftCurrentOnboarding" {
            return FlowRepresentableMetadata(SwiftCurrentOnboarding.self)
        } else {
            return FlowRepresentableMetadata(ContentView.self)
        }
    }

    /// This is a var version of convert which would allow for overriding
    var funcy: (String) -> FlowRepresentableMetadata? = { _ in return nil }

    /// We could also register the string to a dictionary if we don't need to generate a new metadat each time.
    /// This would probably be added to through some method on the data processor and you would register your
    /// FR at launch.
    var dictionaryMappingThing: [String: FlowRepresentableMetadata]

    // All of these metadata options work off of us being able to build on top of Metadata,
    // meaning that we would create the base Metadata and then tack on all of the remaining
    // parameters. Only the FR based closures would have to be created at the start.
}
