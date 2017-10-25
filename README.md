# README #

Yelpic is an app for browsing pictures of businesses around you on Yelp.

### How do I get set up? ###

Before use, register for the Yelp API [here](https://www.yelp.com/developers/documentation/v3). 

Once you have your client\_id and client\_secret, open Config.plist, and enter those values in the appropriate places. 

### What's Included? ###

A demo of evolving app design and refactoring. Starting from the Tag BASELINE, you can see an app that kinda works, kinda. There's really no error handling, everything's all in one view controller, and the caching/recycling of cells is kinda wonky. Going through the subsequent commits, one can see a process of bringing these responsibilities out into their own files, thus lessinging the responsibiities of the singluar view controller. The result, while possibly overkill for a small, simple app, is a codebase that is much more decoupled and testable than was started with. 
