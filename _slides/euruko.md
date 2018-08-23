---
layout: slides
title: "Ducks and Monads: Wonders of Ruby types"
description: EuRuKo 2018
theme: white
highlightjs_theme: atom-one-light # github
transition: none
---

<script>
document.addEventListener(
  "DOMContentLoaded",
  () => Reveal.configure({ slideNumber: 'c/t' })
);
</script>

<style>
  h1, h2, h3, h4, h5, h6 {
    text-transform: none !important;
  }

  .reveal div.slide-number {
    background: none;
    color: black;
  }

  .reveal pre code.ruby {
    font-size: 1.0em;
    line-height: 1.5em;
    max-height: none;
  }
</style>

<section>
  <h1>Ducks and Monads</h1>
  <h2>Wonders of Ruby Types</h2>
</section>

<section>
  <h2>Hey, I'm Igor</h2>
  <p>/'<span style="font-family: monospace;">iːgɔːɹ</span>/</p>

  <aside class="notes" data-markdown>
    Say something about yourself
  </aside>
</section>

<section>
  <h2>I'm a polyglot programmer at Qlean.ru</h2>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2>I don't trust myself</h2>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2>There are four reasons I don't trust myself</h2>
</section>

<section>
  <h2>
    undefined is not a function
  </h2>

  <aside class="notes" data-markdown>
    Type errors:

    I expect a function, but it's a string
    I expect a string, but it's a number

  </aside>
</section>

<section>
  <h2>
    N&nbsp;+&nbsp;1
  </h2>
  <aside class="notes" data-markdown>
    Used to work with rom, switched to AR

    I'm extra careful, but I still make those mistakes

  </aside>
</section>

<section>
  <h2>
    I mess up business logic
  </h2>

  <aside class="notes" data-markdown>
    Sometimes the domain is so complex that I forget to handle an important case.

    One of the recent examples: forgot to check cleaner's location, assigned a cleaner from Saint Petersburg to an order in Moscow.
    Happily, that happened in staging environment, so the cleaner didn't have to buy a plane ticket.

  </aside>
</section>

<section>
  <h2>
    I forget to close a bracket
  </h2>
</section>

<section>
  <h2>
    I forget some details
  </h2>
</section>

<section>
  <h2>I have to double-check my code</h2>
  <p>
    New hobby: finding the right tools
  </p>

  <aside class="notes" data-markdown>
    I'm a human, so I make a lot of mistakes. I have to use the right tools to fight those errors

    I use:

    * automatic tests
    * linters
    * manual testing
    * code review

    It's also importan to find tools that help you *write* a good code.

  </aside>
</section>

<section>
  <h2>Tools to write type-safe Ruby code</h2>

  <aside class="notes" data-markdown>
    Today I want to talk about Ruby's type system and libraries that help us write better code
    with regard to type safety and expressiveness.

    But first, we need stop and think if we really need to care about types.

  </aside>
</section>

<section>
  <h2>Dynamic typing is not an excuse to be reckless</h2>

  <aside class="notes" data-markdown>
    Actually, yes, we do.

    Ruby has a dynamic type system, but it is not a permission to be reckless about our customer's data.

  </aside>
</section>

<section>
  <h2>2 out of 10 most common errors are about types</h2>

  <aside class="notes" data-markdown>
    According to Rollbar, two out of ten most popular errors in Rails projects are related to types.

    JavaScript: 7 out of 10.

  </aside>
</section>

<section>
  <h2>Silent data corruption: <br />JSON in Rails</h2>
  <pre>
    <code class="ruby" data-trim>
      value = "{\"foo\":\"bar\"}"

      # Rails 4
      my_model.value = value # => { foo: "bar" }

      # Rails 5
      my_model.value = value # => "{\"foo\":\"bar\"}"
    </code>

  </pre>

  <aside class="notes" data-markdown>

  </aside>
</section>

<section>
  <h2>We have to use the right libraries</h2>
</section>

<section>
  <h2>
    Writing code is easier than fixing it
  </h2>
</section>

<section>
  <h2>
    Every object has a type
  </h2>
</section>

<section>
  <h2>What's a type, anyway?</h2>
  <ul>
    <li>Syntactic</li>
    <li>Representation</li>
    <li>Representation and behavior</li>
    <li>Value space</li>
    <li><strong>Value space and behavior</strong></li>
  </ul>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h3>
    <q>
      A type is a set of values which a variable can possess and a set of functions that one can apply to these values.
    </q>
  </h3>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2>
    We learn to consider all possible values
  </h2>
</section>

<section>
  <h2>
    nil does not belong to every type
  </h2>
</section>

<section>
  <h2>
    ActiveSupport teaches us to be reckless
  </h2>
</section>

<section>
  <h2>
    <code>blank?</code> and <code>present?</code><br/>are bad for your code
  </h2>
</section>

<section>
  <h2>
    We have to think about design of our data
  </h2>
</section>

<section>
  <h2>
    Being careful is not enough
  </h2>
</section>

<section>
  <h2><q>dry-types is a simple and extendable type system for Ruby</q></h2>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2>Data constructors</h2>
  <pre>
    <code class="ruby" data-trim>
      Types::Strict::String["foo"] # => "foo"
      Types::Strict::String[nil] # => Dry::Types::ConstraintError:
      # nil violates constraints

      Types::Optional::Strict::String[nil] # => nil
    </code>

  </pre>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2>Complex definitions</h2>
  <pre>
    <code class="ruby" data-trim>
      IntArray = Types::Strict::Array.of(Types::Strict::Integer)

      Enum = Types::Strict::String.enum('foo', 'bar')

      Timestamp = Types::Strict::String | Types::Strict::Time

      MyHash = Types::Strict::Hash.schema(
        foo: Types.Instance(MyClass),
        bar: Types::Strict::Float
      )
    </code>

  </pre>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2>dry-types won't change your architecture</h2>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <img style="border: none; max-width: 400px; max-height: auto" src="/assets/images/slides/euruko/hanami.png" />
  <h2>Trying out dry-types: Hanami</h2>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2>Enhancing your application with dry-types</h2>

  <ul>
    <li>Describe your data using dry-types</li>
    <li>Use those definitions in constructors</li>
    <li>Use them in setters</li>
    <li>(hard) Use dry-struct for domain models</li>
  </ul>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2>Three steps to type safety</h2>

  <ul>
    <li>Stop using ActiveSupport</li>
    <li>Consider all possible values</li>
    <li>Use strict constructors</li>
  </ul>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2>
    Expressing errors with types
  </h2>
</section>

<section>
  <h2>
    Errors are not that exceptional
  </h2>
</section>

<section>
  <h2>
    Types can facilitate error handling
  </h2>
</section>

<section>
  <h1>Monads in Ruby</h1>
</section>

<section>
  <h2>Monads are similar to musical instruments</h2>

  <aside class="notes" data-markdown>
    You can use them, but you can't give them a good definition without being wrong
  </aside>
</section>

<section>
  <h2>
    A monad is a result object with a few rules
  </h2>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2>Result (Either) monad</h2>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2><code class="haskell">type Result a b = Failure a | Success b</code></h2>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2>Using Result</h2>
  <pre>
    <code class="ruby" data-trim>
      require 'dry/monads/result'

      include Dry::Monads::Result

      Success(1).success # => 1
      Success(1).success? # => true

      Failure("abc").failure # => "abc"
      Failure("abc").failure? # => true
    </code>

  </pre>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2>Computations: bind</h2>
  <pre>
    <code class="ruby" data-trim>
      Success(1).bind do |value|
        if value.positive?
          Failure("Welp")
        else
          Success(value + 3)
        end
      end # => Failure("Welp")
    </code>

  </pre>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2>Handling errors: or</h2>
  <pre>
    <code class="ruby" data-trim>
      Failure(:not_found).or do |error|
        case error
        when :not_found
          Failure(:db_error)
        else
          Success("Yay!")
        end
      end # => Failure(:db_error)
    </code>

  </pre>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2>Non-monadic computations: fmap</h2>
  <pre>
    <code class="ruby" data-trim>
      Success(1).fmap do |value|
        "The value is #{value}"
      end # => Success("The value is 1")

      Failure(1).fmap do |value|
        "The value is #{value}"
      end # => Failure(1)
    </code>

  </pre>

  <aside class="notes" data-markdown>
  </aside>
</section>

<!-- <section>
  <h2>Recovering from failure: <br />#or_fmap</h2>
  <pre>
    <code class="ruby" data-trim>
      Failure(:not_found).or_fmap do |error|
        logger.info("Error occured", error)

        repo.default
      end # => Success(...)
    </code>

  </pre>

  <aside class="notes" data-markdown>
  </aside>
</section> -->

<section>
  <h2>Escaping the context: <br />value_or</h2>
  <pre>
    <code class="ruby" data-trim>
      Success(-5).bind do |x|
        if x.positive?
          Success(x)
        else
          Failure("Something went wrong")
        end
      end.value_or { nil } # => nil
    </code>

  </pre>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2>Unwrapping</h2>
  <pre>
    <code class="ruby" data-trim>
      Failure(
        "Something went wrong"
      ).value_or(&:itself) # => "Something went wrong"
    </code>

  </pre>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h2>Do notation</h2>
  <pre>
    <code class="ruby" data-trim>
      class Operation
        include Dry::Monads::Do.for(:call)
        include Dry::Monads::Result

        def call(name)
          user = yield find_by_name(name)

          contract = yield find_contract(user)

          Success(contract.new(
            amount: contract.amount + 100
          ))
        end
      end
    </code>

  </pre>

  <aside class="notes" data-markdown>
  </aside>
</section>

<section>
  <h1>Recap</h1>
</section>

<section>
  <h2>Types help us design our applications</h2>
</section>

<section>
  <h2>ActiveSupport may be bad for our code</h2>
</section>

<section>
  <h2>Use dry-types for a type-safe application design</h2>
</section>

<section>
  <h2>Monads help us handle errors gracefully</h2>
</section>

<section>
  <h2>Useful links and references</h2>
  <ul>
    <li><a href="http://dry-rb.org/gems/dry-types/">
      dry-rb.org
    </a></li>
    <li><a href="https://solnic.codes/2016/11/02/duck-typing-vs-type-safety-in-ruby/">solnic.codes</a></li>
    <li><a href="http://hanamirb.org/">hanamirb.org</a></li>
    <li>
      <a href="https://fsharpforfunandprofit.com/rop/">
        Railway Oriented Programming
      </a>
    </li>
    <li><a href="https://books.google.ru/books/about/Abstract_Types_Defined_as_Classes_of_Var.html?id=gKP1SQAACAAJ&redir_esc=y">Parnas, Weiss and Shore on data types</a></li>
    <li>
      <a href="http://trailblazer.to/gems/operation/2.0/">
        Trailblazer operations
      </a>
    </li>
    <li>
      <a href="https://www.morozov.is/2018/05/27/do-notation-ruby.html">Do notation in Ruby</a>
    </li>
  </ul>
</section>

<section>
  <h1>Thank you! ❤</h1>
  <p>
    I would love to hear from you
    <br />
    igor@morozov.is
  </p>

  <aside class="notes" data-markdown>
  </aside>
</section>

<!-- <section>
  <h2></h2>
  <q>
  </q>
</section>

<section>
  <h2></h2>

  <pre>
    <code class="ruby" data-trim>
    </code>
  </pre>
</section>

<section>
  <h2></h2>
  <ul>
    <li></li>
  </ul>
</section>

<section>
  <h2></h2>
  <p>
  </p>
</section> -->
