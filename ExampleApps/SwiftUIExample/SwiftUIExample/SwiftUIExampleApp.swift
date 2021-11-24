//
//  SwiftUIExampleApp.swift
//  SwiftUIExample
//
//  Created by Tyler Thompson on 7/15/21.
//
//  Copyright © 2021 WWT and Tyler Thompson. All rights reserved.
// swiftlint:disable all
import SwiftUI
import Swinject
import SwiftCurrent_SwiftUI

@main
struct SwiftUIExampleApp: App {
    let startingWorkflow: AnyWorkflow

    init() {
        Container.default.register(UserDefaults.self) { _ in UserDefaults.standard }

        let thingToBeJson = WorkflowData(version: "0.0.1", sequence: [
            WorkflowSequenceNode(flowRepresentableName: "SwiftCurrentOnboarding"),
            WorkflowSequenceNode(flowRepresentableName: "ContentView"),
        ])

        if let data = try? JSONEncoder().encode(thingToBeJson) {
            let workflow = try? DataDriven.shared.createWorkflow(from: data)
            print(workflow)
        }

//        let EFRMs = DataDriven.shared.flowRepresentableViewTypes.compactMap { ($0 as? TylerMetadata.Type)?.getMetadata() }

//        DataDriven.shared.register(EFRMs[0] as! ExtendedFlowRepresentableMetadata, for: String(describing: DataDriven.shared.flowRepresentableViewTypes[0]))
        print(DataDriven.shared.registryDescription)

        do {
            startingWorkflow = try DataDriven.shared.getWorkflow(from: ["SwiftCurrentOnboarding", "ContentView"])
        } catch {
            let defaultWorkflow = Workflow(ContentView.self)
            startingWorkflow = AnyWorkflow(defaultWorkflow)
        }
    }

    var body: some Scene {
        WindowGroup {
            if Environment.shouldTest {
                TestView()
            } else {
//                WorkflowLauncher(isLaunched: .constant(true)) {
//                    thenProceed(with: SwiftCurrentOnboarding.self) {
//                        thenProceed(with: ContentView.self)
//                            .applyModifiers { $0.transition(.slide) }
//                    }.applyModifiers { $0.transition(.slide) }
//                }
                WorkflowLauncher(isLaunched: .constant(true), workflow: startingWorkflow)
                .preferredColorScheme(.dark)
            }
        }
    }
}

import SwiftCurrent
import Echo
/// Manages ``FlowRepresentable`` types that will be driven through data.
open class DataDriven {
    // I don't like this.
    static let shared = DataDriven()

    private var registry1 = [String: ExtendedFlowRepresentableMetadata]()

    // I'm leaning towards this being the preferred registry.
    private var registry2 = [String: () -> ExtendedFlowRepresentableMetadata]()

    /// Current human readable description of the registry.
    public var registryDescription: String {
        var stringy = "Registry contains:\n"
        for thisKey in registry1.keys {
            stringy += "  - key: \"\(thisKey)\" : \(registry1[thisKey]!.underlyingTypeDescription)\n"
        }
        return stringy
    }

    func register(_ efrm: @escaping @autoclosure () -> ExtendedFlowRepresentableMetadata, for key: String) {
        registry1[key] = efrm()
        registry2[key] = efrm
    }

    func register(key: Any, creating efrm: @escaping @autoclosure () -> ExtendedFlowRepresentableMetadata) {
        let key = String(describing: key)
        print("Registering key: \(key)")
        registry1[key] = efrm()
        registry2[key] = efrm
    }

    /// Registers the provided type in the data driven registry.
    public class func register<FR: FlowRepresentable & View>(type: FR.Type) {
        let key = String(describing: type)
        let closure = { return ExtendedFlowRepresentableMetadata(flowRepresentableType: type) }

        // This thing could be a instance method that doesn't go directly to shared.  Maybe it could take in shared, I'm not sure.
        shared.registry1[key] = closure()
        shared.registry2[key] = closure
    }

    func getWorkflow(from types: [String]) throws -> AnyWorkflow {
        let workflow = AnyWorkflow.empty
        for thing in types {
            if let efrm = registry2[thing] {
                workflow.append(efrm())
            } else {
                throw Error.unregisteredType
            }
        }

        return workflow
    }

    func createWorkflow(from json: Data) throws -> AnyWorkflow {
        guard let data = try? JSONDecoder().decode(WorkflowData.self, from: json) else { throw Error.unregisteredType }
        let workflow = AnyWorkflow.empty
        let cachedTable = flowRepresentableViewTable

        for sequence in data.sequence {
            if let meta = (cachedTable[sequence.flowRepresentableName] as? TylerMetadata.Type)?.getMetadata() {
                workflow.append(meta)
            }
        }

        return workflow
    }

    enum Error: Swift.Error {
        case unregisteredType
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

extension ContextDescriptor {
    var parentModuleDescriptor: ModuleDescriptor? {
        if parent == nil {
            if self is ModuleDescriptor {
                return self as? ModuleDescriptor
            } else {
                fatalError("No parent module found for: this thing")
            }
        } else {
            return self.parent?.parentModuleDescriptor
        }
    }
}

struct WorkflowData: Codable {
    let version: String
    let sequence: [WorkflowSequenceNode]
}

struct WorkflowSequenceNode: Codable {
    let flowRepresentableName: String
    var flowPersistence: FlowPersistenceData = .default
    var launchStyle: LaunchStyleData = .default
}

struct FlowPersistenceData: Codable {
    static let `default` = FlowPersistenceData(type: "default")

    let type: String
}

struct LaunchStyleData: Codable {
    static let `default` = LaunchStyleData(type: "default")

    let type: String
    var subtype: String? = nil
}
