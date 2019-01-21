---
layout: single
title: "Partial application in Ruby"
date: "2019-01-12 00:00:15 +0300"
---

Ruby is a multi-paradigm language with a strong bias towards object-oriented programming. You can argue that its design is influenced by Alan Kay and Smalltalk, as opposed to C++/Java-style object-oriented languages. Thankfully, this object-oriented design doesn't mean we can't use ideas from functional programming. There's a small list of functional traits in Ruby:

- Expression-oriented syntax
- Geeky names for `Enumerable` methods: `filter`, `map`, `reduce`, `flat_map`
- Idiomatic [monads](https://dry-rb.org/gems/dry-monads)
- [Railway oriented programming](/2018/05/27/do-notation-ruby.html)
- lambdas and procs
- … I can go on and on

There's also one specific empowering feature: built-in support for partial application. In this article, I want to talk about implementation and use-cases for partial application in Ruby.

<!-- excerpt -->

# Proxy methods

Let's say we have a function of two arguments. As an example, we'll take a function that accepts two strings: _tag_ and _text_ and formats them to look like **[tag] text**. The source code for this function would be fairly simple:

```ruby
def tagged_string(tag, str)
  "[#{tag}] #{str}"
end

tagged_string('INFO', 'Hello, World!')
# => '[INFO] Hello, World!'
```

Let's say we build a logger that only uses 3 tags: _INFO_, _WARNING_, and _ERROR_; and implements only one method, which logs to stdout.

```ruby
class Log
  def write(tag, string)
    print(tagged_string(tag, string))
  end
end
```

So, to use it, we have to always call `Log.new.write('INFO', 'log data')`, which is not convenient. Besides, what happens if we add different log levels? What if we make a typo, or write _DEbUG_ instead of _DEBUG_?

Let's improve the code and write a couple of methods that will help us avoid any mistakes with the tags.

```ruby
class Log
  def info(string)
    write('INFO', string)
  end

  def warning(string)
    write('WARNING', string)
  end

  def error(string)
    write('ERROR', string)
  end
end
```

Now, instead of a single method with two arguments, we have three methods that accept one argument. Those methods are just _proxies_ to the original method as they don't have any extra logic; they just **fix the first argument** of the original method. This technique is called **partial application**.

> Partial application is the process of fixing a number of arguments to a function, producing another function of smaller arity

This Wikipedia definition explains what we've done here:

- We have a function (_write_) that accepts two arguments — which means, its arity is 2
- We defined functions _error_, _warning_, and _info_ that accept only one argument, so their arity is 1
- Those functions only pass their input to write _write_ — we **fixed** the first argument and passed the rest

Whenever we make a function that only calls another one, but requires fewer arguments, we can talk about partial application. In practice, we use it to reduce boilerplate, encapsulate logic, and make our lives easier. I bet you've used it countless times already, but probably never considered that this “pattern“ might have a name.

# Without methods

What if we don't want to extend our class, but still want to use partial application? Our only solution is procs. Personally, I prefer to use lambdas for the task. Let's see how they work.

We have a _Log_ with a simple public interface: _write(tag, string)_. I'm building a system which requires its own tag: _SECURITY_, but I will only need to use it in one class.

In this case, I would do something like this:

1. Instantiate the `Log` and save the object into a variable
2. Define a lambda that uses the object and calls `#write` on it
3. Use the lambda whenever I want to log something

This is how it looks in a class:

```ruby
class SecurityService
  attr_reader :log, :logger_instance

  def initialize(logger_instance)
    @logger_instance = logger_instance
    @log = ->(message) { logger_instance.write('SECURITY', message) }
  end

  def call
    log.call('Hello, World!')
  end
end

SecurityService.new(Log.new).call
# => will print "[SECURITY] Hello, World!"

```

We managed not to define any extra methods, but we still had to manually create a lambda. What if we could avoid it? Then the code would be a little bit simpler:

```ruby
@log = logger_instance.write('SECURITY')

log.call('Hello, World!')
```

Unfortunately, Ruby doesn't work this way and we'll just get an exception. However, it gives us a couple of tools to implement what we want.

# Metaprogramming

Let's use Ruby's metaprogramming to write a helper will enable us to pass fewer arguments to our methods. Here's how it would work:

- You pass a function to the helper
- Helper returns a modified function
- If we call the modified function and provide all arguments, it works as usual
- If we provide fewer arguments than required, we get a new function that requires the rest of the arguments

This is how it would look like:

```ruby
enable_partial_application = ... # our helper

fun = -> (x, y) { x + y } # our function

new_fun = enable_partial_application.call(fun)

plus_two = new_fun.call(2) # => new function
plus_two.call(3) # => 5
plus_two.call(10) # => 12

new_fun.call(4, 3) # => 7
```

Sounds cool, right? Let's see how we can implement this in Ruby. I'm going to pollute global namespace and define a method `enable_partial_application` that accepts a function and returns a wrapper function.

```ruby
def enable_partial_application(fun)
  ->(*args) {
    fun.call(args)
  }
end
```

Let's start adding logic piece-by-piece. Here's first piece of logic: "If we provide enough arguments, we call the original function". To do so, we need to know exactly how many arguments the function requires — so we use the built-in method _#arity_, which gives us the number.

```ruby
def enable_partial_application(fun)
  arity = fun.arity

  ->(*passed_args) {
    # I use `<=` instead of `==` because I want Ruby to
    # handle cases when there are too many arguments.
    if arity <= passed_args.count
      fun.call(*passed_args)
    else
      # ???
    end
  }
end
```

Alright, let's handle the case when there are fewer arguments than required. We'll return a new function that remembers our previous input:

```ruby
def enable_partial_application(fun)
  arity = fun.arity

  ->(*passed_args) {
    if arity <= passed_args.count
      fun.call(*passed_args)
    else
      ->(*args) {
        fun.call(*passed_args, *args)
      }
    end
  }
end
```

Okay, now we can test it:

```ruby
fun = ->(x, y) { x + y }
new_fun = enable_partial_application(fun)

plus_two = new_fun.call(2)
plus_two.call(3) # => 5
plus_two.call(10) # => 12

new_fun.call(4, 3) # => 7
```

It works, alright. Let's check out functions with more arguments:

```ruby
fun = ->(x, y, z) { x + y + z }
new_fun = enable_partial_application(fun)

new_fun.call(2, 3).call(3) # => 8

plus_two = new_fun.call(2)
plus_two.call(3, 1) # => 6

plus_two.call(3).call(1) # => ArgumentError

# (wrong number of arguments (given 2, expected 3))

```

The last line fails because we need to make _enable_partial_application_ work recursively. We can fix this by updating two lines:

```ruby
def enable_partial_application(fun)
  arity = fun.arity

  apply = ->(*passed_args) { # <=
    if arity <= passed_args.count
      fun.call(*passed_args)
    else
      ->(*args) {
        apply.call(*passed_args, *args) # <=
      }
    end
  }
end
```

Now it works like a charm — the resulting function keeps calling itself until the user has provided enough arguments.

One last thing though. It doesn't work with functions that take a dynamic number of arguments because `fun.arity` returns a **negative** value. It's a weird [built-in behavior(https://ruby-doc.org/core-2.2.0/Proc.html#method-i-arity) of procs. There's a simple fix:

```ruby
arity = fun.arity

# replace with

arity = fun.arity.positive ? fun.arity : -fun.arity - 1
```

Finally, we've got a working helper that enables partial application for any function in Ruby. The final result:

```ruby
def enable_partial_application(fun)
  arity = fun.arity.positive ? fun.arity : -fun.arity - 1

  apply = ->(*passed_args) { # <=
    if arity <= passed_args.count
      fun.call(*passed_args)
    else
      ->(*args) {
        apply.call(*passed_args, *args) # <=
      }
    end
  }
end
```

# Built-in method

Thankfully, we don't need to build those helpers. Ruby has a built-in method called `#curry`, which works on methods and procs, and does everything I've described above.

```ruby
fun = ->(x, y, z) { x + y + z }
new_fun = fun.curry

new_fun.call(2, 3).call(3) # => 8

plus_two = new_fun.call(2)
plus_two.call(3, 1) # => 6

plus_two.call(3).call(1) # => 6
```

This method takes its name from [currying](https://en.wikipedia.org/wiki/Currying), a process of transforming a single function of N arguments into N functions that only take a single argument. It's a technique to assist partial application in statically typed functional languages like Haskell, OCaml, and F#. It's a topic for a separate article so I won't mention the details.

# Recap

- Partial application helps us fix values and pass fewer arguments
- We use it quite often, even if we don't do it explicitly
- If a function has a variable number of arguments, its arity is negative
- We need a recursive function to build our own partial application
- Ruby comes with partial application out of the box: `Proc#curry` and `Method#curry`
- Currying is less performant than plain methods/procs

Note: if you want to try currying, please keep in mind that it's not a popular pattern in Ruby, so your colleagues might be skeptical about it. However, I urge you to try it out and compare with the conventional partial application.

# References

- [Wikipedia article](https://en.wikipedia.org/wiki/Partial_application) on partial application
- [Partial function application for humans](http://andrewberls.com/blog/post/partial-function-application-for-humans) by Andrew Berls
- [Hidden partial application in Ruby](https://medium.com/@tmikeschu/hidden-partial-application-in-ruby-183095540c0e)
- [Docs for Proc](https://ruby-doc.org/core-2.2.0/Proc.html)
