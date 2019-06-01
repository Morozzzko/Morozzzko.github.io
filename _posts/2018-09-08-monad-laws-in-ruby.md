---
layout: single
title: "Monad laws in Ruby"
date: "2018-09-08 13:00:00 +0300"
header:
  og_image: "/assets/images/previews/monad_laws.png"
---

I've been using monads in Ruby since May 2016, but I haven't really understood the theoretical basis for them. I thought about learning Haskell, but I gave up pretty soon: I didn't think I would benefit from it. Moreover, we started using ReasonML in Planado, which improved my functional programming skills to the point I didn't really need a new functional language in my life. Why bother with learning Haskell when you know Ruby and Reason, right?

In early 2018, I became curious about theoretical aspects of functional programming, especially the monad laws. That's when I realized that I _really_ needed Haskell, mainly because everyone used it in their articles. It was extremely annoying because I couldn't even read the code. How was I going to apply those things in Ruby if I can't even understand what they're saying? So I got a little help.

I grabbed my laptop and a friend who knows Haskell and figured out how to describe the three monad laws using Ruby's [dry-monads](https://dry-rb.org/gems/dry-monads/1.0/) gem.

<!-- excerpt -->

## Monads

Monad is a concept from category theory. Some people describe it as a “monoid in the category of endofunctors”, some call it “computation context”, and some just call them “result objects”. I believe that each of those definitions is correct to some extent. However, neither of them explain the practical side of monads.

As of September 2018, dry-monads gem contains 5 monads:

- `Maybe` — for nil-safe computations
- `Result` – for expressing errors using types and result objects
- `Try` – to describe computations which may result in an exception
- `List` – for idiomatic typed lists
- `Task` – for asynchronous operations

I guess that `Result` is the most popular monad in Ruby, especially since railway-oriented programming has become such a hot topic in Ruby. So I will use it to describe what's going on.

## Result

Result, also known as Either, is a monad helpful for building computations that might fail at some point. It is one of the most important parts of railway-oriented programming. Result has two constructors: `Failure(a)` and `Success(b)`. Both of those constructors encapsulate a value of type `a` or `b`.

Result has a lot of useful methods, but there's one that's the most important: `#bind` – an essential part of monads. It lets us compose computations by applying a block to a value inside the `Success`.

```ruby
require 'dry/monads/result'
extend Dry::Monads::Result::Mixin

def foo(x)
  Success(x).bind do |value|
    Success(value ** 2)
  end.bind do |value|
    if value > 50
      Failure(:number_too_large)
    else
      Success(value)
    end
  end
end

foo(5)
# => Success(25)

foo(10)
# => Failure(:number_too_large)
```

A couple of things to keep in mind when working with `#bind`:

- `Failure#bind` doesn't do anything – it's a no-op. Use `Failure#or` as an alternative.
- The block _must_ return a `Result`. Technically, it can return any value – a number, a string, a `Maybe` monad – but your code will break if you fail to follow the rule.

## Three axioms

Practically, a monad is a data type which obeys three axioms called ”monad laws”:

- Left identity: `return a >>= f ≡ f a`
- Right identity `m >>= return ≡ m`
- Associativity: `(m >>= f) >>= g ≡ m >>= ( \x -> f x >>= g)`

Those things sound pretty basic when you know Haskell and category theory, but might get extremely complicated if you don't.

The first problem I've had with those laws: I couldn't even read them because I didn't know haskell. Here's a cheatsheet that helped me read and understand the formulae:

- `≡` means that expressions are the same
- `return` is a default constructor. For `Result`, `return` is the `#Success` method
- `>>=` is a bind operator. In Ruby, it's a method `#bind`.
- `\x -> ...` is an anonymous function. Read `-> (x) { ... }`
- `f` is a function that accepts a value and returns `Result`
- `m` is a value of type `Result`

## Left identity

Left identity is an axiom which states that `return a >>= f` is identical to `f a`.

To see what that means, let's say we have a function `f`:

```ruby
f = -> (x) { Success(x ** 2) }
```

There are two ways to call use the function:

- Call it using plain Ruby
- Wrap an argument into a monad and pass the function to `#bind`

The law says that those are equal:

```ruby
Success(5).bind(&f) # => Success(25)
f.(5) # => Success(25)
```

Voilà! That's it. Putting the value in the default context (`Success`) and feeding it to a function is the same as applying the function to the value.

What it means:

- there's nothing special about `#bind` – it's just a fancy method call
- if you need to use a monadic function, you don't need to wrap the argument into a monad

## Right identity

Right identity states that `m >>= return` is the same as `m`.

That means that if we have a `Result` object and try to bind it to a `#Success`, the operation won't change anything.

```ruby
Success(2).bind(&method(:Success))
# => Success(2)

Success(2).bind(&Dry::Monads::Success)
# => Success(2)

Failure(2).bind(&method(:Success))
# => Failure(2)
```

I haven't figured out the practical value of this yet. If you have any ideas, send me an email at [igor@morozov.is](mailto:igor@morozov.is).

## Associativity

The fanciest of the three, associativity axiom states that `(m >>= f) >>= g` and `m >>= ( \x -> f x >>= g)` are the same.

The trickiest part for me was `\x -> f x >>= g`, which turned out to be an anonymous function which accepts `x` and has a body `f x >>= g`.

This is how the Ruby equivalent of the law would look like:

```ruby
# prerequisites

m = Success(2)

f = -> (x) { Success(x ** 2) }
g = -> (x) { x < 50 ? Success(x) : Failure(:number_too_large) }

# (m >>= f) >>= g

(m.bind(&f)).bind(&g)
# => Success(4)

# m >>= ( \x -> f x >>= g)

m.bind do |x|
  f.(x).bind(&g)
end # => Success(4)
```

To put it the other way: if you have a chain of computations, it doesn't matter how you nest them – the result would always stay the same.

## Recap

A monad is a powerful construct from category theory which can be used as mathematically sound result objects. In Ruby, [dry-monads](https://dry-rb.org/gems/dry-monads/1.0/) is the de-facto standard gem, which gives us the `Result` (`Either`), `Maybe`, `Task`, `Try` and `List` monads.

To be called a monad, the data type must conform to three axioms called “monad laws”:

> **Left identity**: wrapping a value into a monad and binding it to a function is the same as applying the function to the value.

> **Right identity**: feeding a monadic value to a default constructor doesn't do anything.

> **Associativity**: you can nest your computations and binds however you like.

While those laws have little to no practical value for a casual user, reading about the principles behind it all might help you join the world of functional programming and category theory. Definitely helps me!

Cheers!

## References

- [Best resource on Railway Oriented Programming](https://fsharpforfunandprofit.com/rop/)
- [Lambdacast: good podcast for FP beginners](https://lambdacast.com)
- [Miklós Martin on monad Laws](https://miklos-martin.github.io/learn/fp/2016/03/10/monad-laws-for-regular-developers.html)
- [A fistful of monads](http://learnyouahaskell.com/a-fistful-of-monads#monad-laws)
- [Haskell wiki](https://wiki.haskell.org/Monad_laws)
- [dry-monads](https://dry-rb.org/gems/dry-monads/1.0/)
- [Trailblazer operations](http://trailblazer.to/gems/operation/2.0/)
- [dry-transaction](https://github.com/dry-rb/dry-transaction)
