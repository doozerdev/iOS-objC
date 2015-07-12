iOS
===
The project uses CocoaPods, a dependency management system for iOS development. The only dependency right now is AFNetworking, which I'm not actually using for this first commit. But it will make communicating with the webservice easier.

In order to build it, you need:

  1. Install XCode 6
  2. Install CocoaPods (sudo gem install cocoapods)
  3. clone the source (git clone ...)
  4. In the source directory, run 'pod install', which will end up downloading AFnetworking
  5. Open the Doozer.xcworkspace file in XCode
  6. Click the 'play' button

Note that I'm using UISearchBar as the text entry field since it was the closest thing to what Becca spec'd. It just appears at the top of the list, not whenever you scroll up. And since it's a search bar, it is still using the magnifying glass icon and has the text 'search' on the keyboard. 

But let's just call those 'bugs'...
