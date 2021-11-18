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
        DataDriven.shared.exploringEcho()
        Container.default.register(UserDefaults.self) { _ in UserDefaults.standard }

//        DataDriven.shared.register(ExtendedFlowRepresentableMetadata(flowRepresentableType: SwiftCurrentOnboarding.self), for: "SwiftCurrentOnboarding")
//        DataDriven.shared.register(key: ContentView.self, creating: ExtendedFlowRepresentableMetadata(flowRepresentableType: ContentView.self))
//        DataDriven.register(type: LoginView.self)
        print(DataDriven.shared.flowRepresentableViewTypes)

        let EFRMs = DataDriven.shared.flowRepresentableViewTypes.compactMap { ($0 as? TylerMetadata.Type)?.getMetadata() }

        DataDriven.shared.register(EFRMs[0] as! ExtendedFlowRepresentableMetadata, for: String(describing: DataDriven.shared.flowRepresentableViewTypes[0]))
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

    enum Error: Swift.Error {
        case unregisteredType
    }

    // MARK: Reflection (Echo) stuff
    func exploringEcho() -> Int {
//        let allTypes = types
//        let allProtocols = protocols

        let structs = types.compactMap { $0 as? StructDescriptor }

        let names = structs.map { $0.name }

        let frProtocols = protocols.filter { $0.name.contains("FlowRepresentable") }

        let overlyAbstractedMetadata = reflect(OverlyAbstracted.self) as? TypeMetadata

        structs.first?.parent

        // (structs[7].accessor(.complete, Any.self).metadata as? StructMetadata)?.conformances[2].protocol.name // should say FlowRepresentable
        // (structs[7].accessor(.complete, Any.self).metadata as? StructMetadata)?.type // Should be type: Any.Type of some SwiftUIExample.OverlyAbstracted

        return 0
    }

    func differentAttemptsAtConvertingFromDescriptorToType() -> [Any.Type] {
        let views = types
            .filter { !$0.flags.isGeneric }
            .compactMap { $0 as? StructDescriptor }
            .compactMap { $0.accessor(MetadataRequest(state: .abstract)) }
            .compactMap { $0.metadata as? StructMetadata }
            .filter { $0.conformances.contains { $0.protocol.name == String(describing: View.self) }}
            .compactMap { $0.type }

        let structDescriptors = types
            .compactMap { $0 as? StructDescriptor }
//            .filter { $0.parentModuleDescriptor?.name == "SwiftUIExample" }

        let modules = structDescriptors
            .compactMap { $0.parentModuleDescriptor?.name }
        
        let structNames = structDescriptors
            .compactMap { $0.name }
        print("structNames: \(structNames.count)")

        let nonGenericStructs = structDescriptors
            .filter { !$0.flags.isGeneric }
        let nonGenericNames = nonGenericStructs
            .compactMap { $0.name }
        print("nonGenericNames: \(nonGenericNames.count)")

        var metadataResponses = [MetadataResponse]()
//        _ = structDescriptors
//            .compactMap { $0.accessor(.complete, Any.self) } //.metadata as? StructMetadata }
        for descriptor in nonGenericStructs {
            print(descriptor.name)
            let response = descriptor.accessor(MetadataRequest(state: .abstract))
            metadataResponses.append(contentsOf: [response])
        }

        var metadata = [StructMetadata?]()
        metadataResponses
            .forEach { metadata.append($0.metadata as? StructMetadata) }

        let flowRepresentables = metadata
            .filter { $0?.conformances.contains { $0.protocol.name == String(describing: FlowRepresentable.self) } == true }


        return flowRepresentables.compactMap { $0?.type }
    }

    var flowRepresentableViewTypes: [Any.Type] {
        types
            .filter { !$0.flags.isGeneric }
            .compactMap { $0 as? StructDescriptor }
            .compactMap { $0.accessor(MetadataRequest(state: .abstract)) }
            .compactMap { $0.metadata as? StructMetadata }
            .filter { $0.conformances.contains { $0.protocol.name == String(describing: FlowRepresentable.self) }}
            .compactMap { $0.type }
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

protocol CombinationFRThing: View, FlowRepresentable {

}

protocol NoOneConformsToThis {}

struct OverlyAbstracted: CombinationFRThing {
    var _workflowPointer: AnyFlowRepresentable?

    var body: some View {
        VStack {
            Text("This thing is wack yo")
            Button("Proceed") {
                proceedInWorkflow()
            }
        }
    }
}

struct GenericAbstractedView<OUTPUT> {}

struct IndirectConformance {
    /// The type of data coming into the `FlowRepresentable`; defaulted to `Never`; `Never`means the `FlowRepresentable` will ignore data passed in from the `Workflow`.
    typealias WorkflowInput = Never
    /// The type of data passed forward from the `FlowRepresentable`; defaulted to `Never`; `Never` means data will not be passed forward.
    typealias WorkflowOutput = Never

    /**
     A pointer to the `AnyFlowRepresentable` that erases this `FlowRepresentable`; will automatically be set.

     ### Discussion
     This property is automatically set by a `Workflow`; it simply needs to be declared on a `FlowRepresentable`.
     In order for a `FlowRepresentable` to have access to the `Workflow` that launched it, store the closures for proceeding forward and backward, and provide type safety. It needs this property available for writing.

     #### Note
     While not strictly necessary, it would be wise to declare this property as `weak`.
     */
    var _workflowPointer: AnyFlowRepresentable?

    /**
     Creates a `FlowRepresentable`.

     #### Note
     This is auto-synthesized by FlowRepresentable, and is only called when `WorkflowInput` is `Never`.
     */
    init() {}
    /// Creates a `FlowRepresentable` with the specified `WorkflowInput`.
    init(with args: WorkflowInput) {}

    // No public docs necessary, as this should not be used by consumers.
    // swiftlint:disable:next missing_docs
    static func _factory<FR: FlowRepresentable>(_ type: FR.Type) -> FR { return Self() as! FR }
    // No public docs necessary, as this should not be used by consumers.
    // swiftlint:disable:next missing_docs
    static func _factory<FR: FlowRepresentable>(_ type: FR.Type, with args: WorkflowInput) -> FR { return Self() as! FR }
}
