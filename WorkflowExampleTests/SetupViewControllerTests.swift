//
//  SetupViewControllerTests.swift
//  WorkflowExampleTests
//
//  Created by Tyler Thompson on 10/5/19.
//  Copyright © 2019 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest

@testable import WorkflowExample
import DynamicWorkflow

class SetupViewControllerTests: ViewControllerTest<SetupViewController> {
    func testLaunchingMultiLocationWorkflow() {
        let listener = WorkflowListener()
        
        testViewController.launchMultiLocationWorkflow()
        
        XCTAssertWorkflowLaunched(listener: listener, expectedFlowRepresentables: [
            LocationsViewController.self,
            PickupOrDeliveryViewController.self,
            MenuSelectionViewController.self,
            FoodSelectionViewController.self,
            ReviewOrderViewController.self,
        ])
    }
}
