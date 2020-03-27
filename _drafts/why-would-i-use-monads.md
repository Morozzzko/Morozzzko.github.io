---
layout: single
title: Why should I use monads?
toc: true
---

A couple of weeks ago I witnessed a dialog in a [Ruby chat](https://t.me/rubylang). I'm paraphrasing, but it went like this:

> xxx: What is `dry`? I've seen this gem prefix and discussions, but never actually learned about it. <br />
> yyy: It's a set of libraries to tackle some problems. <br />
> zzz: Yeah, and introduce new ones. Like "How do I explain to my colleague that they need monads".

Let's be honest. I felt so many emotions that I couldn't think straight. I've been discussing this exact topic so many times that I've exhausted myself. There's a lot of misconceptions, frustration and plain skepticism, which lead to aggressive rejection.

Right now, I want to finish this topic once and for all. Not going to achieve it in this post, though. I'm writing a huge piece on error handling techniques in Ruby, which will cover strong and weak points of different error handling techniques in Ruby, including monads.

In _this_ post, I will try to step back and speak about monads from a more practical and emotional perspective. I will briefly explain what a monad really is, why is it valuable, and some of the common problems people face while using it.

<!-- excerpt --> 

# What is a monad

When we're speaking about Ruby, we're usually talking about [dry-monads](https://dry-rb.org/gems/dry-monads/) – a library that implements them. But really, what are they?

> A monad is just a monoid in the category of endofunctors. What's the problem?

The internet is full of jokes like this. It's a formal definition, but it's _so vague_. However, most definitions won't give anything concrete. It's like trying to give a proper definition to a "musical instrument". It's going to be either vague and correct or understandable and incomplete because they are helpful in different ways. I'll take a shot and give you somewhat correct, but a little vague explanation.

Let's just say that `monad` is just a ~~fancy~~ mathematical name for abstractions that behave in a [specific way](/2018/09/08/monad-laws-in-ruby.html). In theory, it lets us chain them, compose them in different ways. In practice, we'd rarely even notice the monadic nature of those abstractions, because it works seamlessly. Let's focus on individual monads and see what _they_ bring to the table.

**Fact**: Ruby's built-in `Array` and `String` are monoids too. We never think about it — that's how we should treat monads too.
{: .notice--info }

[Maybe](https://dry-rb.org/gems/dry-monads/1.3/maybe/) is an abstraction that allows us to express _absense of data_. In practice, it enables us to do nil-safe computations and never worry about catching `undefined method for nil:NilClass`. It acts like an _extremely explicit_ alternative to `nil`. It may be good when you return it from a repository, but I don't use it my models.

[Try](https://dry-rb.org/gems/dry-monads/1.3/try/) is a nice wrapper for exceptions. It's helpful if you need to chain some actions, which may raise an exception. The standard exception-catching mechanism may break the flow and make you jump around the code to get the full picture. Try saves you from this.

[Task](https://dry-rb.org/gems/dry-monads/1.3/task/) is a wrapper around [concurrent ruby's](https://github.com/ruby-concurrency/concurrent-ruby) `Promise`. I've seen folks use it as an easy way to do concurrent IO – download things, write to database, etc. Just take at look at Vasily Kolesnikov's [asynchronous file downloader](https://gist.github.com/v-kolesnikov/c5807aab0ac7ba5d1ba5e31be32e21e6). It's plain and simple yet powerful.

[Result](https://dry-rb.org/gems/dry-monads/1.3/task/) is the most common _monad_ in a Ruby world. We use it to express result of an operation call. It's most useful when the result can be a `Success` or a `Failure`, which works as natural as it sounds. You can just `return Success(with_your_data)` from your function and work with it. If something goes wrong, you can just `return Failure("and provide some details")`. Be cautious: it's not a full replacement for exceptions.

There are also some other monads, but I'll omit them as those are not _that_ common and won't benefit to the story. 

# The beef with monads

So, what's the problem with monads? They seem to be a pretty controversial topic, but why? They seem to be pretty good at doing their job. What's wrong with that?

Some people are even trying to [add their own monads to Rails](https://github.com/rails/rails/issues/37875). 

Everyone has their own problems with monads. Some folks get mildly annoyed by little things. Others are outraged that such an abomination exists in Ruby. Just see what folks have been saying to me:

* Monads are only useful in statically typed languages and only cause trouble in Ruby
* Functional programming doens't look right in Ruby
* Monads don't feel like a right fit in Ruby
* It's just a syntactic sugar for if and else (_speaking about Result_)
* We have exceptions for that (_speaking about Result_)
* It's over-engineering
* People who use monads look like a cult
* Don't try to bring Haskell into Ruby

It's just a list of things off the top of my head. Sure, I'm paraphrasing, but the main idea looks like this. 

Some people who share those things are nice, friendly and welcoming; while some are hostile and won't accept any reason. I won't try to generalize based on their background or any other factor. Instead, I will address some misconceptions and speak about emotions that drive them.

## Is Ruby really the right place for those things?

This issue is probably the most popular one. There's actually a lot of reasons for this skepticism:

1. Monads are a concept from the category theory. Their representation in software development is mostly `Haskell`, which uses them _heavily_. It's definitely not a mainstream language. It surely causes some traction, as people associate monads with something difficult and clumsy
2. The `Result` type gets a lot of usage in Rust, Kotlin, Swift, F#, OCaml/ReasonML, Haskell and Elm. All of those languages are statically typed, which lets their compilers do some static analysis. For example, the compilers may check if you've handled all possible cases. Those checks are nearly impossible to implement in Ruby
3. Ruby is an object-oriented language. Monads are a concept from functional programming, which may seem a bit odd and counterintuitive.
4. When you take a look at dry-monads, you'll see unfamiliar methods like `#bind`, `#fmap`, `#or_fmap`. Those things require some additional learning and are not so trivial
5. The so-called [do notation](/2018/05/27/do-notation-ruby.html) is a syntactic sugar which looks unfamiliar to Ruby developers
6. Combining different kinds of monads may be troublesome. As an example, you may treat `Result` as a `Maybe`, which will definitely result in bugs.
7. It requires extra effort

Those things boil down to four points:

1. Are they really idiomatic?
2. Are they useful?
3. What trouble will they cause? Will they create bigger problems?
4. Is it difficult to learn?

I'll speak about the usefullness and problems in [Perspective of a developer](#TBA), so let's see if it's idiomatic and/or difficult.


## What about exceptions?

We use `Result` to express the logic which may fail or not. Let's imagine a simple use-case – user tries to log in and fills in username/password combination. 

1. We make sure that user has provided username and password. If not, we fail
2. We make sure the username exists in our system. If not, we fail and suggest them to register
3. We make sure the password is correct. 
   a. If not, we try to check if it is one of the user's old passwords. If so, fail and tell them they've changed passwords a while ago.
   b. If it's just an unknown password, fail and tell them the password is incorrect.
4. Make sure the user is not blocked in our system. Fail and warn them about it if they are
5. Create new session

This is a common, yet complex enough example. It consists of multiple steps and has six outcomes: five unsuccessful and one successful. Actually, it has even more outcomes – there are also things that do not concern this process; those things include connectivity issues, out-of-memory errors and other technical difficulties.

A lot of programmers would design this process using exceptions. They'd create five exception classes and just `raise` them on demand. The higher-level code would have to `rescue` them and handle as necessary. 

`Result` is an alternative approach to this design. It suggest that you return a `Success` or a `Failure` with whatever metadata you need. The higher-level code would have to handle it using whatever they want – `if`, `case`, `case in` or something fancier. 

It's actually a matter of preference. Is failure a special case? How does your code make decisions? What fits you better? The difference and similarities of the two techniques deserve their own article, which I'm working on, but I want to emphasize something:

> Exceptions are not an adequate replacement for Result, nor is Result an adequate replacement for exceptions. At least in Ruby

Those things serve different purpose:

1. Result is a way to express your _data_
2. Exceptions are a control flow mechanism

You may replace one with another, but it _might_ be better for them to coexist. 

Remember I said about Rust, Kotlin, Swift, F#, OCaml/ReasonML, Haskell and Elm? Some of them have _both_ Result and exceptions. I encourage you to take a look at how they coexist in those languages and learn from them. Perhaps, it could bring our Ruby code to the next level.

## Perspective of a developer

As a developer, I'm a fan of simple, yet efficient designs. Life is not that easy, so I have to deal with complex designs most of the time. 

When I'm dealing with something complex, I want to work with things that don't confuse me or my teammates. Yet, I'm ready to learn something new, especially if it's a fundamental knowledge. That's why I'm enthusiastic of domain-driven design.

What does it all have to do with the topic? Well, here's the thing. I like monads exactly because they give me exactly what I need. Let me elaborate on that.

I can choose to use monads in a confusing way. Just pretend it's Haskell and write a chain of fmaps, binds and other fancy words. However, I don't need to. I don't even have to _think_ I'm using a monad.

In [What is a monad](#TBA) I've listed four different monads and why they exist. They help me answer the main question: "what's going on here?". This happens because I become _explicit_ about my intentions. I `return Success(...)` when everything is good, I `Try` to run some code which may fail with an error, I perform a `Task`, and I will `Maybe` get a value when I query the database. There's nothing too mathematical about them – 



# How do I persuade my team to use monads

I had to answer it for the first time when [Janko](https://github.com/janko) approached me after EuRuKo 2018 to talk about it. I had no idea then, but I have some ideas now.


