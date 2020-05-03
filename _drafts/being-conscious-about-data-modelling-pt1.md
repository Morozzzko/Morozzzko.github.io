---
layout: single
title: "Being conscious: service objects"
---

I've been programming for a long time and I've had countless arguments about different things. I'd like to list top four reasons I've had an argument online.

**Style guide.** Thankfully, the number of arguments reduces as I mature, but I'm still having them. I'd rather have an extremely opinionated styleguide and just stop talking about it. Something like [wemake-python-styleguide](https://github.com/wemake-services/wemake-python-styleguide), but for Ruby. 

**Monads.** I have to admit that this word is almost banned from my vocabulary because of how many arguments I've had about it. It's getting better, but people still like to argue about them. I [wrote an article recently](/2020/03/29/why-would-i-use-monads.html) about them in hope to show that there's nothing special about them – they're just abstractions that may or may not be helpful. It all depends on your problems and approaches.

**How to design business logic.** It may be an extremely interesting and helpful discussion, or it may turn into a useless argument. When it goes bad, it's usually because we're trying to discuss insignificant details and lower-level things. Where do we put arguments? What about dependency injection? How do we use instance variables? Ughh! 

**Different interpretation of common terminology.** What do we mean when we say “interactor” what about “architecture”? Can we speak about _state_ when we're just passing values from function to function? Is duck typing _really_ an absence of types? What is a type, anyway? What does it mean to write “object oriented” code? What about “functional” approach? Do we need [immutability in OO design](https://www.yegor256.com/2014/06/09/objects-should-be-immutable.html)? Those topics lead to endless discussions with little output.

As much as I love learning about new things, those arguments are extremely energy-draining. I've been thinking: since we're usually reiterating over the same thing, why don't we just dump the knowledge somewhere? That's what I'm going to do.

I'm starting a series of blog posts about different topics in Ruby world. My goal is to describe different approaches to the same problems and highlight pros and cons of each one. Perhaps, pick a favorite.

Right now I want to focus on two larger topics:

1. Designing service objects
2. Handling errors in domain logic. Exceptions, values, result objects

This is a first post of the series, and it will cover the first topic: handling errors in domain logic.

We will go through the basics: what are we talking about when we say “service object”. We'll look through different approaches and see which ones bring the most benefit and which ones should probably be put to rest. In the end, I'm going to suggest a working design you can 

The post is going to be relatively long, so I'll make each chapter as independent as possible, for continuous reading. 

<!-- excerpt --> 

# The purpose of a service object

Service object is a common pattern in Ruby community, but you might also see something similar in other languages. Python's [stories](https://github.com/dry-python/stories) were greatly influenced by [dry-transactions](http://github.com/gems/dry-transactions) and [Trailblazer](http://trailblazer.to/) — some of the tools we could have used for service objects.

The sole purpose of a service object is to be a place for your business logic. 

Let's step back a little and see where it comes from and what problem it solves.

Usually, we're building applications that solve a set of problems for a specific business. Sometimes its logic is simple, but usually we're building something more sophisticated that supports a complex product or a business.

When we're modelling complex processess, we have to make a lot of decisions: what needs to be captured in the model; what are the names and processes; what are the boundaries; what's the shape of our data; how do we implement domain logic.

# Guidelines for helpful service object

Here's my own set of rules that help me build and maintain service objects. Those rules assume we're building single-method services in a mix of functional, object-oriented and procedural style.

**Pick the interface.** I use `#call`, but there are other options: `#run`, `#perform`, and some others. Anything works – just make sure to stay consistent throughout the project

**Expose errors and code smells early.** Focus your desing on exposing overly complex code as early as possible, while maintaining flexibility. 

**Pass arguments to `#call`, not the constructor.** While this advice will make you type a little more, the benefits are astonishing. 

**Use constructor to configure the concrete service.** This includes passing dependencies and magic values you'd put in constants. It enables you to tweak your logic whenever you need it. 





# References

https://hackernoon.com/the-3-tenets-of-service-objects-c936b891b3c2
https://medium.com/selleo/essential-rubyonrails-patterns-part-1-service-objects-1af9f9573ca1
https://medium.com/@scottdomes/service-objects-in-rails-75ca74214b77
https://www.toptal.com/ruby-on-rails/rails-service-objects-tutorial
