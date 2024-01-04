//
//  PropertyExtension.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 1/2/24.
//

import Combine
import SwiftUI

@propertyWrapper
public final class ObservableObjects<Objects: Sequence>: ObservableObject
where Objects.Element: ObservableObject {
  public init(wrappedValue: Objects) {
    self.wrappedValue = wrappedValue
    assignCancellable()
  }

  @Published public var wrappedValue: Objects {
    didSet { assignCancellable() }
  }

  private var cancellable: AnyCancellable!
}

// MARK: - private
private extension ObservableObjects {
  func assignCancellable() {
    cancellable = Publishers.MergeMany(wrappedValue.map(\.objectWillChange))
      .sink { [unowned self] _ in objectWillChange.send() }
  }
}


// MARK: -

@propertyWrapper
public struct ObservedObjects<Objects: Sequence>: DynamicProperty
where Objects.Element: ObservableObject {
  public init(wrappedValue: Objects) {
    _objects = .init(
      wrappedValue: .init(wrappedValue: wrappedValue)
    )
  }

  public var wrappedValue: Objects {
    get { objects.wrappedValue }
    nonmutating set { objects.wrappedValue = newValue }
  }

  public var projectedValue: Binding<Objects> { $objects.wrappedValue }

  @ObservedObject private var objects: ObservableObjects<Objects>
}

@propertyWrapper
public struct StateObjects<Objects: Sequence>: DynamicProperty
where Objects.Element: ObservableObject {
  public init(wrappedValue: Objects) {
    _objects = .init(
      wrappedValue: .init(wrappedValue: wrappedValue)
    )
  }

  public var wrappedValue: Objects {
    get { objects.wrappedValue }
    nonmutating set { objects.wrappedValue = newValue }
  }

  public var projectedValue: Binding<Objects> { $objects.wrappedValue }

  @StateObject private var objects: ObservableObjects<Objects>
}
