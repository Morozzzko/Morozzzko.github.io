---
layout: single
title: "Being conscious: service objects"
---

I've been programming for a long time and I've had countless arguments about different things. I'd like to list top four reasons I've had an argument online.

**Style guide.** Thankfully, the number of arguments reduces as I mature, but I'm still having them. I'd rather have an extremely opinionated styleguide and just stop talking about it. Something like [wemake-python-styleguide](https://github.com/wemake-services/wemake-python-styleguide), but for Ruby. 

**Monads.** I have to admit that this word is almost banned from my vocabulary because of how many arguments I've had about it. It's getting better, but people still like to argue about them. I [wrote an article recently](/2020/03/29/why-would-i-use-monads.html) about them in hope to show that there's nothing special about them – they're just abstractions that may or may not be helpful. It all depends on your problems and approaches.

**How to design domain logic.** It may be an extremely interesting and helpful discussion, or it may turn into a useless argument. When it goes bad, it's usually because we're trying to discuss insignificant details and lower-level things. Where do we put arguments? What about dependency injection? How do we use instance variables? Ughh! 

**Different interpretation of common terminology.** What do we mean when we say “interactor” what about “architecture”? Is it a _state_ when we're just passing values from function to function? Is duck typing _really_ an absence of types? What is a type, anyway? What does it mean to write “object oriented” code? What about “functional” approach? Do we need [immutability in OO design](https://www.yegor256.com/2014/06/09/objects-should-be-immutable.html)? Those topics lead to endless discussions with little output.

As much as I love learning about new things, those arguments are extremely energy-draining. I've been thinking: since we're usually reiterating over the same thing, why don't we just dump the knowledge somewhere? That's what I'm going to do.

I'm starting a series of blog posts about different topics in Ruby world. My goal is to describe different approaches to the same problems and highlight pros and cons of each one. Perhaps, pick a favorite.

Right now I want to focus on two larger topics:

1. Designing service objects
2. Handling errors in domain logic. Exceptions, values, result objects

This is a first post of the series, and it will cover the first topic: handling errors in domain logic.

We will go through the basics: what are we talking about when we say “service object”. We'll look through different approaches and see which ones bring the most benefit and which ones should probably be put to rest. In the end, I'm going to suggest a working design and a couple of guidelines you can use to improve your logic.

The post is going to be relatively long, so I'll make each chapter as independent as possible, for continuous reading. 

<!-- excerpt --> 

# Service objects exist for domain logic

Service object is a common pattern in Ruby community, but you might also see something similar in other languages. Python's [stories](https://github.com/dry-python/stories) were greatly influenced by [dry-transactions](http://github.com/gems/dry-transactions) and [Trailblazer](http://trailblazer.to/) — some of the tools we could have used for service objects.

The sole purpose of a service object is to be a place for your domain logic. Remember the usual models vs controllers dilemma? Well, think no more. Complex domain logic goes to service objects.

Let's step back a little and see why we need to care about the logic at all, and why we should care about its exact location.

Usually, we're building applications that solve a set of problems for a specific business. Sometimes its logic is trivial, but usually it's something a sophisticated system that backs a complex business. Sometimes the software _is_ the product that we sell. Either way, the logic becomes complex quite easily.

When we're modelling complex processess, we have to make a lot of decisions: what needs to be captured in the model; what are the names and processes; what are the boundaries; what's the shape of our data; how to organize domain logic _well_. Service objects don't answer all of our questions, but they _nudge_ us.

# They nudge us to extract logic

One of the most valuable lessons: there are lots of ways to approach modelling your domain, and you're free to combine them.

When we were working with the common model-view-controller paradigm, we had to make trade-offs and try and design logic using what we've got: models and controllers. Concerns, if you're advanced enough. We put domain logic in the models, application logic in the controllers, and we get our happily ever after. 

What if the logic doesn't fit the model, though? It happens when the relationship is not obvious, or when the process affects multiple models. Here's a few examples where the solution is not as obvious:

* Does an applicant get a job at a company, or does the company hire the applicant? 
* Does a buyer sell the goods, or does the customer buy the goods? 
* What if we're trying to match people by their taste in music? How do we measure it? Is it `jane#compare(john)`, or is it the other way around? Is it something else?
* What if we're firing someone? Does a manager fire the person? Does the person fire themself? What if HR initiated the process, not the manager? What if it's a layoff? 

Sometimes, the processes in our business are a bit more complex to be _reasonably_ put into a specific model. There are usually different solutions:

**Add multiple entry points** like `Group#add` and `User#add_to_group`. Works best if you've found a way to avoid duplication.

**Create a new model.** It works best if the model matches the real-world domain. It's reasonable to have a `JobApplication` which can be accepted or rejected.

**Extract the logic** into a function / procedure. It feels quite natural to have an option to call `hire_candidate`. 

**Note:** I've been saying "model" quite a lot. It's not always about ActiveRecord::Model, though. It can be a plain Ruby object or Sequel::Model too.
{: .notice--info }

Service objects nudge us to to the latter – extract the logic into a function or a procedure. Except, we're using classes and objects instead of "real" functions. Hence the name.

# The many forms of a service object

Here's the thing about service object: it's not really a well-documented pattern. People try to figure out how to design them in a meaningful way, and they get different results.

There's a lot of ways to categorize the service objects, with different level of detail. I'm going to take a shot adn categorize by the service object behavior.

**The doer** is an service object which has the `-er` suffix in the name. It has a name like `OrderCreator`, `UserRenamer`, `PurchasePlacer` or something similar. This object looks like it's a person fulfilling their job, and usually doesn't exist in the business domain. In some cases, it may clash with the terminology. `OrderCreator` may be both a person who placed the order _and_ a service.

```ruby
class OrderCreator
  def create(...) # or call / perform / etc
    ...
  end
end
```

**The multitool** is a service which fulfills many jobs at once. For instance, `OrderManager` may assign and remove couriers, update delivery dates and even cancel the order. Everything is centered around a specific entity.

```ruby
class OrderManager
  def initialize(order)
    ...
  end

  def assign(...) 
    ...
  end
  
  def cancel(...) 
    ...
  end

  def reschedule(...) 
    ...
  end
end
```

**The event** is a service object which models a process which starts when _a specific event_ occurs. It's usually a complex multi-step process. The name usually captures the name of the event: `ApplicationSubmitted`, `OrderShipped`, `UserBlocked`, and so on.

```ruby
class OrderPlaced
  def call(...) # or handle / perform / etc
    ...
  end
end
```

**The command** is a lot similar to _the event_, except it's designed as an imperative action in your domain. The object has a name similar to `SubmitApplication`, `SubmitOrder`, `BlockUser`, etc. It may look like _the doer_ except for one major difference: the doer has a poor naming. 

```ruby
class SubmitOrder
  def call(...) # or handle / perform / etc
    ...
  end
end
```

Other service object approaches usually fit within one of those four groups. If I've missed out on something, please let me know at igor@morozov.is.

I'm going to be blunt with you and say that _the doer_ and _the multitool_ are the service objects you should probably throw away and replace them with something else. Let's see what their problem is:

**The doer** is like _the command_, except it has a poor naming. Instead of capturing something real like an action, it's modelled as if it's a full-grown entity in your business. In most cases your business does _not_ have a `SomethingCreator`, but it has an process to `CreateSomething`. There's a huge benefit in speaking a natural language instead of inventing your own, so let's just move on and __turn all doers into commands__.

__The multitool__ is a nice attempt at a service object, but has a couple of fundamental flaws.

* Similar to _the doer_, the name doesn't capture domain pretty well. I've seen people choose names like `OrderManager` or `OrderService`. Neither of those really exists in the domain.
* Is it really a “service”, or is it a model in disguise? You may achieve similar level of isolation by extracting the logic to a module / a concern and including it to your model. 

While I can totally understand the desire to use this design because it extracts and isolates the logic and makes it _feel_ like everything is better, I'd advise everyone to take a deeper look at their own paradigm and see if there are better tools to solve their problems. 

Why did people even have to stray away from the good old object-oriented _model_? Perhaps, there are better approaches in Eventide's [useful object](http://docs.eventide-project.org/user-guide/useful-objects.html#overview), Yegor Bugaenko's [Elegant Objects](https://www.yegor256.com/elegant-objects.html) or Ivan Nemytchenko's [Rails Hurts → Painless Rails](https://railshurts.com/). I'm no expert in any of those things, so I'll speak about useful _service_ objects.

# The helpful ones: the command and the event



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

critique:
https://avdi.codes/service-objects/
https://www.codewithjason.com/rails-service-objects/

