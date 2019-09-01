//
//  Comparable.swift
//  iOSCSS
//
//  Created by Tyler Thompson on 11/11/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
extension LinkedList where Value : Comparable {
    public func sort() {
        guard first?.next != nil else { return }
        first = LinkedList(mergeSort(first, by: { $0 <= $1 })).first
    }
    
    public func sorted() -> LinkedList<Value> {
        return LinkedList(mergeSort(first, by: { $0 <= $1 }))
    }

    public func max() -> Value? {
        guard var m = first?.value else { return nil }
        forEach { m = Swift.max(m, $0.value) }
        return m
    }
    
    public func min() -> Value? {
        guard var m = first?.value else { return nil }
        forEach { m = Swift.min(m, $0.value) }
        return m
    }
}
