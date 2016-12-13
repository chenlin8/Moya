import Foundation
import AlamofireDomain

public typealias Manager = AlamofireDomain.SessionManager
internal typealias Request = AlamofireDomain.Request
internal typealias DownloadRequest = AlamofireDomain.DownloadRequest
internal typealias UploadRequest = AlamofireDomain.UploadRequest
internal typealias DataRequest = AlamofireDomain.DataRequest

internal typealias URLRequestConvertible = AlamofireDomain.URLRequestConvertible

/// Choice of parameter encoding.
public typealias ParameterEncoding = AlamofireDomain.ParameterEncoding
public typealias JSONEncoding = AlamofireDomain.JSONEncoding
public typealias URLEncoding = AlamofireDomain.URLEncoding
public typealias PropertyListEncoding = AlamofireDomain.PropertyListEncoding

/// Multipart form
public typealias RequestMultipartFormData = AlamofireDomain.MultipartFormData

/// Multipart form data encoding result.
public typealias MultipartFormDataEncodingResult = Manager.MultipartFormDataEncodingResult
public typealias DownloadDestination = AlamofireDomain.DownloadRequest.DownloadFileDestination

/// Make the Alamofire Request type conform to our type, to prevent leaking Alamofire to plugins.
extension Request: RequestType { }

/// Internal token that can be used to cancel requests
public final class CancellableToken: Cancellable, CustomDebugStringConvertible {
    let cancelAction: () -> Void
    let request: Request?
    public fileprivate(set) var isCancelled = false

    fileprivate var lock: DispatchSemaphore = DispatchSemaphore(value: 1)

    public func cancel() {
        _ = lock.wait(timeout: DispatchTime.distantFuture)
        defer { lock.signal() }
        guard !isCancelled else { return }
        isCancelled = true
        cancelAction()
    }

    public init(action: @escaping () -> Void) {
        self.cancelAction = action
        self.request = nil
    }

    init(request: Request) {
        self.request = request
        self.cancelAction = {
            request.cancel()
        }
    }

    public var debugDescription: String {
        guard let request = self.request else {
            return "Empty Request"
        }
        return request.debugDescription
    }

}

internal typealias RequestableCompletion = (HTTPURLResponse?, URLRequest?, Data?, Swift.Error?) -> Void

internal protocol Requestable {
    func response(queue: DispatchQueue?, completionHandler: @escaping RequestableCompletion) -> Self
}

extension DataRequest: Requestable {
    internal func response(queue: DispatchQueue?, completionHandler: @escaping RequestableCompletion) -> Self {
        return response(queue: queue) { handler  in
            completionHandler(handler.response, handler.request, handler.data, handler.error)
        }
    }
}

extension DownloadRequest: Requestable {
    internal func response(queue: DispatchQueue?, completionHandler: @escaping RequestableCompletion) -> Self {
        return response(queue: queue) { handler  in
            completionHandler(handler.response, handler.request, nil, handler.error)
        }
    }
}
