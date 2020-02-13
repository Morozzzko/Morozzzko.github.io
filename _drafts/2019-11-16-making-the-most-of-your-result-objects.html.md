---
layout: single
title: "Useful result objects"
date: "2019-11-16 17:52:00+0300"
header:
  og_image: "/assets/images/previews/result-objects.png"
toc: true
---

Result objects is a popular pattern in the Ruby community. We use them one way or another:

* [Interactor](https://github.com/collectiveidea/interactor) and [ActiveInteractor](https://github.com/aaronmallen/activeinteractor) use `context` as a form of result object
* [dry-transaction](https://dry-rb.org/gems/dry-transaction/0.13/) and [dry-monads](https://dry-rb.org/gems/dry-monads/1.0/) use Result (Either) monad as a result object
* We store the result in the service/use case/interactor's instance attributes
* We build our own result objects for our projects

In this article, I will try and explain what a result object is, why do we use them and how to make them as useful as possible. We will walk through the design and implementation of our own result object using plain Ruby. As a bonus, we will supercharge it using `yield` and Ruby 2.7's [pattern matching](https://medium.com/cedarcode/ruby-pattern-matching-1e84cab3b44a). 

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

As you see, there's a lot of different approaches to result objects. I managed to extract those definitions into four groups:

1. A container that stores data and provides a way to check if the computation was a success or not
2. A structure with named fields – a nicer replacement for hash
3. Mathematical definitions:
  a) A composable and chainable type
  b) A type that has two constructors, each accepting one argument

In this post, we're going to focus on a result object that conforms to three of those groups: 1, 3a and 3b. We will see what's behind them in theory and practice.

## Life without result objects

Before digging in and explaining the solution, let's stop for a moment and see what exactly we are trying to solve.

**Hint**: if you're familiar with the concept of [railway oriented programming](/2018/05/27/do-notation-ruby.html), you may skip this section
{: .notice--info }

### Thinking about errors

Let's consider a use-case. Let's say we are building a human resource management application for a cleaning service. Let's say we want to hire a candidate, then our code has to:

1. Mark the candidate's account as "approved"
2. Create a new profile for "cleaner"
3. Give the new account access for all necessary functions
4. Create an account for salaries
5. Send a text message with an app link

The thing about this business process – if any of the first four steps fail, we need to cancel everything and raise an error. The fifth step may fail – in this case, wel'll alert the operator and they'll handle it.

Conventionally, we would achieve it using exceptions. Here's a short table that explains a list of expected outcomes:

| Exception class | What happens |
| -- | -- |
| `CandidateDoesNotExist` | We're trying to approve a candidate that doesn't exist in the system |
| `CandidateAlreadyHired` | The candidate is already hired |
| `CandidateRejected` | The candidate was previously rejected, so we can't hire them |
| `InsufficientData` | We don't have enough info about the candidate to hire them: probably a profile picture is missing |
| `ProfileExists` | Cleaner profile already exists for this candidate. It may happen during race conditions |
| `SalaryAccountExists` | Salary account already exists for this candidate. Possible race condition |
| `TextMessagesUnavailable` | We can't send a text message to the phone number |

As you can see, some of those errors are domain-related, and some are purely technical – like `ProfileExists`, `SalaryAccountExists` and `TextMessageUnavailable`. The idea here is to list every error that we expect to occur regularly. SEGFAULT, HTTP timeouts, IO errors and similar errors are good, but we *don't want* to think about them all the time. 

<div class="notice--info">
  <!-- TODO: make it a header -->
  <strong>Factors that tell you "This error is worth your attention"</strong>

  <ol>
    <li>You want to recover from it: retry, use different source of data, notify the user, or just ignore the step</li>
    <li>It is a part of your business process</li>
  </ol>
</div>

Now, we've listed all natural errors, let's code them. 


### Defining our errors

I prefer to separate domain-specific errors from other errors, so I can just `rescue` any of those errors. So we need an empty base class for that

```ruby
# lib/my_app/errors.rb

module MyApp
  module Errors
    class DomainError < StandardError; end
  end
end
```

Now we need to write all the exceptions. We're not doing anything fancy, so let's put it in the same file with `DomainError`

```ruby
# lib/my_app/errors.rb

module MyApp
  module Errors
    class DomainError < StandardError; end

    class CandidateDoesNotExist < DomainError; end
    class CandidateAlreadyHired < DomainError; end 
    class CandidateRejected < DomainError; end
    class InsufficientData < DomainError; end
    class ProfileExists < DomainError; end
    class SalaryAccountExists < DomainError; end
    class TextMessagesUnavailable < DomainError; end
  end
end
```

So far so good. Now we can use them in our services.

### Getting started with our error

To show what I'm talking about, I'll write a service that hires the candidate. Let's assume that the service only has one method `#call` which accepts the candidate's ID.

```ruby

# lib/my_app/services/hire_candidate.rb

module MyApp
  module Services
    class HireCandidate
      attr_accessor :candidate_repo

      def initialize(candidate_repo:) 
        @candidate_repo = candidate_repo
      end

      def call(candidate_id)
        candidate = fetch_candidate(candidate_id)

        raise Errors::CandidateAlreadyHired if candidate.hired?
        raise Errors::CandidateRejected if candidate.rejected?
        raise Errors::InsufficientData if candidate.profile_picture.nil? || candidate.name.empty?

        candidate.update!(hired_at: Time.now)

        candidate
      end

      private

      def fetch_candidate(candidate_id)
        candidate_repo.find(candidate_id)
      rescue RecordNotFound
        raise Errors::CandidateDoesNotExist
      end
    end
  end
end
```

So far, we've got a service that finds the candidate in our database, checks for constraints and raises helpful exceptions if we can't do something.

If you're not familiar with dependency injection and why we're writing our constructors like that, please read [Solnic's article on dependency injection](https://solnic.codes/2013/12/17/the-world-needs-another-post-about-dependency-injection-in-ruby/)
{: .notice--info }

Now we can use it in our code. Let's say we want to print a helpful message to the console. Here's the code that will make it happen:


```ruby

module MyApp
  hire_candidate = Services::HireCandidate.new

  begin
    hire_candidate.call(1)
  rescue Errors::CandidateAlreadyHired, Errors::CandidateRejected
    puts "Sorry, already worked with them, refresh your app"
  rescue Errors::InsufficientData
    puts "Welp, not enough data. Check for profile picture and name"
  end
end
```

### Going down the rabbit hole

Let's add some complexity and actually introduce the other parts – creating profile, salary account and sending a notification. Our requirements say that if we can't create a profile or an account, we need to rollback, but we may ignore if we can't send the notification.

Let's say that we've already implemented three other services:

* `MyApp::Services::CreateProfile`, which only has one public method: `#call` which accepts a `Candidate`
* `MyApp::Services::CreateSalaryAccount`, with the same interface 
* `MyApp::Services::SendNotification`

Now, our service for hiring a candidate will look like this:


```ruby
module MyApp
  module Services
    class HireCandidate
      attr_accessor :create_profile, :create_salary_account, :send_notification, :candidate_repo, :logger

      def initialize(create_profile:, create_salary_account:, send_notification:, candidate_repo:, :logger) 
        @create_profile = create_profile
        @create_salary_account = create_salary_account
        @send_notification = send_notification
        @candidate_repo = candidate_repo
        @logger = logger
      end

      def call(candidate_id)
        candidate = fetch_candidate(candidate_id)

        raise Errors::CandidateAlreadyHired if candidate.hired?
        raise Errors::CandidateRejected if candidate.rejected?
        raise Errors::InsufficientData if candidate.profile_picture.nil? || candidate.name.empty?

        candidate_repo.transaction do
          candidate.update!(hired_at: Time.now)

          create_profile.call(candidate)
          create_salary_account.call(candidate)
        end

        begin
          send_notification.call(candidate)
        rescue Errors::TextMessagesUnavailable
          logger.warn('Text messages unavailable')
        end

        candidate
      end

      private 

      def fetch_candidate(candidate_id)
        candidate_repo.find(candidate_id)
      rescue RecordNotFound
        raise Errors::CandidateDoesNotExist
      end
    end
  end
end
```

Let's see what we get from this code, reading from top to bottom:

1. We have a service that hires a candidate
2. If we want to hire a candidate, we need to know how to:
  a) fetch candidate info from database
  b) create a profile
  c) create a salary account
  d) send a message
  e) log an error
3. We take a candidate's ID and fetch the info from the database
4. We check for multiple conditions and raise an error if something goes wrong
5. We write down the exact time when the candidate was hired
6. We create a profile
7. We create salary account
8. We try to send a notification and write to a log if we've failed
9. We return the object with the candidate's info


So far so good. Let's see how we can handle it in our app:


```ruby
module MyApp
  hire_candidate = Services::HireCandidate.new(
    create_profile: MyApp::Services::CreateProfile.new,
    create_salary_account: MyApp::Services::CreateSalaryAccount.new,
    send_notification: MyApp::Services::SendNotification.new,
    logger: Logger,
    candidate_repo: MyApp::Repositories::CandidateRepo.new
  )

  begin
    hire_candidate.call(1)
  rescue Errors::CandidateAlreadyHired, Errors::CandidateRejected
    puts "Sorry, already worked with them, refresh your app"
  rescue Errors::InsufficientData
    puts "Welp, not enough data. Check for profile picture and name"
  rescue Errors::ProfileExists 
    puts "Couldn't create profile, please refresh" 
  rescue Errors::SalaryAccountExists 
    puts "Couldn't create salary account, please refresh"
  end
end
```

It sounds trivial enough, but let's see how the handling will look like in a more realistic situation. Let's say we have a web application with a controller. We're writing an API, so we need to return a JSON with a meaningful status and a message. 

See how it might look like:

```ruby

module MyApp
  module WebAPI
    class CandidateController
      def hire
        candidate = hire_candidate.call(params[:candidate_id])

        render json: { candidate_id: candidate.id }
      rescue Errors::CandidateDoesNotExist
        render status: :unprocessable_entity, 
               json: { error_code: "does_not_exiss", message: "sorry but this candidate does not exist" }
      rescue Errors::CandidateAlreadyHired
        render status: :unprocessable_entity, 
               json: { error_code: "candidate_already_hired", message: "sorry but we've already hired this candidate" }
      rescue Errors::CandidateRejected
        render status: :unprocessable_entity, 
               json: { error_code: "candidate_rejected", message: "Sorry but the candidate is already rejected" }
      rescue Errors::InsufficientData
        render status: :unprocessable_entity, 
               json: { error_code: "insufficient_data", message: "You need to fill all necessary info" }
      rescue Errors::ProfileExists 
        render status: :unprocessable_entity, 
               json: { error_code: "profile_exists", message: "Couldn't create profile, please refresh" }
      rescue Errors::SalaryAccountExists 
        render status: :unprocessable_entity, 
               json: { error_code: "salary_account_exists", message: "Couldn't create salary account, please refresh" }
      end

      private

      def hire_candidate
        MyApp::Services::HireCandidate.new(
          create_profile: MyApp::Services::CreateProfile.new,
          create_salary_account: MyApp::Services::CreateSalaryAccount.new,
          send_notification: MyApp::Services::SendNotification.new,
          logger: Logger,
          candidate_repo: MyApp::Repositories::CandidateRepo.new
        )
      end
    end
  end
end
```

Looks clumsy, but it is what it is. We can handle some repetitive errors using Rails' `rescue_from` DSL, but it won't help much – sometimes we get to handle even more complex payloads for extremely difficult processes. That's the trick – we need to figure out a way to make our code easy to change and maintain.

The question is, what is the problem here? It looks like a regular Ruby code. Sure, it may look new to some folks – everyone treats their errors differently – but do we really need to change anything here? We need to look deeper.

## Failures of exceptional design

### Failure to tell us about new outcomes

When we design our systems, we try to consider all possible outcomes and design our code around them.

If we use exceptions, we can easily handle different kinds of failures – we just need to write some `rescue` blocks and we're good.

However, we can can never be sure that we've covered all possible outcomes. 

That might seem okay: the world is huge, it's ever-changing and so is our software, yada yada. That's not what I'm talking about, though.

In [thinking about errors](#thinking-about-errors) we've listed 7 errors that may exist in our system. In [going down the rabbit hole](#going-down-the-rabbit-hole) we've written code that handles all of those errors. Let's work with that example

Let's keep in mind that in a real-world application, we'll probably have multiple entry points for the same code, and error handling will be different in all of those places:

* We'll have an API
* We might have another API, webhooks or websockets
* What about `/admin`? We need might need this too

Now, here's the question: what happens when we extend our logic? It's natural to add new errors when we do, but how do we deal with it?

Naturally, we would create a new exception class, `raise` it whenever we need, and add a new `rescue` clause everywhere. 

Here's the trick: _no static analysis tool_ can tell us that we forgot to cover an exception. It's virtually impossible for two reasons: inheritance and dynamic type system.

To be fair, the same problem may exist in Java too – but only if you're lazy enough. You see, in Java you _have to_ list all exceptions in the function signature. It looks like this:

```java
public Candidate hireCandidate(ID candidateId)
  throws CandidateDoesNotExist, CandidateAlreadyHired, 
  InsufficientData, ProfileExists, 
  SalaryAccountExists, TextMessagesUnavailable { 
  ... // our code here
}
```

Clumsy, right? Usually I'd be lazy and just list the superclass like this:

```java
public Candidate hireCandidate(ID candidateId) 
  throws DomainError { 
  ... // our code here
}
```


The difference between those two options is not so obvious, but it is quite important:

When we list all possible exceptions, the compiler or linter can check if we've covered them all – we call it an _exhaustiveness check_. We can't do that if we're using a superclass because we can always inherit it and the checks will become false-positive.

Sure, there's a workaround: you can `rescue` all _concrete_ exception classes and then try to `rescue` their superclass.


```ruby
rescue MyApp::Errors::CandidateDoesNotExist
  ..
rescue MyApp::Errors:...
  .. more rescues
rescue MyApp::Errors::DomainError
 ... # this code should never execute
end
```

This trick will give us a _comprehensive_ coverage for the exceptions, but it has multiple downsides:

1. The code never runs, so we have to work around our test coverage
2. The logic becomes harder to understand, as we need to explain why we have a branch of code that _should never execute_
3. We need to decide what to do if the never-meant-to-be-executed branch executes. Log an error? Raise another exception? Call 911? 

Since Ruby is a dynamically typed language, lack of such guarantee is a trade-off we can live with – we'll write some tests and go on with our lives. Yet, it's important to be aware of it.

### Failure to compose

### Failure to provide a decent debugging experience

Here's the known issue about exceptions – they mess up the control flow. 

### Failure to perform well

Due to the nature of exceptions, they significantly slow down our code.

### Failure to be predictive

Nikita, mathematics, mapping and shit

## Running away from the problems

I have to admit that I get extremely frustrated with exceptions. Whenever I try to use them, the code gets more complex and harder to reason about. I've tried reading books and using other programming languages – that didn't help much.

Result objects feel like a remedy – they help me structure, read and debug the code. It's not _the solution_, but an alternative approach to tackle the same problems. 

Let's move on to the alternative approach to designing the application logic's flow.

## Using data to solve our problems

Let's take a step back and see how different languages approach error handling and handling special cases without exceptions.

Operating systems use [exit status](https://en.wikipedia.org/wiki/Exit_status) to tell you if the program has exited successfully. Usually, if the exit status is not zero, there was a problem. In this case, you can usually check logs, [stdout](https://en.wikipedia.org/wiki/Standard_streams#Standard_output_(stdout)) or [stderr](https://en.wikipedia.org/wiki/Standard_streams#Standard_error_(stderr)) to see what went wrong. 

If you look at standard C functions, you can see that they return statuses too. One of my favorites is [strcmp](https://en.cppreference.com/w/c/string/byte/strcmp), which returns `0` if two strings are identical. If the strings are not identical, the _sign_ of the result will tell you which string appears first in lexicographical order.

<!-- TODO: rewrite C to use errno instead. See https://www.studytonight.com/c/error-handling-in-c.php -->

Whenever we look at [code in Go](https://blog.golang.org/error-handling-and-go), we can see that the common approach is to return _multiple values_ from a function. The last value contains the error or `nil` if everything's okay.

[Elixir developers](https://medium.com/@moxicon/elixir-best-practices-for-error-values-50dc015a06f5) return `{:ok, value}` and `{:error, error_metadata}` tuples and use [pattern matching](https://elixir-lang.org/getting-started/pattern-matching.html) to handle the result. Lisp developers use this pattern too.

If we look at Rust, the most common pattern is the [Result type](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html), which is a enum of two variants: `Ok(result)` for successful execution and `Err(error_metadata)` for unsuccessful one. You can find similar patterns in Haskell, Kotlin, OCaml, Scala and F#.

If you look at those examples, you can see that they share a common trait – they use pure data to tell if everything's okay. It takes different forms and shapes: some systems use return codes, others return multiple values, while the most sophisticated ones use the _result type_. 

Let's see how we can apply those patterns in Ruby.

## Working with tuples

When we talk about returning multiple values, we actually meat returning [a tuple](https://en.wikipedia.org/wiki/Tuple) – an ordered list with some values. 

Ruby has a nice support for this approach – let's see how we can write the `swap` functions that takes two values and reverses them:

```ruby
def swap(a, b)
  [b, a]
end

a = 1
b = 3

# We've got nice destructurization, why don't we use it
a, b = swap(a, b)

puts a # 3
puts b # 1
```

This is an effective approach, and we can even see it in [Rack](https://github.com/rack/rack) – the webserver interface. All applications and middlewares return a tuple of three elements – or a 3-tuple:

1. The HTTP return code
2. A map of HTTP headers
3. The response body

However, we don't use plain Rack so often, so why don't we look at how we may apply this pattern in our applications.

It may be helpful to think about tuples as structs, but without named fields – you have to remember the position for each field. It actually works nice when you design your domain, as it enables you to create zero-cost abstractions. Just some examples:

* You can use 2-tuple to express currency:  `[200, :eur]`, `[0.4, :rub]`
* Velocity is a nice 3-tuple: `[10, :km, :h]`, `[300, :mile, :day]`
* Playing cards work nicely as 2-tuples: `[:ace, :spades]`, `[7, :hearts]`

You can see that it would be a bit cumbersome to use explicit field names in some circumstances. It's pure data with no logic, so it's reasonable to drop the field names altogether.

Since errors do not really contain any logic, we can design them too. There are many ways to do it, but I would recommend following those guidelines:

1. Use the first element to identify the _type_ of the result. You'll need to tell apart different kinds of success and failures, and the first element is perfect for it. 
2. Use symbols to identify the type: `:success`, `:failure`, `:user_not_found`, and so on.
3. Store metadata as other fields of the tuple. 
4. Add as many fields as you like, but stay reasonable. A 4-tuple _might_ be too large, but a 10-tuple definitely needs refactoring.
5. If you need to have a different number of fields for different cases, use different types. Make sure tuple size stays the same for each type. 
6. Use ubiquitous language across your code. Don't mix `:success`, `:ok` and `:good` together – pick one.

If we apply this pattern to errors we talked about in [going down the rabbit hole](#going-down-the-rabbit-hole), we'll get a result like this

```ruby
module MyApp
  module WebAPI
    class CandidateController
      def hire
        result, *_meta = hire_candidate.call(params[:candidate_id])

        case result
        when :success
          render json: { candidate_id: candidate.id }
        when :candidate_does_not_exist
          render status: :unprocessable_entity, 
                 json: { error_code: "does_not_exiss", message: "sorry but this candidate does not exist" }
        when :candidate_already_hired
          render status: :unprocessable_entity, 
                 json: { error_code: "candidate_already_hired", message: "sorry but we've already hired this candidate" }
        when :candidate_rejected
          render status: :unprocessable_entity, 
                 json: { error_code: "candidate_rejected", message: "Sorry but the candidate is already rejected" }
        when :insufficient_data
          render status: :unprocessable_entity, 
                 json: { error_code: "insufficient_data", message: "You need to fill all necessary info" }
        when :profile_exists 
          render status: :unprocessable_entity, 
                 json: { error_code: "profile_exists", message: "Couldn't create profile, please refresh" }
        when :salary_account_exists 
          render status: :unprocessable_entity, 
                 json: { error_code: "salary_account_exists", message: "Couldn't create salary account, please refresh" }
        end
      end

      private

      ...
    end
  end
end
```

It looks similar to the exception implementation, but it's actually a bit different:

1. We don't need to create any classes – we just use symbols
2. We can now _see_ duplicate code: `error_code` in JSON is equal to the `result` type. We can simplify the code further
3. Only the message is different at this point. This looks like a great chance to refactor

To be fair, we could have done most of the refactoring with exceptions, too. It's just easier to follow and comprehend for me. Your mileage may vary.

There's a problem – if we add another type of error, the application won't tell us, as it will behave unexpectedly instead of crashing. I'll explain the solution in further sections. If you don't want to wait, feel free to skip to [TBA TBD](#).

## Using wrapper classes

Tuples may be a good solution especially for the Elixir folks, but they lack some elegance. For instance, I can't use `result.success?` to figure out if the execution was successful – I have to always destructurize. It's not so bad, but not so ergonomic either.

So let's try and design a wrapper that will solve our problems and make the error-handling approach more idiomatic.

First, we'll need to figure out what we need:

1. We're making a `Result` type
2. It has two different outcomes: a `Success` and a `Failure`
3. Both have `success?` and `failure?` methods
4. It's just a container for some value

So, it will look like this:

```ruby
class Result
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def success?
    false
  end

  def failure?
    false
  end
end

class Success < Result
  def success?
    true
  end
end

class Failure < Result
  def failure?
    true
  end
end
```

Let's see how we would use it:

```ruby
Success.new(candidate).success?
Failure.new([:candidate_does_not_exist, candidate_name])

result = some_function.call # returns a Success or a Failure

if result.success?
  do_something
else
  do_something_else
end
```





## Legacy

-----

We use result objects to represent the result of a computation.

Conventionally, Ruby has exceptions for this – you raise an exception if there's an error. You'd to catch it and voilà – here's your result, do whatever you want.

1. Errors become first-class residents of your application
2. It becomes easier to figure out all possible outcomes
3. The code becomes simpler, easier to write and a little more performant
4. Complex logic becomes easier to read, compose and desin

For what it's worth, the ideological ones are about pragmatism too. Let's talk about them a little.



## Life with result objects

### Errors become first-class residents of your application


### It becomes easier to figure out all possible outcomes


### The code becomes simpler, easier to write and a little more performant


### Complex logic becomes easier to read, compose and design

# Recap

# Links and references


* [Ruby pigeon article on errors without exceptions](https://www.rubypigeon.com/posts/result-objects-errors-without-exceptions/)

