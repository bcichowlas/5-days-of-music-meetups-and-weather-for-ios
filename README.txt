Here's an iOS app that integrates Dark Sky and Meetup, showing relevant
music-related events in the proximity for the five days of weather data returned
by Dark Sky.

It provides an example of using a table of varying size WKWebViews in a table with the sizes adjusting to the received contents.  This is currently a tricky manner, since WKWebView signals "onFinish" before the scroll sizes have been set.  This app gets around that by using KVO.

If you run it on the Xcode Simulator, be sure to have a Location
defined.

