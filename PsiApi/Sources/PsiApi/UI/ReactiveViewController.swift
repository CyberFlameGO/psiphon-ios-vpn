/*
 * Copyright (c) 2020, Psiphon Inc.
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#if os(iOS)

import Foundation
import UIKit
import ReactiveSwift

public enum ViewControllerLifeCycle: Equatable {
    case initing
    case viewDidLoad
    case viewWillAppear(animated: Bool)
    case viewDidAppear(animated: Bool)
    case viewWillDisappear(animated: Bool)
    case viewDidDisappear(animated: Bool)
}

extension ViewControllerLifeCycle {
    
    public var initing: Bool {
        guard case .initing = self else {
            return false
        }
        return true
    }
    
    public var viewDidLoad: Bool {
        guard case .viewDidLoad = self else {
            return false
        }
        return true
    }
    
    public var viewWillAppear: Bool {
        guard case .viewWillAppear = self else {
            return false
        }
        return true
    }
    
    public var viewDidAppear: Bool {
        guard case .viewDidAppear(_) = self else {
            return false
        }
        return true
    }
    
    public var viewWillDisappear: Bool {
        guard case .viewWillDisappear(_) = self else {
            return false
        }
        return true
    }
    
    public var viewDidDisappear: Bool {
        guard case .viewDidDisappear(_) = self else {
            return false
        }
        return true
    }
    
    public var viewWillOrDidDisappear: Bool {
        viewWillDisappear || viewDidDisappear
    }
    
    /// Returns true while the view controller life cycle in somewhere between
    /// `viewDidLoad` and `viewDidAppear` (inclusive).
    public var viewDidLoadOrAppeared: Bool {
        viewDidLoad || viewWillAppear || viewDidAppear
    }
    
}

/// ReactiveViewController makes the values of UIViewController lifecycle calls available in a stream
/// and also buffers the last value.
open class ReactiveViewController: UIViewController {
    
    /// The time at which this view controller's `viewDidLoad` got called.
    /// Value is nil beforehand.
    public private(set) var viewControllerDidLoadDate: Date?
    
    /// Value of the last UIViewController lifecycle call. The property wrapper provides
    /// an interface to obtain a stream of UIViewController lifecycle call values, which starts
    /// with the current value of this variable.
    @State public private(set) var lifeCycle: ViewControllerLifeCycle = .initing
    
    /// Set of presented error alerts.
    /// Note: Once an error alert has been dismissed by the user, it will be removed from the set.
    private(set) var errorAlerts = Set<ErrorEventDescription<ErrorRepr>>()
    
    private let onDismiss: () -> Void
    
    /// - Parameter onDismiss: Called once after the view controller is either dismissed
    /// (when viewD
    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        self.viewControllerDidLoadDate = Date()
        super.viewDidLoad()
        lifeCycle = .viewDidLoad
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lifeCycle = .viewWillAppear(animated: animated)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lifeCycle = .viewDidAppear(animated: animated)
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lifeCycle = .viewWillDisappear(animated: animated)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lifeCycle = .viewDidDisappear(animated: animated)
        onDismiss()
    }
    
    /// Presents `viewControllerToPresent` only after `viewDidAppear(_:)` has been called
    /// on this view controller.
    public func presentOnViewDidAppear(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        self.$lifeCycle.signalProducer
            .filter{ $0.viewDidAppear }
            .take(first: 1)
            .startWithValues { [weak self] _ in
                guard let self = self else {
                    return
                }
                guard !self.lifeCycle.viewWillOrDidDisappear else {
                    return
                }
                self.present(viewControllerToPresent, animated: flag, completion: completion)
            }
    }
    
}

extension ReactiveViewController {
    
    /// Display error alert if `errorDesc` is a unique alert not in `self.errorAlerts`, and
    /// the error event `errorDesc.event` date is not before the init date of
    /// the view controller `viewControllerInitTime`.
    /// Only if the error is unique `makeAlertController` is called for creating the alert controller.
    public func display(errorDesc: ErrorEventDescription<ErrorRepr>,
                        makeAlertController: @autoclosure () -> UIAlertController) {
        
        guard let viewDidLoadDate = self.viewControllerDidLoadDate else {
            return
        }
        
        // Displays errors that have been emitted after the init date of the view controller.
        guard errorDesc.event.date > viewDidLoadDate else {
            return
        }
        
        // Inserts `errorDesc` into `errorAlerts` set.
        // If a member of `errorAlerts` is equal to `errorDesc.event.error`, then
        // that member is removed and `errorDesc` is inserted.
        let inserted = self.errorAlerts.insert(orReplaceIfEqual: \.event.error, errorDesc)
        
        // Prevent display of the same error event.
        guard inserted else {
            return
        }
        
        let alertController = makeAlertController()
        self.presentOnViewDidAppear(alertController, animated: true, completion: nil)
    }
    
}

#endif
