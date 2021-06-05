---
layout: single
title: "Designing helpful service objects. Part 2. Practice"
toc: true
header:
  og_image: "/assets/images/posts/service_objects/part_two.png"
reddit_comment_url: false
---

I've had countless arguments about software engineering, and "service objects" are one of the hot topics. I published [an article](/2020/06/01/helpful-service-objects-part-1-chosing-right-design.html) where I assessed different approaches to designing service objects. I've planned to have a three-part series of posts:

* [Choosing the right design](/2020/06/01/helpful-service-objects-part-1-chosing-right-design.html)
* _The practice_
* The next level

Right now, I want to demonstrate how to demonstrate how to apply those principles _in practice_.

<!-- excerpt -->

# What we're dealing with

In the first part, I've listed different ways to implement a "service object". Out of all those options, I pushed hard towards a concrete design. Let's revisit it.

Business processes start when _something happens_ or if someone wants to _perform an action_. We want our code to reflect this reality, so we name our service objects after the **events and commands** which trigger the process. Class names would look like `CustomerSubmittedRating`, `BakerHired`, `CakeBaked` for events and `FireBaker`, `SubmitRating` and `AmendOrder` for commands.

**We use `#call`** to run the logic. It's a pretty standard way to call a function, proc or just a generic piece of code.

**No mutable state** in our objects. Dependencies and configurable options go to constructor / instance attributes and never change. We understand dependencies as other service objects, functions, renderers, database connections, repositories, whatever pieces of logic we need to run it. 

**Parameters** or **input** go to the `#call` as arguments, and we never store them in object state.

If you've missed out on some details and reasoning, please refer to section ["Why some service objects are better than other"](/2020/06/01/helpful-service-objects-part-1-chosing-right-design.html#why-some-service-objects-are-more-useful-than-others) of my previous article, where I add philosophical and practical perspective to those decisions.


# How we're going to do it

We'll dig into a context of a real-life application. We'll start at the highest level and then "zoom in" to make lower-level considerations. Basically, we'll have three levels of detail:

1. **Business requirements**. Figure out _what_ and _why_ we'll add something to our project.
2. **Technical requirements**. What systems do we interact with? How?
3. **Code**. Implementation with just enough detail

Afterwards, we'll see how to adapt to new requirements and extend the objects.

# Application: improving quality for a baker-to-consumer marketplace

Let's say we're building a multi-sided marketplace where bakers can sell their pastry to customers. 

We don't directly employ the bakers, but serve as an information medium between them and the customers. Customers submit their orders and we help distribute the orders among bakers. If the customer is unhappy, it's our risk and we cover any damages out of our own pocket.

We want to minimize the risks, so we introduce the _quality and motivation_ system. It is based on communication, feedback and maths:

1. After a customer have received their order, we send them an email asking to rate the baked goods on a scale from 1 to 5. 
2. After every rating, we calculate the baker's rating: we take the last 20 orders and calculate a weighted mean: most recent orders matter most.
3. If the rating falls below a certain threshold, the baker enters the "danger zone".
4. If the bakers in the "danger zone" doesn't improve their performance within the next three reviews, we cancel their future orders and disable their account.
5. Bakers with perfect rating get a 5% bonus for every rated order

It might not look _too_ complex at the first sight, but in reality, we've got a lot of moving parts:

* We need to build a subsystem which allows customers to rate orders: it affects database, code organization and web/mobile apps.
* Rating recalculation 
* The "danger zone"
* Payout calculation
* Communication via e-mail
* Disabling accounts and cancelling future orders
* API for customer web app
* API for baker app, which is the primary way to communicate with bakers

Since we can only communicate via mobile app, let's assume the "danger zone" is visible in the user interface. It'll enable us to tell bakers exactly how to improve their situation. 

If we try to visualize the whole process, it will look like this:

<figure>
  <a href="/assets/bpmn/service_objects/rating_workflow.svg" target="_blank">
    <img src="/assets/bpmn/service_objects/rating_workflow.svg" alt="BPMN representation of the process">
  </a>
  <figcaption>A visual representation of the process. Click to open in new tab.</figcaption>
</figure>

We can see that  not an atomic process, but a complex and distributed one. Distributed in terms of time and execution, as we can't afford to _just wait_ for seven days. This way, this huge process actually breaks into three smaller ones:

* `OrderCompleted` – when we send an email
* `CustomerSubmittedRating` – when the customer submits their rating via app. It shouldn't fail most of the time, but it _may_ fail if the 7-day threshold is passed
* `CustomerRatedOrder` – when the rating has been accepted

<figure>
  <a href="/assets/bpmn/service_objects/rating_workflow_refactored.svg" target="_blank">
    <img src="/assets/bpmn/service_objects/rating_workflow_refactored.svg" alt="BPMN representation of the refactored process">
  </a>
  <figcaption>A visual representation of the three processes. Click to open in new tab.</figcaption>
</figure>

We can't say much more about the flow without introducing more technical detail.

# Assumptions about the tech stack

Since we don't have a _real_ project, we need to make a few assumptions so that we're on the same page.

**We use Rails** because it's pretty common and because I want to emphasize that it's possible to introduce the ideas in the existing app. Even a legacy one.

**There are no service objects whatsoever**. All domain logic is in the models.

However, we could have used [Hanami](https://hanamirb.org/) as a framework or [Roda](https://roda.jeremyevans.net/) as routing & [Sequel](https://github.com/jeremyevans/sequel) or [ROM](https://rom-rb.org/) for persistence. The principles stay the same.

**It's a monolith** with two "modules" – HTTP API and an admin panel. The modules are not separate [engines](https://guides.rubyonrails.org/engines.html), but simple namespaces within the app.

**API is RESTful-ish**. We try to follow resource-based approach and use HTTP verbs, which resembles a lot of RESTful APIs. However, some of our endpoints are _verbs_. It's not exactly RESTful, but it's pragmatic enough.

**Mobile apps are the only API consumers**. They are under our control.

**There is no tool for delayed execution**. Our only entry points are HTTP controllers. There's no event bus or sidekiq.

**We use all-caps acronyms**. That's why you'll see `API` instead of `Api`. We've just configured [inflections](https://api.rubyonrails.org/v6.1.3.2/classes/ActiveSupport/Inflector.html).

Now that we're on the same page, we can move on to the next step: contracts.

# Designing contracts

Since our task doesn't require anything from an admin panel, we can skip it and focus on HTTP API.

When we're talking about HTTP contracts, we usually speak about paths, methods and payloads. We don't care about payloads right now, so we'll focus on the paths and methods.

Let's imagine we run `rails routes`. We should see two routes: one of completing the order and one for submitting the rating.

```
Prefix Verb URI Pattern                                                Controller#Action
       POST /api/bakers/orders/:id/complete(.:format)                  api/bakers/orders#complete
       POST /api/customers/orders/:order_id/rating(.:format)           api/customers/orders/rating#create
```

This should be enough for the whole client-server communication.

In real life, we'll also have multiple ways to communicate that the baker has entered the "danger zone" or that they've been blocked. Let's assume that this communication goes through push notifications and text messages, and never queried via API.


# Implementation: HTTP / controllers

In this part we'll draft the controller code and explain what's going on there.

Here's how order-completion part looks right now:

```ruby
# app/controllers/api/bakers/orders_controller.rb

module API
  module Bakers
    class OrdersController < ApplicationController
      def complete
        order.complete!

        render ...
      end
    end
  end
end
```

There's not much to this code: it calls a method to complete the order. Right now we need two things: write the code which sends the email, and _call it_.

There are several ways to do that:

**Call from controller**. We can call our service object right after we call `order.complete!`. It will become a burder right after you use `#complete!` in any other context. 

**Callbacks**. If a model has a callback for `order_completed`, then it _might_ be a solution. It's very likely that your team doesn't like callbacks, but they may work _perfectly_ in some codebases. 

**Event bus**. wisper, dry-events, kafka, zeromq, redis, sidekiq – whatever floats your boat. In this approach, `order#complete!` will publish an event. I prefer this solution even in monoliths. However, our app doesn't have an event bus, so we'll skip this option.

**Call from `#complete!`**. This is probably the most suitable solution here, as it makes sure that we get the same predictable behavior everywhere. It _looks_ worse than callbacks or event bus, but it'll work for most teams.

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
      in :block
        block_baker.call(baker_new_rating, reason: block_reason)
      in :show_warnings
        show_warning.call(baker_new_rating)
      in :rating_recovered
        remove_warnings.call(baker_new_rating)
      in :reward
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



# "Service object" may not be a good name

<div class="notice">
  <p>The term "service object" is ambiguous and puts the discussion in the wrong direction. This happens because "service" is a term which is used in many contexts, including object-oriented programming, domain-driven design, Rails and Ruby world. Whenever we don't have a shared understanding, we get long-lasting arguments.</p>

  <p>My idea is that those "objects" are just functions. However, it's a variation of the more broad approach, so I'm still going to use the name.</p>
</div>

