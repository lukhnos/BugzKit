BugzKit
=======

BugzKit is an Objective-C library for the FogBugz API. This is what we at Lithoglyph used to develop LadyBugz, a FogBugz client for the Mac.

Since Lithoglyph has discontinued developing the application, I think we should open up the library so as to give the app (at least in spirit) a new life. This library should be useful in creating new FogBugz clients on both the Mac and the iOS platforms.

For now there is no documentation on how to use it. I will try to furnish with examples if I have time.

Basically, the library is designed to separate request objects (objects that encapsulate API request details) and request operations (the actual worker objects that make the HTTP requests and handle the response). This allows the library to be used in a multithreaded app, backed by NSOperation objects and operation queues.

Copyright
---------

Copyright (c) 2007-2011 Lukhnos D. Liu.

This library is released under the MIT License.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

*   The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
