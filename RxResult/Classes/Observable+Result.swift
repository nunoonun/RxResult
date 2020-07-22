//
//  Observable+Result.swift
//
//  Created by Ivan Bruel on 03/05/16.
//  Copyright © 2016 Faber Ventures. All rights reserved.
//

import Foundation
import RxSwift
import Result

public protocol RxResultError: Error {
  static func failure(from error: Error) -> Self
}

public extension ObservableType {

    func mapResult<U: RxResultError>(_ errorType: U.Type) -> Observable<Result<Element, U>> {
        return self.map(Result<Element, U>.success)
      .catchError{ error in
        if let error = error as? U {
            return .just(Result.failure(error))
        }
        return .just(Result.failure(U.failure(from: error))) }
    }
}

public extension ObservableType where Element: ResultProtocol {

    func `do`(onSuccess: (@escaping (Self.Element.Value) throws -> Void))
        -> Observable<Element> {
      return `do`(onNext: { (value) in
        guard let successValue = value.result.value else {
          return
        }
        try onSuccess(successValue)
      })
  }

    func `do`(onFailure: (@escaping (Self.Element.Error) throws -> Void))
        -> Observable<Element> {
      return `do`(onNext: { (value) in
        guard let failureValue = value.result.error else {
          return
        }
        try onFailure(failureValue)
      })
  }

    func `do`(onSuccess: ((Self.Element.Value) throws -> Void)?, onFailure: ((Self.Element.Error) throws -> Void)?)
        -> Observable<Element> {
      return `do`(onNext: { (value) in
        if let successValue = value.result.value {
          try onSuccess?(successValue)
        } else if let errorValue = value.result.error {
          try onFailure?(errorValue)
      }
      })
  }

    func subscribeResult(onSuccess: ((Self.Element.Value) -> Void)? = nil,
                         onFailure: ((Self.Element.Error) -> Void)? = nil) -> Disposable {
    return subscribe(onNext: { value in
      if let successValue = value.result.value {
        onSuccess?(successValue)
      } else if let errorValue = value.result.error {
        onFailure?(errorValue)
      }
    })
  }
}
