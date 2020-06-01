---
layout: single
title: "Why do we need service objects and how to make them helpful"
toc: true
---

# Practicing with command and the event: rating an order

Both the command and the event service objects have a similar design and their only difference is their name. I haven't really explained much how those objects work, so let's rectify it. 

So, the command and the event are service objects which serve a simple purpose: to model one concrete business process. Naturally, business processes start if _something happens_ or if someone wants to _perform something_. We'd want to use _the event_ in the first case and _the command_ in the second. 

I bet you're going to be writing commands most of the time, unless you're really invested in things like domain-driven design. I've used _the event_ occassionally, and it is definitely a great thing, but it might be a bit difficult to adjust to. Let's see a complex example which uses both kinds of service objects.

In this example, we're building a multi-sided marketplace where bakers can sell their pastry to the customers. We don't employ the bakers, but serve as a mere information medium between them and the customers. If the customer is unhappy, it's our risk and we pay out of our pocket. So we introduce the _quality and motivation_ system, which looks like this:

1. After a customer receives their order, we send them an email asking to rate the baked goods on a scale from 1 to 5. 
2. We calculate the baker's rating: we take the last 20 orders and calculate a weighted mean. Most recent orders matter most.
3. If the rating falls below a certain threshold, the baker enters the "danger zone" .
4. If the bakers enter the "danger zone" and don't improve their performance within the next three reviews, we stop working with them.
5. If the baker has a perfect rating, we'll give them 5% bonus with each rated order.

This logic might be enough to get you started, but let's add a little more context. I'll start with the high-level concept and the core collaborators:

1. The customers use mobile/web app which communicates HTTP API. Rating an order is a separate HTTP endpoint
2. Bakers use their own mobile app with a separate API. It's the main means of communication
3. Rating calculator is a complex logic, so we just delegate it

Since we can only communicate via mobile app, let's assume the "danger zone" is visible in the user interface. It'll enable us to tell bakers exactly how to improve their situation. However, it adds another constraint: we must explicitly toggle the states.

If we try to visualize the whole process, it will look like this:

<figure>
  <a href="/assets/bpmn/service_objects/rating_workflow.svg" target="_blank">
    <img src="/assets/bpmn/service_objects/rating_workflow.svg" alt="BPMN representation of the process">
  </a>
  <figcaption>A visual representation of the process. Click to open in new tab.</figcaption>
</figure>

It may seem pretty simple, but don't be fooled: there's a lot of room for failure and waste of time, so we need to take some time to design it. Let's dive into it.

We can see that it's not an atomic process, but a complex and distributed one. Distributed in terms of time and execution, as we can't afford to _just wait_ for seven days. This way, this huge process actually breaks into three smaller ones:

1. The `OrderCompleted` handler. We'll need to send an email and wait.
2. The `CustomerSubmittedRating` handler. We'll have to make sure that the rating can be submitted and actually save it to the database. It will emit the `CustomerRatedOrder` event.
3. The `CustomerRatedOrder` handler. That's where we handle all the specific logic.


<figure>
  <a href="/assets/bpmn/service_objects/rating_workflow_refactored.svg" target="_blank">
    <img src="/assets/bpmn/service_objects/rating_workflow_refactored.svg" alt="BPMN representation of the refactored process">
  </a>
  <figcaption>A visual representation of the three processes. Click to open in new tab.</figcaption>
</figure>

In some scenarios, we'll have an event bus and some kind of a event-based framework. Perhaps something complex like event sourcing or whatever. This is not our case. Let's imagine we have a bare Rails or a Hanami app with _no_ extra dependencies. 

I'll use Rails as an example because Hanami has a better integration for this kind of things, you can even [read the official docs](https://guides.hanamirb.org/architecture/interactors/). However, you can still apply the same ideas to Hanami, Sinatra or anything else with only difference being the routing toolkit and the way we store the service objects.

Let's say we have two routes:

```ruby
Prefix Verb URI Pattern                                      Controller#Action
       POST /orders/:id/complete(.:format)                   web/orders#complete
       POST /orders/:order_id/rating(.:format)               web/orders/rating#create
```

Let's see the code which handles the first part: sending the email.

```ruby
# app/operations/quality_and_motivation/order_completed.rb

module QualityAndMotivation
  class OrderCompleted
    attr_reader :send_email, :template_name

    def initialize(send_email:, template_name:)
      @send_email = send_email
      @template_name = template_name
    end

    def call(order)
      send_email.call(order.user, template_name)

      :success
    end
  end
end

# app/controllers/web/orders_controller.rb

module Web
  class OrdersController < ApplicationController
    OrderCompleted = QualityAndMotivation::OrderCompleted.new(send_email: SendEmail.new, template_name: "please_rate_order")

    def complete
      current_order.complete!

      result = OrderCompleted.call(current_order)

      render ...
    end
  end
end

```

We've got two important parts here: the `OrderCompleted` handler and the controller. 

**The handler** is just a service object which receives two options:

1. The `send_email` component, which is a callable instance. We expect that it's a function to send an email to a user. It sends an email using a provided email template.
2. The email template name

It doesn't do anything except send an email with the given template, and return `:success` to indicate that everything went smoothly.

I don't want to use exceptions or anything else in the logic, so I'm using trivial data structures to return values.
{: .notice-info }

**The controller** class stores the configured service object in a constant, and calls it after the event has happened.

This logic is pretty straightforward. `OrderCompleted` looks like callback and its nature is pretty close, except it doesn't just happen manually and you have a total control.

Controller for rating the order is going to look similar:

```ruby
# app/controllers/web/orders/rating_controller.rb
module Web
  module Orders
    class RatingController < ApplicationController
      CustomerSubmittedRating = QualityAndMotivation::CustomerSubmittedRating.new(order_rating_repo: Order, period_to_rate_days: 7)

      def complete
        CustomerSubmittedRating.call(current_order, rating)

        render ...
      end

      private

      def rating
        params.require(:rating)
      end
    end
  end
end
```


// ///////// TODO


```ruby
module QualityAndMotivation
  class CustomerSubmittedRating
    attr_reader :order_rating_repo, :period_to_rate_days

    def initialize(order_rating_repo:, period_to_rate_days:)
      @order_rating_repo = order_rating_repo
      @period_to_rate_days = @period_to_rate_days
    end

    def call(order, rating)
      if still_eligible_for_rating?(order)
        recored_rating = order_rating_repo.create(
          value: rating,
          order: order
        )

        {
          result: :customer_rated_order,
          rating: recorded_rating
        }
      else
        {
          result: :rating_no_longer_available, 
          period_to_rate_days: period_to_rate_days
        }
      end
    end

    private 

    def still_eligible_for_rating?(order)
      ...
    end
  end
end
```

```ruby
module QualityAndMotivation
  class CustomerRatedOrder
    attr_reader :block_baker, :show_warning, :remove_warnings, :give_bonus, :block_reason

    def initialize(block_baker:, show_warning:, remove_warnings:, give_bonus:, block_reason:)
      @block_baker = block_baker 
      @show_warning = show_warning 
      @remove_warnings = remove_warnings 
      @give_bonus = give_bonus 
      @block_reason = block_reason 
    end

    def call(order)
      baker_old_rating = order.baker

      baker_new_rating = baker_old_rating.recalculate_rating
      
      decision = decide_how_to_handle_change(baker_old_rating, baker_new_rating)

      case decision
      when :block
        block_baker.call(baker_new_rating, reason: block_reason)
      when :show_warnings
        show_warning.call(baker_new_rating)
      when :rating_recovered
        remove_warnings.call(baker_new_rating)
      when :reward
        give_bonus.call(baker_new_rating)
      end
    end

    private

    def decide_how_to_handle_change(baker_old_rating, baker_new_rating)
      ...
    end
  end
end
```

# Guidelines for helpful service object

Here's my own set of rules that help me build and maintain service objects. Those rules assume we're building single-method services in a mix of functional, object-oriented and procedural style.

**Pick the interface.** I use `#call`, but there are other options: `#run`, `#perform`, and some others. Anything works – just make sure to stay consistent throughout the project

**Expose errors and code smells early.** Focus your desing on exposing overly complex code as early as possible, while maintaining flexibility. 

**Pass arguments to `#call`, not the constructor.** While this advice will make you type a little more, the benefits are astonishing. 

**Use constructor to configure the concrete service.** This includes passing dependencies and magic values you'd put in constants. It enables you to tweak your logic whenever you need it. 


# How to take it a step further

I've shown the raw process that illustrates the general ideas. What we have in our real applications is usually different. It happens because of two reasons: 

* it's not pragmatic to follow every rule in the book
* we use this approach in combination with other tools 

I'm gonna talk about some examples off the top of my head.

## Use sensible defaults

You can probably use default behavior 90% of the time. It gets frustrating to type in thd default dependencies everywhere. What if the default changes? Should we `grep` across the project and replace all occurrences? No way.

Default values in the constructor are a good option if you feel like the added verbosity is too much

```ruby
# Before: no defaults, have to pass them every time

def initialize(block_baker:, show_warning:, remove_warnings:, give_bonus:, block_reason:)
  @block_baker = block_baker 
  @show_warning = show_warning 
  @remove_warnings = remove_warnings 
  @give_bonus = give_bonus 
  @block_reason = block_reason 
end

# After. Example 1: Sharing defaults across instances

def initialize(
  block_baker: BlockBaker.new, 
  show_warning: ShowWarning.new, 
  remove_warnings: RemoveWarnings.new, 
  give_bonus: GiveBonus.new,
  block_reason: :low_quality_auto
)
  @block_baker = block_baker 
  @show_warning = show_warning 
  @remove_warnings = remove_warnings 
  @give_bonus = give_bonus 
  @block_reason = block_reason
end

# After. Example 2: Building new defaults for each instance

def initialize(block_baker: nil, show_warning: nil, remove_warnings: nil, give_bonus: nil, block_reason: nil)
  @block_baker = block_baker || BlockBaker.new
  @show_warning = show_warning  || ShowWarning.new
  @remove_warnings = remove_warnings  || RemoveWarnings.new
  @give_bonus = give_bonus  || GiveBonus.new
  @block_reason = block_reason || :low_quality_auto
end
```

## Reduce boilerplate setup with gems

Writing constructors gets tedious, so it's natural to reduce the boilerplate using a domain-specific language or external gems.

I like the DSL provided by [dry-initializer](https://dry-rb.org/gems/dry-initializer/3.0/) as it's plain enough and integrates with dry-rb ecosystem. You can use other gems, though.

See how it looks:

```ruby
# Before

class MyClass
  attr_reader :block_baker, :show_warning, :remove_warnings, :give_bonus, :block_reason

  def initialize(block_baker: nil, show_warning: nil, remove_warnings: nil, give_bonus: nil, block_reason: nil)
    @block_baker = block_baker || BlockBaker.new
    @show_warning = show_warning  || ShowWarning.new
    @remove_warnings = remove_warnings  || RemoveWarnings.new
    @give_bonus = give_bonus  || GiveBonus.new
    @block_reason = block_reason || :low_quality_auto
  end
end

# After

class MyClass
  extend Dry::Initializer

  option :block_baker, default: -> { BlockBaker.new }
  option :show_warning, default: -> { ShowWarning.new }
  option :remove_warnings, default: -> { RemoveWarnings.new }
  option :give_bonus, default: -> { GiveBonus.new }
  option :block_reason, default: -> { :low_quality_auto }
end
```

Usually, the end result has the same number of lines, but the main benefit is that you don't have to type the same thing four times: one time in `attr_reader`, one in constructor signature, and two in the constructor body. This leads to the silliest of bugs, so we can avoid then. A reduced visual clutter is a bonus, too.

## Make use of result objects and railway oriented programming

Result objects are a common pattern in Ruby community, yet there are way too many options to implement them.

Please refer to Vitaly Pushkar's article ["Error handling with Monads in Ruby"](https://nywkap.com/programming/either-monads-ruby.html)

However, it's not the only way to implement result objects. I'll cover it in a separate topic

I've also had my own articles: 

* Monads are just a tool [](/2020/04/01/should-i-really-use-monads.html)
* Railway oriented programing with do notation (an old one) [](/2018/05/27/do-notation-ruby.html)
## Know when to avoid railway oriented programming

See

https://fsharpforfunandprofit.com/posts/against-railway-oriented-programming/

## Think about automated dependency management

See dry-container, dry-auto_inject and dry-system


## A short lifetime may be reasonable too

In [Why some service objects are more useful than others](#why-some-service-objects-are-more-useful-than-others) I mentioned that each object must have a reasonable lifetime. I explained that since service objects are essentially functions, their lifetime should be similar to a function's lifetime. Which is almost equal to the duration of Ruby process.

However, this is not the universal truth, as there are cases when a shorter lifetime is more desirable:

**Fixing memory leaks.** Shorter lifetime hels if a dependency allocates memory which is never freed. Adding a shorer lifecycle will probably help Ruby free the memory. It's not the only solution, but it's a quick one.

**Context-dependent logic.** Let's say you have a multi-tenant SaaS project. Each piece of logic will be associated with one of your tenants. Now, there are two common ways to approach this:

1. Pass the context around. It's a solution, but I bet you'll get tired of it pretty quickly.
2. Make context a dependency. This way, you won't have to pass it with _absolutely every_ method call. Especially helpful if you've [thought about automated dependency management](#think-about-automated-dependency-management), which will do most of the work for you.

In this scenario, I'd rather choose the second path, as it's just tiresome to pass the context around.Moreover, allocating dedicaded functions for all of your tenants sounds crazy. Imagine having thousands of `two_plus_two` functions, one for each tenant. No.

**Lack of tools in the project.** If I know I want to have one instance per process, I'll probably store it somewhere. However, it requires some organizational work: picking an approach, choosing a library, enforcing the convention. This is not always justifiable in the moment, so it's alright to cut the corner here and leave the work to the future you.





## Visualize your dependencies

See dry-system and https://github.com/dry-rb/dry-system-dependency_graph




# References

https://hackernoon.com/the-3-tenets-of-service-objects-c936b891b3c2
https://medium.com/selleo/essential-rubyonrails-patterns-part-1-service-objects-1af9f9573ca1
https://medium.com/@scottdomes/service-objects-in-rails-75ca74214b77
https://www.toptal.com/ruby-on-rails/rails-service-objects-tutorial

critique:
https://avdi.codes/service-objects/
https://www.codewithjason.com/rails-service-objects/

