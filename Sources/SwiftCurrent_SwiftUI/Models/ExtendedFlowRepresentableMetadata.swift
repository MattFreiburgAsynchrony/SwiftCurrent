//
//  ExtendedFlowRepresentableMetadata.swift
//  SwiftCurrent
//
//  Created by Morgan Zellers on 11/2/21.
//  Copyright © 2021 WWT and Tyler Thompson. All rights reserved.
//  

import SwiftUI
import SwiftCurrent

@available(iOS 14.0, macOS 11, tvOS 14.0, watchOS 7.0, *)
public class ExtendedFlowRepresentableMetadata: FlowRepresentableMetadata {
    private(set) var workflowItemFactory: (AnyWorkflowItem?) -> AnyWorkflowItem

    public init<FR: FlowRepresentable & View>(flowRepresentableType: FR.Type,
                                              launchStyle: LaunchStyle = .default,
                                              flowPersistence: @escaping (AnyWorkflow.PassedArgs) -> FlowPersistence = { _ in .default },
                                              flowRepresentableFactory: @escaping (AnyWorkflow.PassedArgs) -> AnyFlowRepresentable) {
        workflowItemFactory = {
            guard let wrappedWorkflowItem = $0 else { return AnyWorkflowItem(view: WorkflowItem(FR.self)) }
            return AnyWorkflowItem(view: WorkflowItem(FR.self) { wrappedWorkflowItem })
        }

        underlyingTypeDescription = String(describing: flowRepresentableType)

        super.init(flowRepresentableType, launchStyle: launchStyle, flowPersistence: flowPersistence, flowRepresentableFactory: flowRepresentableFactory)
    }

    public init<FR: FlowRepresentable & View>(flowRepresentableType: FR.Type,
                                              launchStyle: LaunchStyle = .default,
                                              flowPersistence: @escaping (AnyWorkflow.PassedArgs) -> FlowPersistence = { _ in .default }) {
        workflowItemFactory = {
            guard let wrappedWorkflowItem = $0 else { return AnyWorkflowItem(view: WorkflowItem(FR.self)) }
            return AnyWorkflowItem(view: WorkflowItem(FR.self) { wrappedWorkflowItem })
        }

        underlyingTypeDescription = String(describing: flowRepresentableType)

        super.init(flowRepresentableType, launchStyle: launchStyle, flowPersistence: flowPersistence) { args in
            AnyFlowRepresentableView(type: FR.self, args: args)
        }
    }

    /// The type name for the underlying ``FlowRepresentable``
    public let underlyingTypeDescription: String
}

@available(iOS 14.0, macOS 11, tvOS 14.0, watchOS 7.0, *)
extension FlowRepresentable where Self: View {
    public static func getMetadata() -> FlowRepresentableMetadata {
        ExtendedFlowRepresentableMetadata(flowRepresentableType: self)
    }
}
