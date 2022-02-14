Workflows are highly configurable, whether in SwiftUI, UIKit, or something custom built. You can provide JSON or YAML representations of a workflow to SwiftCurrent. This can be provided from a server, or supplied some other way (like a flatfile for whitelabel configuration). Both JSON and YAML representations use JSONSchema as a way to document what the structure should look like. You can see the schema at [our WorkflowSchema repo](https://github.com/wwt/WorkflowSchema), as well as detailed examples in YAML and JSON.

# Creating a workflow from data

### Step 1 - Define your workflow
Start by defining your workflow. In this example we'll use JSON to define our workflow. NOTE: The `$schema` property is entirely optional, but some editors know how to parse that schema to give you extra documentation on the properties and validate against the schema to give you fast feedback on whether your JSON looks correct.

```json
{
  "$schema": "https://raw.githubusercontent.com/wwt/WorkflowSchema/main/workflow-schema.json",
  "schemaVersion": "v0.0.1",
  "sequence": [
    { "flowRepresentableName": "FirstView" },
    { "flowRepresentableName": "SecondView" },
    { "flowRepresentableName": "ThirdView" }
  ]
}
```

This workflow describes 3 screens in the order FirstView -> SecondView -> ThirdView

### Step 2 - Supply an aggregator
In order to map flow representable names in our JSON to actual types in the codebase SwiftCurrent uses `FlowRepresentableAggregator`. This protocol simply requires an array of types to be supplied. Each `FlowRepresentable` in the codebase that is also `WorkflowDecodable` can be added to the array. `WorkflowDecodable.flowRepresentableName` must match the name given in the JSON. 

The easiest way forward is to use our [SwiftCurrentGen](https://github.com/wwt/main/SwiftCurrentGen) package in a run script build phase to generate a `FlowRepresentableAggregator` based on the types already present in your codebase. This tool scans your files, finds everything that is `WorkflowDecodable` generates an aggregator for you.

Alternatively you can create your own quite easily:
```swift
struct Aggregator: FlowRepresentableAggregator {
    var types: [WorkflowDecodable.Type] = [
        FirstView.self,
        SecondView.self,
        ThirdView.self
    ]
}
```

### Step 3 - Using your aggregator, decode the workflow
SwiftCurrent provides several ways to decode workflows. `JSONDecoder.decodeWorkflow(withAggregator:from:)` is an extension on `JSONDecoder` that you can use. Alternatively you can use the `DecodeWorkflow` property wrapper to make use of `Decodable` like you normally would.

```swift
struct SomeDecodableType: Decodable {
    @DecodeWorkflow(aggregator: Aggregator.self) var myWorkflow: AnyWorkflow
}
```