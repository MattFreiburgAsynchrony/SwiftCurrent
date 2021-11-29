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
    var startingWorkflow: AnyWorkflow

    init() {
        Container.default.register(UserDefaults.self) { _ in UserDefaults.standard }

        let thingToBeJson = WorkflowData(version: "0.0.1", sequence: [
            WorkflowSequenceNode(flowRepresentableName: "SwiftCurrentOnboarding"),
            WorkflowSequenceNode(flowRepresentableName: "ContentView"),
        ])

        // Option 1
        if let data = try? JSONEncoder().encode(thingToBeJson),
            let workflow = try? DataDriven().createWorkflow(from: data, using: EchoThing()) {
                startingWorkflow = workflow
                print(workflow)

        } else {
            startingWorkflow = AnyWorkflow.empty
        }

        // Option 2
        if let workflow = try? DataDriven().createWorkflow(from: ["SwiftCurrentOnboarding", "ContentView"], using: RegistryThing().registerKnownTypes()) {
            startingWorkflow = workflow
        }

        // Option 3
        startingWorkflow = try! DataDriven().createWorkflow(from: ["SwiftCurrentOnboarding", "ContentView"], using: FallbackDataThing())
    }

    var body: some Scene {
        WindowGroup {
            if Environment.shouldTest {
                TestView()
            } else {
                WorkflowLauncher(isLaunched: .constant(true), workflow: startingWorkflow)
                    .preferredColorScheme(.dark)
            }
        }
    }
}

import SwiftCurrent
open class DataDriven {
    open func createWorkflow(from json: Data, using aggrigator: FlowRepresentableAggrigator) throws -> AnyWorkflow {
        guard let data = try? JSONDecoder().decode(WorkflowData.self, from: json) else { throw Error.unknownDataType }

        return try createWorkflow(from: data, using: aggrigator)
    }

    open func createWorkflow(from data: WorkflowData, using aggrigator: FlowRepresentableAggrigator) throws -> AnyWorkflow {
        let workflow = AnyWorkflow.empty
        let cachedTable = aggrigator.flowRepresentableTypeMap

        for sequence in data.sequence {
            if let meta = (cachedTable[sequence.flowRepresentableName] as? TylerMetadata.Type)?.getMetadata() {
                workflow.append(meta)
            } else {
                throw Error.unregisteredType
            }
        }

        return workflow
    }

    open func createWorkflow(from types: [String], using aggrigator: FlowRepresentableAggrigator) throws -> AnyWorkflow {
        let workflow = AnyWorkflow.empty
        let cachedTable = aggrigator.flowRepresentableTypeMap

        for sequence in types {
            if let meta = (cachedTable[sequence] as? TylerMetadata.Type)?.getMetadata() {
                workflow.append(meta)
            } else {
                throw Error.unregisteredType
            }
        }

        return workflow
    }

    public enum Error: Swift.Error {
        case unknownDataType
        case unregisteredType
    }
}

// MARK: Codables
// These should probably be classes so they can be extended
public struct WorkflowData: Codable {
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

// MARK: Aggrigators
public protocol FlowRepresentableAggrigator { // <--- KEEP : this is I think another key aspect like TylerMetadata. It allows us to have many products.  I'm not sure if a map is still the correct thing, but this works.
    var flowRepresentableTypeMap: [String: Any.Type] { get }

    // Could even be this but this drops its reusability
//    var tylerMetadataTypeMap: [String: TylerMetadata.Type] { get }
}

// MARK: Echo product
import Echo
public class EchoThing { // <----- KEEP : This is our reflection thing.  How it gets changed, I'm not sure but the reflection works.  This should be in its own product
    private static var flowRepresentableMetadata: [TypeMetadata] {
        types
            .filter { !$0.flags.isGeneric }
            .compactMap { $0 as? TypeContextDescriptor }
            .compactMap { $0.accessor(MetadataRequest(state: .abstract)) }
            .compactMap { $0.metadata as? TypeMetadata }
            .filter { $0.conformances.contains { $0.protocol.name == String(describing: FlowRepresentable.self) }}
    }

    public static var flowRepresentableTypes: [Any.Type] {
        flowRepresentableMetadata
            .compactMap { $0.type }
    }

    public static var flowRepresentableTypeTable: [String : Any.Type] {
        flowRepresentableMetadata
            .reduce(into: [:]) { $0[$1.contextDescriptor.name] = $1.type }
    }
}

extension EchoThing: FlowRepresentableAggrigator {
    public var flowRepresentableTypeMap: [String: Any.Type] { EchoThing.flowRepresentableTypeTable }
}

// MARK: Manual product or root of DataDriven?
public class RegistryThing { // <-- KEEP : I think this is something we could ship with the root data-driven product BECAUSE it provides a no-dependency option for users.
    private var registryTypes = [Any.Type]()
    private var registryMap = [String: Any.Type]()

    /// Registers the provided type in the data driven registry.
    public func register<FR: FlowRepresentable>(type: FR.Type) {
        let key = String(describing: type)

        registryMap[key] = type
        registryTypes.append(type)
    }

    /// Current human readable description of the registry.
    public var registryDescription: String {
        var stringy = "Registry contains:\n"
        for thisKey in registryMap.keys {
            stringy += "  - key: \"\(thisKey)\" : \(String(describing: registryMap[thisKey]))\n"
        }
        return stringy
    }
}

extension RegistryThing { // Consumer might do something like this in their code
    open func registerKnownTypes() -> Self {
        register(type: SwiftCurrentOnboarding.self)
        register(type: ContentView.self)

        return self
    }
}

extension RegistryThing: FlowRepresentableAggrigator {
    public var flowRepresentableTypeMap: [String: Any.Type] { return registryMap }
}

class FallbackDataThing: FlowRepresentableAggrigator {
    public let flowRepresentableTypeMap: [String : Any.Type] = [
        String(describing: SwiftCurrentOnboarding.self) : SwiftCurrentOnboarding.self,
        String(describing: ContentView.self) : ContentView.self,
    ]
}
