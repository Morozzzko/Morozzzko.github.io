---
layout: single
title: 'Unfinished: Designing helpful service objects. Part 2. Practice'
toc: true
header:
  og_image: "/assets/images/posts/service_objects/part_two.png"
reddit_comment_url:
date: 2022-04-27 03:38 +0300
---
<div class="notice">
  <p><strong>This is a partially-written post, which will never be complete</strong></p>

  <p>I've been writing this article on-and-off since June 2020. I didn't like how it turned out and re-wrote it numerous times.</p>

  <p>It tries to cover way too many things at once, and that's the problem I can't resolve without removing everything I've done and re-working the whole series. There are way too many assumptions and things which are missing for the complete picture. The reader would need the context for the article to be useful</p>

  <p>However, the work still might serve as an inspiration or an example to some. Even as an anti-example. So I'm leaving it here with an "unfinished" notice</p>
</div>


I've had countless arguments about software engineering, and "service objects" are one of the hot topics. I published [an article](/2020/06/01/helpful-service-objects-part-1-chosing-right-design.html) where I assessed different approaches to designing service objects. I've planned to have a three-part series of posts:

* [Choosing the right design](/2020/06/01/helpful-service-objects-part-1-chosing-right-design.html)
* _The practice_
* The next level

Right now, I want to demonstrate how to apply those principles _in practice_. 

This article may read like a tutorial on adding service objects to Rails app. Frankly, it _is_ a tutorial on adding service objects to Rails app.

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


# Implementation: bridge to existing code

Aside from writing a lot of new code, we need to integrate into existing Ruby code. Let's see how we deal with it.

Here's an existing order-completion code. We've had it before starting work on the feature:

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

There's not much to this code: it calls a method to complete the order. 

Right now we need two things: write the code which sends the email, and _call it_. There are several ways to do that:

**Call from controller**. We can call our service object right after we call `order.complete!`. It will become a burder right after you use `#complete!` in any other context. 

**Callbacks**. If a model has a callback for `order_completed`, then it _might_ be a solution. It's very likely that your team doesn't like callbacks, but they may work perfectly in _some_ codebases. 

**Event bus**. wisper, dry-events, kafka, zeromq, redis, sidekiq – whatever floats your boat. In this approach, `order#complete!` will publish an event. I prefer this solution even in monoliths. However, our app doesn't have an event bus, so we'll skip this option.

**Call from `#complete!`**. This is probably the most suitable solution here, as it makes sure that we get the same predictable behavior everywhere. It _looks_ worse than callbacks or event bus, but it'll work for most teams.

There are also other ways and DSLs like [AASM](https://github.com/aasm/aasm) which may trigger the code.

Either way, here's what it might look like:

```ruby
# app/models/order.rb

class Order < ApplicationRecord
  def complete!
    ...
    on_completed
  end

  private

  def on_completed
    # what has to go there?
  def
end
```

Now, we'll need to write some code which we'll call inside `on_completed`. 

Before we go on, we need to figure out the naming. Since we're developing "quality and motivation" features, let's put it in the corresponding module: `QualityAndMotivation`. 

We've got at least two options of naming our class:

* `SendReviewEmailToCustomer`, which is verbose, but clearly indicates what's going on
* `OrderCompleted`, which doesn't tell us _what's_ going on inside, but tells us _when_ the logic should be called

I suggest we use `OrderCompleted`, practically making it an _event_. I prefer this way for a number of reasons.

**The name makes it easier to search** related files. Whenever we want to find all things which happen when order is completed, we can just search for files containing `OrderCompleted` and dig from there.

**Project becomes easier to explore**. The name is an answer to "When exactly do we use the code?". 

There's a significant downside, though.

**You have to dig in to figure out what it does**. Usually when we see a method call, we can figure out the side-effects and what exactly the method does. If we see `SendReviewEmailToCustomer`, then it's obvious what's going on. With `OrderComplete`? Not so much. 

It's okay, though. It helps us figure out _the important_ parts of the process. Otherwise, we'd have to ask "is sending review email to customer a crucial part of order completing process?".

So here's the last reason to use event-centered naming:

**It helps us tell what's important and what's not**. If you decide to test `Order#complete`, you _know_ you can just stub `QualityAndMotivation::OrderCompleted` to do nothing. 


```ruby
# app/<we_will_decide_later>/quality_and_motivation/order_completed.rb

module QualityAndMotivation
  class OrderCompleted
    attr_reader :send_email

    def initialize(send_email:)
      @send_email = send_email
    end

    # we'll discuss parts above later

    def call(order)
      send_email.call(
        order.user, 
        template: 'order_completed', 
        locals: { baker_names: ..., scheduled_at: order.scheduled_at }
      )

      :success
    end
  end
end

# app/models/order.rb

class Order < ...
  ...
  def on_completed
    QualityAndMotivation::OrderCompleted.new(
      send_email: SendEmail.new,
    ).call(self)
  end
end
```

That's it. We've integrated new code into an existing process. Let's recap

* We named our service object after an event. The namespace represents the _context_ in which we handle the event – quality and motivation
* We've decided to put a call to our service object to a model method. It's okay because we don't have an event bus or other service objects
* We _have not_ given a name to the _directory_ for the newly created files
* We don't handle any errors. If email sending fails, the controller will handle it manually

# Implementation: all-new code

Now we need to implement the new logic: which will handle newly received logic. There are two parts: a service object and controller.

Controller will look pretty straightforward: it just instantiates service object and calls it, handling the result in a way.

```ruby
# app/controllers/api/customers/orders/rating_controller.rb

module API
  module Customers
    module Orders
      class RatingController < ApplicationController
        def complete
          case customer_submitted_rating.call(current_order, prepared_params[:rating])
          in :period_to_rate_expired
            render ...
          in :success
            render ...
          end
        end

        private

        def customer_submitted_rating
          QualityAndMotivation::CustomerSubmittedRating.new(order_rating: OrderRating, period_to_rate_days: 7)
        end

        def prepared_params
          params.require(:rating)
        end
      end
    end
  end
end
```

Here's how  `CustomerSubmittedRating` service object might look: it accepts or rejects the rating, considering the duration between current time and rating.

```ruby
module QualityAndMotivation
  class CustomerSubmittedRating
    attr_reader :period_to_rate_days, :order_rating

    def initialize(period_to_rate_days:, order_rating:)
      @period_to_rate_days = period_to_rate_days
      @order_rating = order_rating
    end

    def call(order, rating)
      if within_period_to_rate?
        order_rating.create!(order: order, rating: rating)
        :success
      else
        :period_to_rate_expired
      end
    end
  end
end
```

In real life we may get a constraint error because we can't submit the rating for the same order twice. We omit this because we don't want to add too many details.
{: .notice }


Here's one last thing: we still haven't implemented the logic which actually recalculates the rating and does something. I won't bother you with the actual code, as it'll look like this:

```ruby
def call(order)
  baker = order.baker
  old_rating, new_rating = recalculate_rating(baker)

  if ...
  else ...
  end
end
```


# "Service object" may not be a good name

<div class="notice">
  <p>The term "service object" is ambiguous and puts the discussion in the wrong direction. This happens because "service" is a term which is used in many contexts, including object-oriented programming, domain-driven design, Rails and Ruby world. Whenever we don't have a shared understanding, we get long-lasting arguments.</p>

  <p>My idea is that those "objects" are just functions. However, it's a variation of the more broad approach, so I'm still going to use the name.</p>
</div>


... the post ended here
