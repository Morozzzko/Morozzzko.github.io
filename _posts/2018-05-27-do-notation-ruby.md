---
layout: single
title: "Using do notation in Ruby for Railway Oriented Programming"
date: '2018-05-27 13:25:00 +0300'
---

Railway oriented programming is a design pattern which helps you
handle errors in your application. Instead of relying on exceptions,
you will design your data and functions in a specific way. Here's
how it often looks in practice:

* There is a `Result` type, which can be either a `Success` or a `Failure`
* `Success` and `Failure` are practically containers with different data
* Functions that work with data accept `Result` and return `Result`
* Once a function returns `Failure`, we stop further execution

I want to emphasize that `Result` is just an alternative name for the `Either`
monad. Railway Oriented Programming comes from functional programming,
so it is tightly related to the usual FP concepts like monads, composition, and many
others. However, you don't need to have an extensive knowledge of monads to
use ROP in your code. In this article, I'll show you how to write railway-oriented
code in Ruby.

## ROP with dry-transaction

There is a [dry-transaction](http://dry-rb.org/gems/dry-transaction/) gem
which provides a DSL to build railway-oriented business transactions.
The core part of the gem is [dry-monads](http://dry-rb.org/gems/dry-monads/)
which provides the [`Result` type](http://dry-rb.org/gems/dry-monads/result/)
and tools to work with it.

To create a railway-oriented operation, you'll need to do a few things:

* Create a class and `include Dry::Transaction`
* Define a few methods that return either `Success` or `Failure`
* Use step adapters to chain those methods together

Then, you could instantiate the class and pass any input to the `#call` method.

Here's how it looks like:

```ruby
class MyOperation
  include Dry::Transaction
  include Dry::Monads

  step :validate
  step :log
  step :persist

  def validate(data)
    if data.valid?
      Success(name: data.name, age: data.user_age)
    else
      Failure("something went wrong")
    end
  end

  def log(name:, **rest)
    print("User name is #{name}")

    Success(name: name, **rest)
  end

  def persist(name:, age:)
    ...
    # some business logic here
    ...
    Success(name: name, age: age)
  end
end

MyOperation.new.call(...)
# ^ can return either
# Success(name: ..., age: ...)
# or Failure("something went wrong")
```

As you can see, we use class-level `step` method to compose the `validate`,
`log` and `persist` methods. `Failure` returned from `validate` halts the
further execution.

Pros of the approach:

* It's plain Ruby
* It allows us to reuse steps
* It works!
* Chained methods don't need to unwrap the input

Cons of the approach:

* The DSL has a weaker control over your program's flow — conditionals look awkward
* The `Result` object that you pass around keeps accumulating data and becomes
  enormous, so you have to use `**rest` in your function signatures
* Database transactions were hard to implement until [around step](http://dry-rb.org/gems/dry-transaction/around-steps/) came around. Still awkward, though

## dry-monads to the rescue

Since dry-transaction is based on dry-monads, we could probably build something
ourselves, right?

`Result` has a few methods to help you chain those monads:

* `bind` applies unwrapped `Success` value to the block, which should return a `Result` object. No-op on `Failure`
* `fmap` is similar to `bind`, but wraps the returned value into `Success`
* `or` is similar to `bind`, but for `Failure`
* `or_fmap` is similar to `fmap`, but for `Failure`
* `tee` does the same thing as `bind`, but returns input if the result is a `Success`
* `success?` and `failure?` tell you which kind of `Result` it is
* `value_or` extracts the value from `Success` or returns fallback value

This is how the same example would look like using raw monads:

```ruby
class MyOperation
  include Dry::Monads

  def call(data)
    validate(data).bind(method(:log)).bind(method(:log))
  end

  def validate(data)
    if data.valid?
      Success(name: data.name, age: data.user_age)
    else
      Failure("something went wrong")
    end
  end

  def log(name:, **rest)
    print("User name is #{name}")

    Success(name: name, **rest)
  end

  def persist(name:, age:)
    ...
    # some business logic here
    ...
    Success(name: name, age: age)
  end
end
```

The differences:

* Plain methods instead of a DSL
* Better control over flow of our application: more methods to

However, there are some disadvantages to the approach

* Having to use `#method` is hideous. Using callable objects helps
* You still have to pass **all** parameters to each function
* Complex logic gets awkward as you add `#or` and `#or_fmap` to the chain
* It doesn't halt execution if a function returned a `Failure`, so you'll have
  to work around that

Since 1.0.0.beta1 of dry-monads, there's a solution to the problems: do notation.

## Do notation in Ruby

Just like Haskell's do notation, dry-monads' do notation allows us to write
railway oriented functions in an imperative style.

Let's see how this works:

```ruby
class MyOperation
  include Dry::Monads
  include Dry::Monads::Do.for(:call)

  def call(data)
    validated_data = yield validate(data)

    log(validated_data[:name])

    persist(validated_data)
  end

  def validate(data)
    if data.valid?
      Success(name: data.name, age: data.user_age)
    else
      Failure("something went wrong")
    end
  end

  def log(name)
    print("User name is #{name}")
  end

  def persist(name:, age:)
    ...
    # some business logic here
    ...
  end
end
```

The core points:

* A new mixin: `Dry::Monads::Do.for(:call)`
* `yield` halts the execution if the function returns `Failure`
* No need to unwrap the monad: `yield` does it for us
* `log` and `persist` no longer need to return `Result` as they don't affect the flow
* We don't have to stick to declarative style anymore

## Performance

The reason I wrote the article is that I wanted to benchmark do notation
and compare its performance against dry-transaction.

The questions I wanted to answer:

* Is do-notation faster than dry-transaction?
* What are the performance differences between happy and not-so-happy paths?
* What kind of performance drop do we have as we add more steps?

So I wrote a simple benchmark to test those things. Design decisions:

* No IO or loops
* Simple arithmetics is good enough
* Objects behave like pure functions

The algorithm I tested looks as follows:

* Multiply input by 2
* If the result is greater than 100, return an error
* Add 2

Total: 3 steps.

Benchmark output:

```
Warming up --------------------------------------
  do-notation: happy    33.809k i/100ms
do-notation: failure    14.274k i/100ms
  transaction: happy     5.878k i/100ms
transaction: failure     5.867k i/100ms
Calculating -------------------------------------
  do-notation: happy    387.914k (± 1.4%) i/s -      1.961M in   5.056134s
do-notation: failure    152.445k (± 1.7%) i/s -    770.796k in   5.057752s
  transaction: happy     59.981k (± 3.0%) i/s -    299.778k in   5.002999s
transaction: failure     60.327k (± 1.5%) i/s -    305.084k in   5.058375s

Comparison:
  do-notation: happy:   387913.7 i/s
do-notation: failure:   152445.2 i/s - 2.54x  slower
transaction: failure:    60327.4 i/s - 6.43x  slower
  transaction: happy:    59981.0 i/s - 6.47x  slower
```

So what do we see:

* dry-transaction performance isn't really affected by failures
* do notation becomes approximately 2.5 times slower if we get a `Failure`
* Do notation is over _six_ times faster than dry-transaction

## Heavier benchmark

Alright, so we had a benchmark that worked with three steps that could
_theoretically_ return `Failure`. But real-world apps are way more complex
than that. So I decided to add more steps and see what happens.

Algorithm:

* Multiply input by 2
* Add 2 three times
* If the result is greater than 100, return an error
* Add 2 four times

Total: 9 steps.

Benchmark output:

```
Warming up --------------------------------------
  do-notation: happy    10.384k i/100ms
do-notation: failure     9.282k i/100ms
  transaction: happy     2.084k i/100ms
transaction: failure     2.083k i/100ms
Calculating -------------------------------------
  do-notation: happy    108.311k (± 1.3%) i/s -    550.352k in   5.082157s
do-notation: failure     89.917k (± 6.9%) i/s -    454.818k in   5.086821s
  transaction: happy     21.047k (± 2.1%) i/s -    106.284k in   5.052038s
transaction: failure     21.047k (± 1.5%) i/s -    106.233k in   5.048585s

Comparison:
  do-notation: happy:   108310.5 i/s
do-notation: failure:    89917.5 i/s - 1.20x  slower
  transaction: happy:    21047.4 i/s - 5.15x  slower
transaction: failure:    21047.1 i/s - 5.15x  slower
```

So what do we see _here_:

* Happy path is not that much faster than not-so-happy path

  That's because happy path still has to evaluate the remaining steps. It takes time.

* dry-transaction still shows similar performance for both outcomes
* dry-transaction is five times slower than do notation

## Conclusion

* Railway Oriented Programming is a way to gracefully handle errors in your
  application
* You can use dry-monads and dry-transactions to build railway-oriented services
* Functions can return either `Success` or `Failure`, which form the `Result` monad
* Do notation is **way** faster and more flexible than dry-transaction
* This approach is framework-agnostic: works with Rails, Hanami, Sinatra, dry-web-roda
* Include `Dry::Monads::Do.for(:call)` to be able to `yield Result` from your `#call` method

Also, dry-monads lack documentation, so if you decide to give it a try, you are very welcome to contribute!

## Links

* [dry-transaction](https://dry-rb.org/gems/dry-transaction)
* [dry-monads](https://dry-rb.org/gems/dry-monads)
* [Railway Oriented Programming in Elixir](http://zohaib.me/railway-programming-pattern-in-elixir/)
* [Slides on ROP](https://fsharpforfunandprofit.com/rop/) at F# for fun and profit
* [Article on ROP](https://fsharpforfunandprofit.com/posts/recipe-part2/) at F# for fun and profit
* [🇷🇺 Anton Davydov on DO notation ](https://medium.com/pepegramming/do-notation-1e0840a6dbe0)
