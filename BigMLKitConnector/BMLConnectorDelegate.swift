//
//  BMLConnectorDelegate.swift
//  BigMLKitConnector
//
//  Created by sergio on 28/04/15.
//  Copyright (c) 2015 BigML Inc. All rights reserved.
//

import Foundation

/**
Responsible for handling all delegate callbacks for the underlying session.
*/
final class BMLConnectionDelegate: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate {
    
    private var subdelegates: [Int: Request.TaskDelegate] = [:]
    private let subdelegateQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT)
    private subscript(task: NSURLSessionTask) -> Request.TaskDelegate? {
        get {
            var subdelegate: Request.TaskDelegate?
            dispatch_sync(subdelegateQueue) {
                subdelegate = self.subdelegates[task.taskIdentifier]
            }
            
            return subdelegate
        }
        
        set {
            dispatch_barrier_async(subdelegateQueue) {
                self.subdelegates[task.taskIdentifier] = newValue
            }
        }
    }
    
    // MARK: NSURLSessionDelegate
    
    /// NSURLSessionDelegate override closure for `URLSession:didBecomeInvalidWithError:` method.
    public var sessionDidBecomeInvalidWithError: ((NSURLSession!, NSError!) -> Void)?
    
    /// NSURLSessionDelegate override closure for `URLSession:didReceiveChallenge:completionHandler:` method.
    public var sessionDidReceiveChallenge: ((NSURLSession!, NSURLAuthenticationChallenge) -> (NSURLSessionAuthChallengeDisposition, NSURLCredential!))?
    
    /// NSURLSessionDelegate override closure for `URLSession:didFinishEventsForBackgroundURLSession:` method.
    public var sessionDidFinishEventsForBackgroundURLSession: ((NSURLSession!) -> Void)?
    
    public func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        sessionDidBecomeInvalidWithError?(session, error)
    }
    
    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: ((NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void)) {
        if sessionDidReceiveChallenge != nil {
            completionHandler(sessionDidReceiveChallenge!(session, challenge))
        } else {
            completionHandler(.PerformDefaultHandling, nil)
        }
    }
    
    public func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        sessionDidFinishEventsForBackgroundURLSession?(session)
    }
    
    // MARK: NSURLSessionTaskDelegate
    
    /// Overrides default behavior for NSURLSessionTaskDelegate method `URLSession:willPerformHTTPRedirection:newRequest:completionHandler:`.
    public var taskWillPerformHTTPRedirection: ((NSURLSession!, NSURLSessionTask!, NSHTTPURLResponse!, NSURLRequest!) -> (NSURLRequest!))?
    
    /// Overrides default behavior for NSURLSessionTaskDelegate method `URLSession:willPerformHTTPRedirection:newRequest:completionHandler:`.
    public var taskDidReceiveChallenge: ((NSURLSession!, NSURLSessionTask!, NSURLAuthenticationChallenge) -> (NSURLSessionAuthChallengeDisposition, NSURLCredential!))?
    
    /// Overrides default behavior for NSURLSessionTaskDelegate method `URLSession:session:task:needNewBodyStream:`.
    public var taskNeedNewBodyStream: ((NSURLSession!, NSURLSessionTask!) -> (NSInputStream!))?
    
    /// Overrides default behavior for NSURLSessionTaskDelegate method `URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:`.
    public var taskDidSendBodyData: ((NSURLSession!, NSURLSessionTask!, Int64, Int64, Int64) -> Void)?
    
    /// Overrides default behavior for NSURLSessionTaskDelegate method `URLSession:task:didCompleteWithError:`.
    public var taskDidComplete: ((NSURLSession!, NSURLSessionTask!, NSError!) -> Void)?
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: ((NSURLRequest!) -> Void)) {
        var redirectRequest = request
        
        if taskWillPerformHTTPRedirection != nil {
            redirectRequest = taskWillPerformHTTPRedirection!(session, task, response, request)
        }
        
        completionHandler(redirectRequest)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: ((NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void)) {
        if taskDidReceiveChallenge != nil {
            completionHandler(taskDidReceiveChallenge!(session, task, challenge))
        } else if let delegate = self[task] {
            delegate.URLSession(session, task: task, didReceiveChallenge: challenge, completionHandler: completionHandler)
        } else {
            URLSession(session, didReceiveChallenge: challenge, completionHandler: completionHandler)
        }
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: ((NSInputStream!) -> Void)) {
        if taskNeedNewBodyStream != nil {
            completionHandler(taskNeedNewBodyStream!(session, task))
        } else if let delegate = self[task] {
            delegate.URLSession(session, task: task, needNewBodyStream: completionHandler)
        }
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if taskDidSendBodyData != nil {
            taskDidSendBodyData!(session, task, bytesSent, totalBytesSent, totalBytesExpectedToSend)
        } else if let delegate = self[task] as? Request.UploadTaskDelegate {
            delegate.URLSession(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
        }
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if taskDidComplete != nil {
            taskDidComplete!(session, task, error)
        } else if let delegate = self[task] {
            delegate.URLSession(session, task: task, didCompleteWithError: error)
            
            self[task] = nil
        }
    }
    
    // MARK: NSURLSessionDataDelegate
    
    /// Overrides default behavior for NSURLSessionDataDelegate method `URLSession:dataTask:didReceiveResponse:completionHandler:`.
    public var dataTaskDidReceiveResponse: ((NSURLSession!, NSURLSessionDataTask!, NSURLResponse!) -> (NSURLSessionResponseDisposition))?
    
    /// Overrides default behavior for NSURLSessionDataDelegate method `URLSession:dataTask:didBecomeDownloadTask:`.
    public var dataTaskDidBecomeDownloadTask: ((NSURLSession!, NSURLSessionDataTask!, NSURLSessionDownloadTask!) -> Void)?
    
    /// Overrides default behavior for NSURLSessionDataDelegate method `URLSession:dataTask:didReceiveData:`.
    public var dataTaskDidReceiveData: ((NSURLSession!, NSURLSessionDataTask!, NSData!) -> Void)?
    
    /// Overrides default behavior for NSURLSessionDataDelegate method `URLSession:dataTask:willCacheResponse:completionHandler:`.
    public var dataTaskWillCacheResponse: ((NSURLSession!, NSURLSessionDataTask!, NSCachedURLResponse!) -> (NSCachedURLResponse))?
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: ((NSURLSessionResponseDisposition) -> Void)) {
        var disposition: NSURLSessionResponseDisposition = .Allow
        
        if dataTaskDidReceiveResponse != nil {
            disposition = dataTaskDidReceiveResponse!(session, dataTask, response)
        }
        
        completionHandler(disposition)
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeDownloadTask downloadTask: NSURLSessionDownloadTask) {
        if dataTaskDidBecomeDownloadTask != nil {
            dataTaskDidBecomeDownloadTask!(session, dataTask, downloadTask)
        } else {
            let downloadDelegate = Request.DownloadTaskDelegate(task: downloadTask)
            self[downloadTask] = downloadDelegate
        }
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        if dataTaskDidReceiveData != nil {
            dataTaskDidReceiveData!(session, dataTask, data)
        } else if let delegate = self[dataTask] as? Request.DataTaskDelegate {
            delegate.URLSession(session, dataTask: dataTask, didReceiveData: data)
        }
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: ((NSCachedURLResponse!) -> Void)) {
        if dataTaskWillCacheResponse != nil {
            completionHandler(dataTaskWillCacheResponse!(session, dataTask, proposedResponse))
        } else if let delegate = self[dataTask] as? Request.DataTaskDelegate {
            delegate.URLSession(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
        } else {
            completionHandler(proposedResponse)
        }
    }
    
    // MARK: NSURLSessionDownloadDelegate
    
    /// Overrides default behavior for NSURLSessionDownloadDelegate method `URLSession:downloadTask:didFinishDownloadingToURL:`.
    public var downloadTaskDidFinishDownloadingToURL: ((NSURLSession!, NSURLSessionDownloadTask!, NSURL) -> (NSURL))?
    
    /// Overrides default behavior for NSURLSessionDownloadDelegate method `URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:`.
    public var downloadTaskDidWriteData: ((NSURLSession!, NSURLSessionDownloadTask!, Int64, Int64, Int64) -> Void)?
    
    /// Overrides default behavior for NSURLSessionDownloadDelegate method `URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:`.
    public var downloadTaskDidResumeAtOffset: ((NSURLSession!, NSURLSessionDownloadTask!, Int64, Int64) -> Void)?
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        if downloadTaskDidFinishDownloadingToURL != nil {
            downloadTaskDidFinishDownloadingToURL!(session, downloadTask, location)
        } else if let delegate = self[downloadTask] as? Request.DownloadTaskDelegate {
            delegate.URLSession(session, downloadTask: downloadTask, didFinishDownloadingToURL: location)
        }
    }
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if downloadTaskDidWriteData != nil {
            downloadTaskDidWriteData!(session, downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
        } else if let delegate = self[downloadTask] as? Request.DownloadTaskDelegate {
            delegate.URLSession(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
    }
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        if downloadTaskDidResumeAtOffset != nil {
            downloadTaskDidResumeAtOffset!(session, downloadTask, fileOffset, expectedTotalBytes)
        } else if let delegate = self[downloadTask] as? Request.DownloadTaskDelegate {
            delegate.URLSession(session, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
        }
    }
    
    // MARK: NSObject
    
    public override func respondsToSelector(selector: Selector) -> Bool {
        switch selector {
        case "URLSession:didBecomeInvalidWithError:":
            return (sessionDidBecomeInvalidWithError != nil)
        case "URLSession:didReceiveChallenge:completionHandler:":
            return (sessionDidReceiveChallenge != nil)
        case "URLSessionDidFinishEventsForBackgroundURLSession:":
            return (sessionDidFinishEventsForBackgroundURLSession != nil)
        case "URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:":
            return (taskWillPerformHTTPRedirection != nil)
        case "URLSession:dataTask:didReceiveResponse:completionHandler:":
            return (dataTaskDidReceiveResponse != nil)
        case "URLSession:dataTask:willCacheResponse:completionHandler:":
            return (dataTaskWillCacheResponse != nil)
        default:
            return self.dynamicType.instancesRespondToSelector(selector)
        }
    }
}
}
