---
layout: single
title: "Useful result objects"
date: "2019-11-16 17:52:00+0300"
header:
  og_image: "/assets/images/previews/result-objects.png"
toc: true
---

Result objects is a popular pattern in the Ruby community. We use them one way or another:

* [Interactor](https://github.com/collectiveidea/interactor) uses `context` as a form of result object
* [dry-transaction](https://dry-rb.org/gems/dry-transaction/0.13/) and [dry-monads](https://dry-rb.org/gems/dry-monads/1.0/) use Result (Either) monad as a result object
* We store the result in the service/use case/interactor's instance attributes
* We build our own result objects in our projects

In this article, I would try and explain what is a result object, why do we use them and how to make them as useful as possible. We will walk through the design and implementation of our own result object using plain Ruby. As a bonus, we will supercharge it using `yield` and Ruby 2.7's [pattern matching](https://medium.com/cedarcode/ruby-pattern-matching-1e84cab3b44a). 

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

## Why result objects

Before digging in and explaining the solution, let's stop for a moment and see what exactly we are trying to solve.

**Hint**: if you're familiar with the concept of [railway oriented programming](/2018/05/27/do-notation-ruby.html), you may skip this section
{: .notice--info }

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

Now, we've listed all natural errors, let's code them. I prefer to separate domain-specific errors from other errors, so I can just `rescue` any of those errors. So we need an empty base class for that

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

Now we can use it in our code. Let's say we want to write a helpful error to the console.


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

Let's add some complexity and actually introduce the other parts – creating profile and salary account. Our requirements say that if we can't create a profile or an account, we need to rollback. 

Let's say that we already have the two services:

* `MyApp::Services::CreateProfile`, which only has one public method: `#call` which accepts a `Candidate`
* `MyApp::Services::CreateSalaryAccount`, with the same interface 

Now, our service will look like this:


```ruby
module MyApp
  module Services
    class HireCandidate
      attr_accessor :create_profile, :create_salary_account, :candidate_repo

      def initialize(create_profile:, create_salary_account:, candidate_repo:) 
        @create_profile = create_profile
        @create_salary_account = create_salary_account
        @candidate_repo = candidate_repo
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


So far so good. 


We use result objects to represent the result of a computation.

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

# Recap

# Links and references


* [Ruby pigeon article on errors without exceptions](https://www.rubypigeon.com/posts/result-objects-errors-without-exceptions/)

