**Overview**
This package provides a swift implementation of the Dubins-Curves github repo by Andrew Walker (and other contributors) located at:

[Dubins-Curves](https://github.com/AndrewWalker/Dubins-Curves)

I've done a bit of refactoring to make it a little more "swifty", and have reimplemented all of the supplied test cases to ensure that I've not broken anything.

**Additional**
What this package also does, is provide a wrapper that allows the result of the path computation to be converted to a CGPath for
the purposes of animating sprites that will follow that path.

A demonstration project is included to show this in action.
                
