public protocol FlowRepresentable {
    /// The type of data coming into the `FlowRepresentable`; defaulted to `Never`; `Never`means the `FlowRepresentable` will ignore data passed in from the `Workflow`.
    associatedtype WorkflowInput = Never
    /// The type of data passed forward from the `FlowRepresentable`; defaulted to `Never`; `Never` means data will not be passed forward.
    associatedtype WorkflowOutput = Never

    /**
     Creates a `FlowRepresentable`.

     #### Note
     This is auto-synthesized by FlowRepresentable, and is only called when `WorkflowInput` is `Never`.
     */
    init()

    // No public docs necessary, as this should not be used by consumers.
    // swiftlint:disable:next missing_docs
    static func _factory<FR: FlowRepresentable>(_ type: FR.Type) -> FR
}

struct ViewThing: FlowRepresentable {
    static func _factory<FR: FlowRepresentable>(_ type: FR.Type) -> FR {
        return type.init()
    }
}