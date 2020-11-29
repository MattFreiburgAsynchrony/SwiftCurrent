//
//  AnyWorkflow.swift
//  
//
//  Created by Tyler Thompson on 11/25/20.
//

import Foundation

public class AnyWorkflow: LinkedList<FlowRepresentableMetaData> {
    public typealias InstanceNode = LinkedList<AnyFlowRepresentable?>.Element
    public typealias ArrayLiteralElement = AnyFlowRepresentable.Type
    internal var instances = LinkedList<AnyFlowRepresentable?>()
    internal var orchestrationResponder: AnyOrchestrationResponder?

    public var firstLoadedInstance: LinkedList<AnyFlowRepresentable?>.Element?

    deinit {
        removeInstances()
        orchestrationResponder = nil
    }

    public func applyOrchestrationResponder(_ orchestrationResponder: AnyOrchestrationResponder) {
        self.orchestrationResponder = orchestrationResponder
    }

    @discardableResult public func launch(with args: Any?,
                                          withLaunchStyle launchStyle: LaunchStyle = .default,
                                          onFinish: ((Any?) -> Void)? = nil) -> LinkedList<AnyFlowRepresentable?>.Element? {
        removeInstances()
        instances = LinkedList(map { _ in nil })
        var root: (instance: AnyFlowRepresentable, metadata: FlowRepresentableMetaData)?
        var passedArgs: PassedArgs = .none

        let metadata = first?.traverse { nextNode in
            let nextMetadata = nextNode.value
            let flowRepresentable = nextMetadata.flowRepresentableFactory()
            flowRepresentable.workflow = self
            flowRepresentable.proceedInWorkflowStorage = { passedArgs = .args($0) }

            let shouldLoad = flowRepresentable.shouldLoad(with: passedArgs.extract(args))

            defer {
                guard let instance = instances.first?.traverse(nextNode.position) else { fatalError("Internal state of workflow completely mangled somehow...") }
                let persistance = nextMetadata.calculatePersistance(args)
                if shouldLoad {
                    firstLoadedInstance = instance
                    firstLoadedInstance?.value = flowRepresentable
                    self.setupCallbacks(for: instance, onFinish: onFinish)
                } else if !shouldLoad && persistance == .persistWhenSkipped {
                    instance.value = flowRepresentable
                    self.setupCallbacks(for: instance, onFinish: onFinish)
                    self.orchestrationResponder?.launchOrProceed(to: (instance: instance, metadata: nextMetadata), from: convertInput(root))
                    root = (instance: flowRepresentable, metadata: nextMetadata)
                }

            }
            return shouldLoad
        }?.value

        guard let first = firstLoadedInstance,
              let m = metadata else {
            if let argsToPass = passedArgs.extract(args) {
                onFinish?(argsToPass)
            }
            return nil
        }

        self.orchestrationResponder?.launchOrProceed(to: (instance: first, metadata:m), from: convertInput(root))

        return firstLoadedInstance
    }

    /// abandon: Called when the workflow should be terminated, and the app should return to the point before the workflow was launched
    /// - Parameter animated: A boolean indicating whether abandoning the workflow should be animated
    /// - Parameter onFinish: A callback after the workflow has been abandoned.
    /// - Returns: Void
    /// - Note: In order for this to function the workflow must have a presenter, presenters must call back to the workflow to inform when the abandon process has finished for the onFinish callback to be called.
    public func abandon(animated: Bool = true, onFinish:(() -> Void)? = nil) {
        orchestrationResponder?.abandon(self, animated: animated, onFinish: {
            self.removeInstances()
            self.firstLoadedInstance = nil
            self.orchestrationResponder = nil
            onFinish?()
        })
    }

    private func removeInstances() {
        instances.forEach { $0.value?.proceedInWorkflowStorage = nil }
        instances.removeAll()
        firstLoadedInstance = nil
    }

    private func setupProceedCallbacks(_ node: LinkedList<AnyFlowRepresentable?>.Element, _ onFinish: ((Any?) -> Void)?) {
        guard let currentMetadataNode = first?.traverse(node.position) else { fatalError("Internal state of workflow completely mangled somehow...") }
        node.value?.proceedInWorkflowStorage = { [self] args in
            var argsToPass = args
            var viewToPresent: (instance: AnyFlowRepresentable, metadata: FlowRepresentableMetaData)?
            let nextLoadedNode = node.next?.traverse { nextNode in
                guard let metadata = first?.traverse(nextNode.position)?.value else { return false }
                let persistance = metadata.calculatePersistance(argsToPass)
                let flowRepresentable = metadata.flowRepresentableFactory()
                flowRepresentable.workflow = self

                nextNode.value = flowRepresentable
                flowRepresentable.proceedInWorkflowStorage = { argsToPass = $0 }

                let shouldLoad = flowRepresentable.shouldLoad(with: argsToPass) == true
                if !shouldLoad && persistance == .persistWhenSkipped {
                    viewToPresent = (instance: flowRepresentable, metadata: metadata)
                    self.setupCallbacks(for: nextNode, onFinish: onFinish)
                    self.orchestrationResponder?.proceed(to: (instance: nextNode, metadata: metadata),
                                                         from: (instance: node, metadata: currentMetadataNode.value))
                }

                return shouldLoad
            }

            guard let nextNode = nextLoadedNode,
                  let nextMetadataNode = first?.traverse(nextNode.position) else {
                onFinish?(argsToPass)
                return
            }

            self.setupCallbacks(for: nextNode, onFinish: onFinish)
            orchestrationResponder?.proceed(to: (instance: nextNode, metadata:nextMetadataNode.value),
                                            from: convertInput(viewToPresent) ?? (instance: node, metadata:currentMetadataNode.value))
        }
    }

    private func setupProceedBackwardCallbacks(_ node: LinkedList<AnyFlowRepresentable?>.Element, _ onFinish: ((Any?) -> Void)?) {
        guard let currentMetadataNode = first?.traverse(node.position) else { fatalError("Internal state of workflow completely mangled somehow...") }
        node.value?.proceedBackwardInWorkflowStorage = { [self] in
            //IDEA: Check for nil to know whether something was skipped or not
            //don't worry about persistance, just pass that along to the orchestration responder
            let previousLoadedNode = node.traverse(direction: .backward) { previousNode in
                return previousNode.value != nil
            }

            guard let previousNode = previousLoadedNode,
                  let previousMetaDataNode = first?.traverse(previousNode.position) else { return }

            orchestrationResponder?.proceedBackward(from: (instance: node, metadata: currentMetadataNode.value), to: (instance: previousNode, metadata: previousMetaDataNode.value))
//            var viewToPresent: (instance: AnyFlowRepresentable, metadata: FlowRepresentableMetaData)?
//            let nextLoadedNode = node.next?.traverse { nextNode in
//                guard let metadata = first?.traverse(nextNode.position)?.value else { return false }
//                let persistance = metadata.calculatePersistance(argsToPass)
//                let flowRepresentable = metadata.flowRepresentableFactory()
//                flowRepresentable.workflow = self
//
//                nextNode.value = flowRepresentable
//                flowRepresentable.proceedInWorkflowStorage = { argsToPass = $0 }
//
//                let shouldLoad = flowRepresentable.shouldLoad(with: argsToPass) == true
//                if !shouldLoad && persistance == .persistWhenSkipped {
//                    viewToPresent = (instance: flowRepresentable, metadata: metadata)
//                    self.setupCallbacks(for: nextNode, onFinish: onFinish)
//                    self.orchestrationResponder?.proceed(to: (instance: nextNode, metadata: metadata),
//                                                         from: (instance: node, metadata: currentMetadataNode.value))
//                }
//
//                return shouldLoad
//            }
//
//            guard let nextNode = nextLoadedNode,
//                  let nextMetadataNode = first?.traverse(nextNode.position) else {
//                onFinish?(argsToPass)
//                return
//            }
//
//            self.setupCallbacks(for: nextNode, onFinish: onFinish)
//            orchestrationResponder?.proceed(to: (instance: nextNode, metadata:nextMetadataNode.value),
//                                            from: convertInput(viewToPresent) ?? (instance: node, metadata:currentMetadataNode.value))
        }
    }

    private func setupCallbacks(for node: LinkedList<AnyFlowRepresentable?>.Element, onFinish: ((Any?) -> Void)?) {
        setupProceedCallbacks(node, onFinish)
        setupProceedBackwardCallbacks(node, onFinish)
    }
}

extension AnyWorkflow {
    private func convertInput(_ old: (instance: AnyFlowRepresentable,
                                      metadata: FlowRepresentableMetaData)?) -> (instance: AnyWorkflow.InstanceNode,
                                                                                 metadata: FlowRepresentableMetaData)? {
        guard let old = old else { return nil }
        return (instance: AnyWorkflow.InstanceNode(with: old.instance), metadata: old.metadata)
    }
}

extension AnyWorkflow {
    private enum PassedArgs {
        case none
        case args(Any?)

        func extract(_ defaultValue: Any?) -> Any? {
            if case .args(let value) = self {
                return value
            }
            return defaultValue
        }
    }
}
