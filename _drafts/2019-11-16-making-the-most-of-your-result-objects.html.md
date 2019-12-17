---
layout: single
title: "Making the most of your result objects"
date: "2019-11-16 17:52:00+0300"
header:
  og_image: "/assets/images/previews/result-objects.png"
---

Result objects are a popular patterns in the Ruby community. We use them one way or another:

* [Interactor](https://github.com/collectiveidea/interactor) uses `context` as a form of result object
* [dry-transaction](https://dry-rb.org/gems/dry-transaction/0.13/) and [dry-monads](https://dry-rb.org/gems/dry-monads/1.0/) use Result (Either) monad as a result object
* We store the result in the service/use case/interactor's instance attributes
* We build our own result objects

There's a great article [ruby pigeon](https://www.rubypigeon.com/posts/result-objects-errors-without-exceptions/) to read it on result objects and why we use them.

In this article, I would walk through the design and implementation of our own result object using plain Ruby and supercharging it using `yield` and Ruby 2.7's [pattern matching](https://medium.com/cedarcode/ruby-pattern-matching-1e84cab3b44a). I will explain design decisions made by popular libraries and how they work.

<!-- excerpt -->

## What is a result object

Result object is a generic name for a number of patterns. I haven't found a comprehensive description, so I went to [Saint P Ruby Community telegram](https://t.me/saintprug/46186) to help me find one.

Here's a list of what I've got:

A result object is ...

* a monoid in the category of endofunctors
* a sum type with two unary constructors
* a PORO-thingie with data inside and public methods to check for result
* an object you'd return when the computation result is a set of unrelated or loosely related values, and we don't want to use hash or array for grouping them together
* an object that contains computation result and a flag representing the "successfulness" of the operation
* a container with arbitrary data plus a flag that represents the "successfullness" of the computation
* a wrapper object that indicates whether or not the API call was a success, and includes the data if it was – a definition from [Braintree API](https://developers.braintreepayments.com/reference/general/result-objects/ruby)


## Why result objects

We use result objects to represent the result of a function and say if it was a success or a failure.

Conventionally, Ruby has exceptions for this – you raise an exception if there's an error. You'd to catch it and voilà – here's your result, do whatever you want.

1. Errors become first-class residents of your application
2. It becomes easier to figure out all possible outcomes
3. The code becomes simpler, easier to write and a little more performant
4. Complex logic becomes easier to read, compose and design

For what it's worth, the ideological ones are about pragmatism too. Let's talk about them a little.

### Errors become first-class residents of your application


### It becomes easier to figure out all possible outcomes


### The code becomes simpler, easier to write and a little more performant


### Complex logic becomes easier to read, compose and design

