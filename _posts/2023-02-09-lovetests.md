---
layout: post
title: How I learned to stop worrying and love the tests
category: sw-eng
---

Back in 2010 I have graduated and for lack of a better idea I chose to stick around the university and become a developer on a research project. As a consequence of that decision, I had less commercial experience when I eventually decided to look for a Real Job a couple of years down the line, but the pay was not bad for a fresh grad, I had creative freedom on the project, and a couple of published articles and a patent (pending) to my name to put in my CV, just in case it should impress someone. But this isn't supposed to be about me, but the role of testing in software engineering, so I will not dwell on personal circumstances.

The software I was working on was a C++ library for image processing, plus a [Qt](https://en.wikipedia.org/wiki/Qt_(software))-based GUI on top of it. It was pretty CPU hungry (an outcome of my lack of experience), and I did a lot of learning on the job, trying to incorporate every new language feature or other New Golden Rule of Programming that I happened to come across that week into the project. Which was probably not the best idea, as it became a loose sack of sometimes conflicting ideas, but at least for me the benefit was that I was able to try different things and see what worked, which I probably wouldn't have the opportunity to do as a commercial developer. Some of the conclusions from that work didn't really sink in until years later, when while doing something unrelated I would get an epiphany ("oh, so that was how I should have done it in that project..."), and one of those would be the usage of (unit) testing.

The problem I had in that project was that my code was very brittle. I kept coming up with ideas for improving the algorithm in regard to performance or accuracy, implementing those ideas, to only see stuff break all over. Worse still, sometimes I would learn that something was broken months later. Every time after implementing a feature, I would run through a known dataset in the GUI, checking to see if the analysis results still made sense. If they didn't, it was log reading time, trying to figure out where it went wrong. Guess you could say I did manual testing, but it clearly wasn't enough.

I eventually learned about automated tests, and particularly unit testing. It didn't make much sense to me, but because I was young and impressionable, I decided to throw myself into it, and implemented a "unit test" for every single "unit" in my code. Seeing as this was C++ software for image processing, I had a lot of classes for doing simple stuff, like coordinates of a point in 2d space:

{% highlight cpp %}
// a point in 2d space
struct Point2d { 
    // point coordinates
    int x, y; 

    // constructor, makes a point
    Point2d(int x, int y) : x(x), y(y) {
    } 

    // custom equality operator for comparing two points
    bool operator==(const Point2d &arg) { 
        return x == arg.x && y == arg.y; 
    } 

    // ... more stuff ...
};
{% endhighlight %}

I learned that I needed unit testing for my code to be super great, and as far as I could understand, a "unit" meant a class for C++ code, so I needed to write unit tests for all functions of all classes. Well, just watch me! For some reason, I couldn't be bothered to learn [GoogleTest](http://google.github.io/googletest/), so I ended up writing my own simple unit test framework, which was basically a bunch of functions checking a condition and reporting an error if it was not satisfied. But for the sake of this post, let's just pretend I was using GTest.

{% highlight cpp %}
TEST_F(Point2dTest, CheckBasics) {
    Point2d a(1, 2); // make a point
    ASSERT_EQ(a.x, 1); // check that it has the expected coordinates
    ASSERT_EQ(a.y, 2);
    ASSERT_EQ(a, a); // make sure a == a

    Point2d b(3, 4); // make a different point
    ASSERT_NE(a, b); // make sure a != b
}
{% endhighlight %}

Time to give myself a pat on the back, right?

I spent a considerable amount of time on stupid stuff like this, but soon enough I became disenchanted with the idea. Of course my point coordinates always were `(1, 2)`. Of course `a` was always equal to itself. I never had reason to touch this code, so why would its behaviour change? All my tests would (almost) always pass. For all the effort I spent, I wasn't getting a good return on my investment, and I had a lot of other work to do. Soon enough, I ditched the whole idea, my unit test app rotted, I disabled its compilation in the Makefile and that was that. Unit testing was useless, at least as far as I was concerned.

Some time later I found myself working  on a much bigger, commercial project. How I learned that (some) commercial software could be even more buggy, bloated and lacking any cohesive design is a story for another time, but in this instance, the company's customer wanted them to implement unit tests, because it was a minimal requirement to pass the bar of some "best practices" standard that they were obligated to adhere to. Well, that sounds familiar. Nothing like prescriptive golden rules that you can blindly follow to an unspecified degree, that, once checked off, allow you to put your feet up and light a cigar after a job well done. Of course, nobody at that company wanted to write the tests, which is why they brought on some sweet cheap extra "resources" from Eastern Europe. I came on as part of a small team and started looking around, and eventually implementing the tests.

Now, by that time I already had gathered some more experience, so I knew not to start at the bottom of the class hierarchy. I wanted to get as much bang for my buck as possible. What I learned by then was, [most unit testing is waste](https://rbcs-us.com/documents/Why-Most-Unit-Testing-is-Waste.pdf). Don't bother testing "units" (I never really learned what that's even supposed to mean). Test **functionality**. That might make the kind of tests you develop "functional tests", but the software development field is so full of buzzwords that override common-sense meanings, that it wouldn't surprise me if that term meant something different. Well, no matter. If your system has a hundred different classes that do menial tasks, probably at the end there is an object method or a function that puts (or attempts to put) these basic constructs into good use - either directly, or as part of a more hierarchical structure where larger objects are composed of, or derived from smaller ones, but it doesn't really matter.

Pick a piece of functionality that is actually important, perhaps one that is a full use case (if those have been identified), and write a test for it. If the system is a car, run a function that turns on the engine and check if it did turn on. Don't bother checking if there is fuel, if the amount of the fuel is less or equal to the size of the tank, whether the exhaust is clogged or any such nonsense - you will learn about that anyway if the engine doesn't turn on. Just turn the big red key and see if it worked! That might be more or less complicated, depending on how much of the environment you need to simulate (mock/stub) in your test. Perhaps you need to put the car on a treadmill for the driving test, and if the code doesn't support [dependency injection](https://en.wikipedia.org/wiki/Dependency_injection), i.e. substituting parts of the system for mocked versions for testing purposes, then you might be in for some heavy refactoring. However, once you have it down, it will give you a useful piece of 0/1 information about the system's state, and if you run it regularly (best make it part of the daily build, or any other automated pipeline arrangement you may have), you will learn immediately if there is a problem with any smaller part that makes up the system, so it can get fixed. It also gives you good code coverage stats, and if it doesn't, perhaps some code needs eliminating?

This approach can be performed iteratively, adding tests for other use cases, and eventually tests for smaller pieces that are hard to cover as part of the whole for some reason, but you are keeping time waste to a minimum, and positively contributing to the quaility of the product, reducing downtime by providing instant feedback after somebody commited code to the windshield wiper cleaning pattern that just happened to make the air conditioning break (sorry for the clumsy metaphores).

That covers (no pun intended) implementing tests for an existing system. You can do better when building something from the ground up. For one, when developing software with testability in mind, implementing the tests is going to be a lot easier, and they probably will get incorporated into the process earlier, acting as a force multiplier, letting you implement features faster, and with a greater confidence in overall stability. There really is nothing more comforting than seeing the tests pass after I implemented a big new feature in [dostrace](https://github.com/neuviemeporte/dostrace). Even when they fail, I'm grateful that they are there and just saved me hours of work hunting down a problem I unknowningly caused with my change. I don't worry as much and I think tests are [the bomb](https://en.wikipedia.org/wiki/Dr._Strangelove). 😉 

I tend to also eventually write tests for medium-sized chunks of functionality (e.g. one test per class) when writing code for my project. After I create something that's relatively complex, I will write a test for it that checks the overall operation - no getting bogged down in the details, just the large picture. It isn't as effective as a Big Test in the amount of coverage per effort expended, but more granular tests can help cover some less likely scenarios, and also give more instant feedback of what the problem is, instead of having to figure it out from the Big Test's failure in a debugger. Also, after running into a bug (either from a failure of the Big Test, or much worse by an observed problem _while the tests passes_), I will usually implement a specific test to cover it, which makes it easy to work on the fix in isolation. Implement the test, see it fail, work until it passes (set the test suite filter so it's the only one to execute), done. I guess it is somewhat similar to [test-driven development](https://en.wikipedia.org/wiki/Test-driven_development), but I think TDD is just as dogmatic as almost any other prescriptive methodology. How am I supposed to write a test before implementing the functionality, if I don't even have a good idea how it's going to work, or even what name the method will have? But that said, involving the tests in everyday development work is something that improved my productivity, the quality of the software that I write, and most importantly, it lets me sleep easy at night, because I rest assured in the knowledge that the engine still turned on after I repainted the car hot pink. 

There is en entirely different story to be told about the importance of manual testing, but it will have to wait for a different post.
