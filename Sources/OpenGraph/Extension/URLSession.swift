//
//  URLSession.swift
//  OpenGraph
//
//  Created by Rudrank Riyam on 18/01/22.
//  Copyright © 2022 Satoshi Takano. All rights reserved.
//

import Foundation

// Taken from John Sundell's [AsyncCompatibilityKit](https://github.com/JohnSundell/AsyncCompatibilityKit/blob/main/Sources/URLSession%2BAsync.swift)

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public extension URLSession {
    /// Start a data task with a URL using async/await.
    /// - parameter url: The URL to send a request to.
    /// - returns: A tuple containing the binary `Data` that was downloaded,
    ///   as well as a `URLResponse` representing the server's response.
    /// - throws: Any error encountered while performing the data task.
    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await data(for: URLRequest(url: url))
    }
    
    /// Start a data task with a `URLRequest` using async/await.
    /// - parameter request: The `URLRequest` that the data task should perform.
    /// - returns: A tuple containing the binary `Data` that was downloaded,
    ///   as well as a `URLResponse` representing the server's response.
    /// - throws: Any error encountered while performing the data task.
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        var dataTask: URLSessionDataTask?
        let onCancel = { dataTask?.cancel() }
        
        return try await withTaskCancellationHandler(
            handler: {
                onCancel()
            },
            operation: {
                try await withCheckedThrowingContinuation { continuation in
                    dataTask = self.dataTask(with: request) { data, response, error in
                        guard let data = data, let response = response else {
                            let error = error ?? URLError(.badServerResponse)
                            return continuation.resume(throwing: error)
                        }
                        
                        continuation.resume(returning: (data, response))
                    }
                    
                    dataTask?.resume()
                }
            }
        )
    }
}
