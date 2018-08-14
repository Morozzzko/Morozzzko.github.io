---
layout: slides
title: "Ducks and Monads: Wonders of Ruby types"
description: EuRuKo 2018
theme: white
highlightjs_theme: atom-one-light # github
transition: slide
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
</style>

<section>
  <h1>Ducks and Monads</h1>
  <h2>Wonders of Ruby Types</h2>
</section>

<section>
  <h2>Hey, I'm Igor</h2>
  <p>/'<span style="font-family: monospace;">iːgɔːɹ</span>/</p>

  <aside class="notes">
    Say something about yourself
  </aside>
</section>

<section>
  <h2>I'm a polyglot programmer at Qlean.ru</h2>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>I don't trust myself</h2>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>There are four reasons I don't trust myself</h2>
</section>

<section>
  <h2>
    undefined is not a function
  </h2>
</section>

<section>
  <h2>
    N&nbsp;+&nbsp;1
  </h2>
</section>

<section>
  <h2>
    I mess up business logic
  </h2>
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

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Tools to write type-safe Ruby code</h2>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Virtus (deprecated)</h2>
  <pre>
    <code class="ruby" data-trim>
      class User
        include Virtus.model

        attribute :name, String
        attribute :age, Integer, optional: true
      end

      user = User.new(name: 'Mickey')

      user.age # => nil
      user.age = '31' # => 31
      user.age.class # => Integer

    </code>

  </pre>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>What was so cool about it?</h2>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Boilerplate (before)</h2>
  <pre>
    <code class="ruby" data-trim>
      class User
        attr_accessor :name, :phone, :age, :repo, :injected_service

        def initialize(
          name: , phone: nil, age: nil,
          repo: UserRepo,
          injected_service: InjectedService.new
        )
          @name = name
          @phone = phone
          @age = age
          @repo = repo
          @injected_service = injected_service
        end
      end
    </code>

  </pre>
  <p>
    We have to type each attribute name three times
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Less boilerplate (after)</h2>
  <pre>
    <code class="ruby" data-trim>
      class User
        include Virtus.model

        attribute :name, String
        attribute :phone, String, optional: true
        attribute :age, Integer, optional: true
        attribute :repo, Class, default: UserRepo
        attribute :injected_service, Class, default: InjectedService
      end
    </code>

  </pre>
  <p>
    One attribute &ndash; one definition. No more typos!
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Type checks</h2>

  <pre>
    <code class="ruby" data-trim>
      class Duck
        include Virtus.model(strict: true)

        attribute :name, String # <- can never be nil
        attribute :age, Integer, required: false
      end

      donald = Duck.new(name: 'Donald')

      donald.age # => nil

      donald.age = 'I am not a number'
      # => Failed to coerce attribute `age'
      # from "I am not a number" into Integer
    </code>
  </pre>
  <p>
    It has nilable types too!
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Type coercions</h2>
  <pre>
    <code class="ruby" data-trim>
      class Event
        include Virtus.model

        attribute :date, Date
      end

      euruko = Event.new(date: "2018-08-24")
      euruko.date # => Fri, 24 Aug 2018
      euruko.date.class # => Date < Object
    </code>

  </pre>
  <p>
    Convenience <em>and</em> type safety!
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Nested assignment</h2>
  <pre>
    <code class="ruby" data-trim>
      class EventDuration
        include Virtus.model
        attribute :start_at, Date
        attribute :finish_at, Date
      end

      class Event
        include Virtus.model
        attribute :date, EventDuration
      end

      euruko = Event.new(date: {
        start_at: "2018-08-24",
        finish_at: "2018-08-25"
      })
    </code>

  </pre>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Virtus used to empower us</h2>
  <p>
    But it's deprecated in favor of dry-struct
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>dry-initializer can replace Virtus</h2>

  <pre>
    <code class="ruby" data-trim>
      class Duck
        extend Dry::Initializer

        option :name, String
        option :age, Integer, optional: true
      end

      donald = Duck.new(name: 'Donald')
    </code>
  </pre>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>dry-struct &amp; dry-types force you to learn</h2>
  <p>
    You can't fulyl enjoy those libraries until you've learned to think differently
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>
    functional programming <br />
    + <br />
    Ruby <br />
    =<br />
    ❤
  </h2>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Ruby's functional features</h2>
</section>

<section><h2>Expression-based syntax</h2></section>
<section><h2>Higher order functions</h2></section>
<section><h2>Immutability (<code>#freeze</code>)</h2></section>
<section><h2>Identity function (<code>Object#itself</code>)</h2></section>
<section><h2>map, flat_map, reduce, select, reject</h2></section>
<section><h2><code>proc#curry</code></h2></section>
<section><h2>Tail recursion optimization (opt-in)</h2></section>

<section>
  <h2><q>dry-types is a simple and extendable type system for Ruby</q></h2>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>What's a type, anyway?</h2>
  <p>
    <ul>
      <li>Syntactic</li>
      <li>Representation</li>
      <li><strong>Representation and behavior</strong></li>
      <li>Value space</li>
      <li><strong>Value space and behavior</strong></li>
    </ul>

  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Representation and behavior</h2>
  <q>
    A type is defined as its representation and a set of operators manipulating these representations.
  </q>

  <aside class="notes">
  </aside>
</section>

<!-- <section>
  <h2>Representation and behavior</h2>
  <pre>
    <code class="ruby" data-trim>
      class Duck
        def walk(steps)
          "We've walked #{steps} steps"
        end
      end

      donald = Duck.new
      donald.walk(10) # => "We've walked 10 steps
      donald.nil? # => false
      donald.class # => Duck < Object
      donald.bark
      # => NoMethodError: undefined method `bark' for ...
    </code>

  </pre>
  <p>
    Objects are representation. Methods are operators.
  </p>
</section> -->

<section>
  <h2>Value space and behavior</h2>
  <q>
    A type is a set of values which a variable can possess and a set of functions that one can apply to these values.
  </q>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>A variable can possess an infinite set of values</h2>
  <p>
    But we still expect our variables types be predictable
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>How do we define a type in Ruby?</h2>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Duck test</h2>
  <q>
  If it looks like a duck, swims like a duck, and quacks like a duck, then it probably is a duck.
  </q>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Object belongs to a type if it exposes desired behavior</h2>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Ducks behave similarly</h2>

  <pre>
    <code class="ruby" data-trim>
      class Duck
        def call
          "Hello"
        end
      end
      def quack
        "<3"
      end

      huey = Duck.new
      dewey = -> { "there" }
      louie = method(:quack)

      [huey, dewey, louie].map(&:call).join(' ')
      # => "Hello there <3"
    </code>
  </pre>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>
    What's so different about dry-types?
  </h2>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Composable type and value constructors</h2>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>A constructor is a method that initialized an object of a a specific type</h2>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Value constructors in Ruby</h2>
  <ul>
    <li><code>Class#new</code></li>
    <li><code>Kernel#Integer</code></li>
    <li><code>Kernel#String</code></li>
    <li><code>Kernel#Hash</code></li>
    <li><code>Kernel#URI</code></li>
    <li><code>Kernel#Rational</code></li>
    <li><code>…</code></li>
  </ul>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Value constructor: Kernel#Float</h2>
  <pre>
    <code class="ruby" data-trim>
      Float("123") # => 123.0
      Float(123) # => 123.0
      Float(123.0) # => 123.0
      Float([123]) # => TypeError
      # (can't convert Array into Float)
    </code>
  </pre>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Value constructors in dry-rb</h2>
  <pre>
    <code class="ruby" data-trim>
      Types::Coercible::Float.call("123") # => 123.0
      Types::Coercible::Float.call(123) # => 123.0
      Types::Coercible::Float.call(123.0) # => 123.0
      Types::Coercible::Float.call([123]) # => TypeError
      # (can't convert Array into Float)
    </code>
  </pre>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Definitions</h2>
  <pre>
    <code class="ruby" data-trim>
      class Duck < Dry::Struct
        attribute :name, Types::String
        attribute :age, Types::Integer
      end

      donald = Duck.new(name: 123, age: []) #  No error here
    </code>

  </pre>
  <p>
    Base definitions without type checks or coercions. Only suitable for type annotations
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Coercible types</h2>
  <pre>
    <code class="ruby" data-trim>
      class Duck < Dry::Struct
        attribute :name, Types::Coercible::String
        attribute :age, Types::Coercible::Integer
      end

      donald = Duck.new(name: 'Donald', age: '13')
      donald.age # => 13
    </code>

  </pre>
  <p>
    Coercible types use kernel coercions to build a specific value and raise exceptions if it's impossible.
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Strict types</h2>
  <pre>
    <code class="ruby" data-trim>
      class Duck < Dry::Struct
        attribute :name, Types::Strict::String
        attribute :age, Types::Strict::Integer
      end

      donald = Duck.new(name: 'Donald', age: '13')
      # => Dry::Types::ConstraintError ("13" violates constraints
      # => (type?(Integer, "13") failed))
    </code>

  </pre>
  <p>
    Strict types ensure that the constructor input matches the output type.
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Optional types</h2>
  <pre>
    <code class="ruby" data-trim>
      class Duck < Dry::Struct
        attribute :name, Types::Optional::Strict::String
        attribute :age, Types::Optional::Strict::Integer
      end

      donald = Duck.new(name: 'Donald', age: nil)
      donald.name # => 'Donald'
      donald.age # => nil
    </code>

  </pre>
  <p>
    Optional types mark a strict or coercible type as nilable.
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Maybe types</h2>
  <pre>
    <code class="ruby" data-trim>
      Dry::Types.load_extensions(:maybe)

      class Duck < Dry::Struct
        attribute :name, Types::Maybe::Strict::String
        attribute :age, Types::Maybe::Strict::Integer
      end

      donald = Duck.new(name: 'Donald', age: nil)
      donald.name # => Some('Donald')
      donald.age # => None
    </code>

  </pre>
  <p>
    Maybe types behave similarly to optional types, except they wrap the result into the Maybe monad.
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Algebraic data type (ADT)</h2>
  <p>
    is a type formed by combining other types.
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
<!-- TODO: think about removing subtitle -->
  <h2>Algebraic data type: product</h2>
  <p>
    Whenever a type consists of multiple fields, it's a product type.
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
<!-- TODO: think about removing subtitle -->
  <h2>Algebraic data type: sum</h2>
  <p>
    Whenever a value can be one of multiple possible types, it's a sum.
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Sum in action</h2>

  <pre>
    <code class="ruby" data-trim>
      Age = Types::Strict::String | Types::Strict::Integer

      Age["12"] #=> "12"
      Age[12] # => 12
      Age[nil] # => Dry::Types::ConstraintError
      # (nil violates constraints (type?(Integer, nil) failed))
    </code>
  </pre>

  <aside class="notes">
  </aside>

</section>

<section>
  <h2>Types and transformations</h2>

  <pre>
    <code class="ruby" data-trim>
      Email = Types::Strict::String
                .constructor(&:downcase)
                .constructor(&:strip)

      Email["  hello@EXAMPLE.com"] # => "hello@example.com"

    </code>
  </pre>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Instance type</h2>

  <pre>
    <code class="ruby" data-trim>
      Goose = Class.new

      StrictGoose = Types::Instance(Goose)
      OptionalGoose = StrictGoose.optional

      lucy = Goose.new

      OptionalGoose[lucy] # => #<Goose#....>
      StrictGoose[lucy] # => #<Goose#....>

      OptionalGoose[nil] # => nil
      StrictGoose[nil] # => Dry::Types::ConstraintError
      # (nil violates constraints (type?(Goose, nil) failed))
    </code>
  </pre>

  <aside class="notes">
  </aside>
</section>

<!--

require 'dry/types'
require 'dry-initializer'

module Types
  include Dry::Types.module
end





-->

<section>
  <h1>Monads in Ruby</h1>
</section>

<section>
  <h2>Monads are similar to musical instruments</h2>

  <aside class="notes">
    You can use them, but you can't give them a good definition without being wrong
  </aside>
</section>

<section>
  <h2><q>A monad is just a monoid in the category of endofunctors.
    What's the problem?
  </q></h2>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>A monad is a computation context</h2>
  <pre>
    <code class="ruby" data-trim>
      def call
        first_action
          .bind(&second_action)
          .bind(&other_action)
          .or(&recover_from_error)
          .fmap(&render_result)
          .value!
      end
    </code>
  </pre>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>
    A monad is a result object with a few rules
  </h2>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Result (Either) monad</h2>
  <p>
    Useful for computations that might fail
  </p>
  <p>
    Popular for Railway-oriented programming
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2><code class="haskell">type Result a b = Failure a | Success b</code></h2>

  <aside class="notes">
  </aside>
</section>

<section>
  <pre>
    <code class="ruby" data-trim>
      class Attack
        include Dry::Monads::Result
        FAILURE_MESSAGES = %i[fell_in_sewer tripped died]

        def call(enemy)
          if rand(2).zero?
            Success(enemy.hit(10))
          else
            Failure(FAILURE_MESSAGES.sample)
          end
        end
      end
    </code>

  </pre>
  <p>
    It returns <code>Failure(String)</code> or <code>Success(Enemy)</code>
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Escaping the context</h2>
  <pre>
    <code class="ruby" data-trim>
      # To get an updated enemy:
      attack.call(enemy).value! # will raise exception for Failure
      attack.call(enemy).value_or { nil } # nil for Failure

      # To get an error string:
      attack.call(enemy).flip.value_or { nil } # => nil for Success

      # To get whatever is inside the result:
      attack.call(enemy).value_or(&:itself)
    </code>

  </pre>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Imperative monads: do-notation</h2>
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

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Monads promote early error handling</h2>
  <p>
    Errors are not so exceptional, so we must always keep them in mind.
  </p>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Nil-safe computation: Maybe</h2>

  <pre>
    <code class="ruby" data-trim>
      user&.orders&.first&.address&.id
      # =>
      user
        .fmap(&:orders)
        .fmap(&:first)
        .fmap(&:address)
        .fmap(&:id)
        .value_or { nil }
    </code>
  </pre>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Concurrency: Task</h2>

  <code>
    Task { ... }.bind(&:print)
  </code>

  <aside class="notes">
  </aside>
</section>

<section>
  <h2>Exceptions: Try</h2>

  <pre>
    <code class="ruby" data-trim>
      def divide(a, b)
        Try(ZeroDivisionError) do
          a / b
        end.to_result
      end

      case divide(1, 0)
        when Success
          print "hooray!"
        when Failure(ZeroDivisionError)
          print "yikes"
      end
    </code>
  </pre>

  <aside class="notes">
  </aside>
</section>

<!-- <section>
  <h2>Type: integer</h2>
  <p>
    Possible values: {-∞ … -1, 0, 1, 2 … ∞} <br />
    Applicable functions/operators: <code>+</code>, <code>-</code>, <code>zero?</code>, <code>negative?</code>, etc.
  </p>
</section>

<section>
  <h2>Type: string</h2>
  <p>
    Possible values: {"", "hello", "there", "a" …} <br />
    Applicable functions/operators: <code>+</code>, <code>split</code>, <code>empty?</code>, <code>upcase</code>, etc.
  </p>
</section> -->

<section>
  <h2>Recap</h2>
  <!-- TODO: split -->
  <ul>
    <li>dry-initializer + dry-types can replace Virtus</li>
    <li>dry-types = flexible type definitions and type safety</li>
    <li>Monads are not scary</li>
    <li>Ruby is great for programmers</li>
  </ul>

  <aside class="notes">
  </aside>
</section>

<section>
  <h1>Thank you! ❤</h1>
  <p>
    I would love to hear from you
    <br />
    igor@morozov.is
  </p>

  <aside class="notes">
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
