BugzKit
=======

BugzKit is an Objective-C library for the FogBugz API. This is what we at Lithoglyph used to develop LadyBugz, a FogBugz client for the Mac.

Since Lithoglyph has discontinued developing the application, I think we should open up the library so as to give the app (at least in spirit) a new life. This library should be useful in creating new FogBugz clients on both the Mac and the iOS platforms.


Design Concepts
---------------

Basically, the library is designed to separate request objects (objects that encapsulate API request details) and request operations (the actual worker objects that make the HTTP requests and handle the response). This allows the library to be used in a multithreaded app, backed by NSOperation objects and operation queues.


Walking Through the BasicRequests Demo
--------------------------------------

Perhaps the best way to understand how this framework can be used is to walk through the `Examples/BasicRequests` sample.

To build the example, first checkout this project, then go to `Examples/BasicRequests`, and make a copy of `AccountInfo.template.h` and name it `AccountInfo.h`, and fill in your FogBugz account details.

The Xcode project file `BasicRequests.xcodeproj` is made using Xcode 4, but I've also tested with the latest Xcode 3.2.1. Please note that the sample app is built with 64-bit Debug config. I haven't tested it on any 32-bit config and there might be things you want to take care of (I've commented those things in the source code).

In this sample app (note: a command-line tool), we want to do a few things:

*   Check the API availability
*   Login
*   Fetch three lists -- projects, people, milestones
*   Logout

Apparently, each task depends on the successful execution of the previous task.

BugzKit solves the dependency problem by separating "request objects" and "request operations".

A "request object" (like `BKLogOnRequest`, `BKListRequest`) encapsulates the information required to make a request (URL, auth token, parameters, HTTP method, etc.) and also handles the received information.

A "request operation" is an object that actually makes the HTTP request and pass the received data to the request object. It also handles error, cancellation, status callback, among many other things.

BugzKit only provides you `BKRequestOperation`, a skeleton. You need to fill in the details how you want to make the requests and handles the many states that a network operation involves. In the sample app, I've supplied a simple `RequestOperation` class, which uses `-[NSData dataWithContentsOfURL:]` to make the HTTP/HTTPS request. In reality you want to use a more sophisticated way so that you can cancel the ongoing requests, among many other things you want to do. `NSURLConnection` is what you're looking for. Many people in the Mac/iOS community uses [ASIHTTPRequest](http://allseeing-i.com/ASIHTTPRequest/). I have my own HTTP request class in the [ObjectiveFlickr](https://github.com/lukhnos/objectiveflickr) library, too.

Take a look at `RequestOperation.m`, and you'll understand why I leave so many implementation details to you. 

After the request operation has received the HTTP payload, it has to convert the raw byte stream into meaningful data. FogBugz uses XML, and BugzKit supplies a `BKXMLMapper` helper class to first parse the XML then map the elements to an NSDictionary, much like what many XML-to-JSON libraries do. Using NSDictionary and NSArray objects to manipulate structured data is way then dealing with XML.

A very important note here: `BKXMLMapper` has an option to let you use `NSXMLParser` (default) or libxml2. Both libraries are unfortunately either totally thread-safe or garbage collection-compatible. `BKXMLMapper` takes care of the thread-safe issue by using putting using the `@synchronized` block. If you want to make a number of large requests at the same time, the XML parsing phase can become a bottleneck. And that they leak memory in GC is one of the reason LadyBugz couldn't use GC. FogBugz API actually only uses a small subset of XML, and it should be possible to pick an efficient, thread-safe, GC-compatible XML parser to work with BugzKit.

After the request operation has the NSDictionary object at hand, it passes the dictionary to the request object's `rawXMLMappedResponse` property. It is at this stage that the request object *processes* the data, and determines if there's an error. If there's no error, the untyped `processedResponse` (more accurately, the `id`-typed) will contain the processed response, the type of which (usually either NSDictionary or NSArray) depends on the nature of the request. If an error is the response from the server, the `error` property will be set an NSError object.

Once we have a basic request operation class, we can start do the real work. For each task listed above, we:

1.  Create a request object
2.  Create a request operation object and load the request object into the operation (at initialization)
3.  Specify how we want to handle successful completion or failure for each operation
4.  Add dependency (see Apple's `NSOperation` API documentation on how this works)
5.  Add the operation to an operation queue

In our sample, we also have a `convergeBlockOperation` which is a plain-vanilla `NSBlockOperation`. The operation gets executed after all its dependencies are done. If none of its dependencies failed, then the operation schedules a logout request operation.

The sample app also schedules a runloop in the main thread and only quits the runloop when the last operation requests so.


Coverage of this API Library
----------------------------

A lot of things in FogBugz are not covered in the API library, such as Wiki and time tracking. It should not be hard to extend the library for those purposes.

`BKEditCaseRequest` and `BKMailRequest` are capable of handling file attachments for you. When you initialize those objects, there's an init method that takes an array of URLs as one of its arguments. Those URLs must be file URLs, and the request objects will create the necessary temp files for you under the hood, and you can use the `requestInputStream` property to get a read stream for the raw bytes data, which you send as the multipart HTTP request body.

The definitive FogBugz API guide is of course http://fogbugz.stackexchange.com/fogbugz-xml-api.

Finally, this library does not make any guarantee that the library is up to date.


Copyright
---------

Copyright (c) 2009-2011 Lukhnos D. Liu.

This library is released under the MIT License.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

*   The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
