---
layout: single
title: Should I _really_ use monads?
toc: true
toc_sticky: true
header:
  og_image: "/assets/images/previews/should-i-really-use-monads.png"
date: 2020-04-01 20:19 +0000
---
A couple of weeks ago I witnessed a dialogue in a [Ruby chat](https://t.me/rubylang). I'm paraphrasing, but it went like this:

> xxx: What is `dry`? I've seen this gem prefix and discussions, but never actually learned about it. <br />
> yyy: It's a set of libraries to tackle some problems. <br />
> zzz: Yeah, and introduce new ones, such as "How do I explain to my colleague that they need monads".

Let's be honest. I felt so many emotions that I couldn't think straight. I've been discussing this exact topic so many times that I've exhausted myself. There's a lot of misconceptions, frustration and plain skepticism around monads, and it all leads to aggressive rejection by many.

Right now, I want to finish this topic once and for all. Not going to do it in this post, though. I'm writing a huge piece on error handling techniques in Ruby, which will cover strong and weak points of different techniques, including monads. 

In _this_ post, I will try to step back and speak about monads from a more practical and emotional perspective. I will briefly explain what a monad really is, why is it valuable, and some of the common issues with it. It's about people and technology, so don't expect to see any code.
<!-- excerpt --> 

# What is a monad

When we're speaking about monads in Ruby, we're usually talking about [dry-monads](https://dry-rb.org/gems/dry-monads/) – a library that implements them. However, monad is a much broader concept that comes from category theory:

> A monad is just a _monoid_ in the category of endofunctors. What's the problem?

The internet is full of jokes like this. It's a comprehensive definition, but it's _so vague_. To be fair, _most_ definitions won't give you anything concrete. Giving a definition to monads is a lot like trying to give a proper definition to a "musical instrument". It's going to be either vague and correct or understandable and incomplete; simply because each instrument, just like each monad, plays a different role. I'll give you somewhat correct, but a little vague explanation.

A `monad` is just a ~~fancy~~ mathematical name for abstractions that behave in a [specific way](/2018/09/08/monad-laws-in-ruby.html). In theory, it lets us chain them, compose them in different ways. In practice, we'd rarely notice the monadic nature of those abstractions. Let's focus on individual monads and see what they bring to the table.

**Fact**: Ruby's built-in `Array` and `String` are _monoids_ too. We never think about it — that's how we should treat monads too.
{: .notice--info }

[Maybe](https://dry-rb.org/gems/dry-monads/1.3/maybe/) is an abstraction that allows us to express _absence of data_. In practice, it enables us to do nil-safe computations and never worry about getting `undefined method for nil:NilClass`. It acts like an _extremely explicit_ alternative to `nil`. It may be good when you return it from a [repository](https://medium.com/@laertis.pappas/repository-pattern-in-ruby-i-decoupling-activerecord-and-persistence-e395e1b0cf69), but I don't use it my models.

[Try](https://dry-rb.org/gems/dry-monads/1.3/try/) is a nice wrapper for exceptions. It's helpful if you need to chain some actions, which may raise an exception. The standard exception-catching mechanism may break the flow and make you jump around the code to get the full picture. Try saves you from this.

[Task](https://dry-rb.org/gems/dry-monads/1.3/task/) is a wrapper around [concurrent ruby's](https://github.com/ruby-concurrency/concurrent-ruby) `Promise`. I've seen folks use it as an easy way to do concurrent IO – download things, write to database, etc. Just take at look at Vasily Kolesnikov's [asynchronous file downloader](https://gist.github.com/v-kolesnikov/c5807aab0ac7ba5d1ba5e31be32e21e6). It receives a list of URLs and creates tasks to download them. Without many low-level asynchronous details.

[Result](https://dry-rb.org/gems/dry-monads/1.3/result/) is the most common monad in a Ruby world. We use it to express result of a function call. It's most useful when the result can be a `Success` or a `Failure`, which works as natural as it sounds. You can just `return Success(with_your_data)` from your function and work with it. If something goes wrong, you would `return Failure("and provide some details")`. 

There are other monads, but I'll omit them as those are not _that_ common and won't benefit to the story. 

# The beef with monads

So, what's the problem with monads? They seem to be a pretty controversial topic, but why? They seem to be pretty good at doing their job. What's wrong with that?

Everyone has their own problems with monads. Some folks get mildly annoyed by little things. Others are outraged that such an abomination exists in Ruby. Just see what folks have been telling me:

* Monads are only useful in statically typed languages and only cause trouble in Ruby
* Functional programming doesn't look right in Ruby
* Monads don't feel like a right fit in Ruby
* It's just a syntactic sugar for if and else (_speaking about Result_)
* We already have exceptions for that (_speaking about Result_)
* It's over-engineering
* People who use monads look like a cult
* Don't try to bring Haskell into Ruby

It's just a list of things off the top of my head. Sure, I'm paraphrasing, but the main idea looks like this. 

Some people who share those things are nice, friendly and welcoming; while some are hostile and won't accept any reason. I won't try to generalize based on their background or any other factor. Instead, I will address some misconceptions and speak about emotions that drive them.

## Is Ruby really the right place for those things?

This issue is probably the most popular one. There's actually a lot of reasons for this skepticism, let's think about them.

**Monads are a concept from the category theory.** Math. Their representation in software development is mostly `Haskell`, which uses them _heavily_, and it's definitely not a mainstream language. It creates a subconscious association: haskell / monads =  something difficult and clumsy.

**They come from other languages.** The `Result` type gets a lot of usage in Rust, Kotlin, Swift, F#, OCaml/ReasonML and Elm too. All of those languages are statically typed and compiled, which enables to do extra static analysis. For example, the compilers may check if you've handled all possible cases. Those checks are nearly impossible to implement in Ruby.

**Ruby is an object-oriented language.** Monads are a concept from functional programming, which may seem a bit odd and counter-intuitive.

**You'll have to learn a new interface.** When you take a look at dry-monads, you'll see unfamiliar methods like `#bind`, `#fmap`, `#or_fmap`. Those things require some additional learning and are not so trivial.

**There's something we never did before.** The so-called [do notation](/2018/05/27/do-notation-ruby.html) is a syntactic sugar which looks unfamiliar to Ruby developers.

**Combining different kinds of monads may be troublesome.** As an example, you may treat `Result` as a `Maybe`, which will definitely result in bugs.

**It requires extra effort to learn and adapt**. This is one of the most bitter points here. Having to learn may be annoying, and the whole process isn't easy.

Those things boil down to four points:

1. Are they really idiomatic?
2. Are they useful?
3. What trouble will they cause? Will they create bigger problems?
4. Is it difficult to learn?

I'll speak about the usefulness and problems in [My own perspective](#my-own-perspective), so let's see if it's idiomatic and/or difficult.

Let me show you a couple of examples that demonstrate many ways to use the library. Labels are collapsible — click on them to see the code.


<details markdown="1"> 
<summary>
1. <strong>Basic usage.</strong> Trying to create a record and returning a value depending on the outcome.
</summary>


```ruby
# https://github.com/saintprug/rubytalks.org/blob/cb32cff14587e021e71f0e5547765e84cd014c0d/lib/domains/talks/operations/create.rb#L43-L51

def create_talk_speaker(talk_id, speaker_id)
  talk_speaker = talks_speakers_repo.create(talk_id: talk_id, speaker_id: speaker_id)

  if talk_speaker
    Success(talk_speaker)
  else
    Failure('could not create talk_speaker')
  end
end
```
</details>

<details markdown="1"> 
<summary>
2. <strong>Composing multiple operations</strong>. A function that fetches or creates a record. It shows chaining functions using <code class="highlighter-rouge">#fmap</code> — a method which works similar to <code class="highlighter-rouge">Enumerable#map</code>, but won't do anything if it's called on a <code class="highlighter-rouge">Failure</code>
</summary>

```ruby
# https://github.com/davydovanton/cookie_box/blob/c7e92db9b69b38eb85fb9d7ef1f81706ea4830e6/lib/repositories/libs/get_or_create_repo.rb#L13-L22

def call(repo_name)
  repo_name = truncate(repo_name)
  repo = repository.find_by_name(repo_name)

  if repo
    Success(repo)
  else
    info_getter.call(repo_name).fmap { |value| create_repository(value) }
  end
end
```
</details>

<details markdown="1"> 
<summary>
3. <strong>Composing multiple operations.</strong> If one of them fails, the method will return a Failure and rollback the transaction. 
</summary>

```ruby
# https://github.com/saintprug/rubytalks.org/blob/cb32cff14587e021e71f0e5547765e84cd014c0d/lib/domains/talks/operations/create.rb#L17-L28

def call(talk_form) # rubocop:disable Metrics/AbcSize
  talk_form = talk_form.symbolize_keys
  oembed = yield generate_oembed(talk_form[:link])

  talk_repo.transaction do
    speakers = yield find_or_create_speakers(talk_form[:speakers])
    event = yield find_or_create_event(talk_form[:event])
    talk = yield event ? create_talk(talk_form, oembed, event.id) : create_talk(talk_form, oembed)
    yield create_talk_speakers(talk.id, speakers)
    Success(talk)
  end
end
```
</details>

<details markdown="1"> 
<summary>
4. <strong>Working with the computed result.</strong> Using <code class="highlighter-rouge">if</code> with predicates to handle different cases
</summary>

```ruby
# https://github.com/saintprug/rubytalks.org/blob/fe0a6f2c08f161e9bde9545227be6db5e1346539/lib/util/web/helpers/respond_with.rb#L9-L16

def respond_with(response, result, serializer, status: 200)
  if result.success?
    respond_with_success(response, result.value!, with: serializer, status: status)
  else
    status = fetch_error(result.failure)[:status]
    respond_with_failure(response, result.failure, status: status)
  end
end
```

</details>

<details markdown="1"> 
<summary>
5. <strong>Working with the computed result.</strong> Using <code class="highlighter-rouge">case</code> to handle all cases
</summary>


```ruby
# https://github.com/saintprug/retro-board/blob/b66a26a36cfc5ccfe8263fe0af31b3610ce2a896/apps/web/controllers/boards/show.rb#L10-L19

include Dry::Monads::Result::Mixin

def call(params)
  result = operation.call(params.to_h.slice(:id))

  case result
  when Success { |value| value.is_a?(Board) }
    @board = result.value!
  else
    halt 404, "These aren't the boards you're looking for"
  end
end
```
</details>

<details markdown="1"> 
<summary>
6. <strong>Working with the computed result.</strong> Using <code class="highlighter-rouge">#fmap</code> to access the wrapped data
</summary>

```ruby
# https://github.com/davydovanton/cookie_box/blob/c7e92db9b69b38eb85fb9d7ef1f81706ea4830e6/apps/web/controllers/decks/show.rb#L10-L17

def call(params)
  operation.call(params[:id]).fmap do |payload|
    @deck = payload[:deck]
    @issues = payload[:issues]
  end

  status 404, 'Not found' unless abilities['deck.read'].call(current_account, @deck)
end
```
</details>

<details markdown="1"> 
<summary>
7. <strong>Working with the computed result.</strong> Using pattern matching.
</summary>

```ruby
# a modification of example five, taken from saintprug/retro-board
# it shows a more "modern" syntax for include
# https://github.com/saintprug/retro-board/blob/b66a26a36cfc5ccfe8263fe0af31b3610ce2a896/apps/web/controllers/boards/show.rb#L10-L19

include Dry::Monads[:result]

def call(params)
  case operation.call(params.to_h.slice(:id))
  in Success(Board => board)
    @board = board
  else
    halt 404, "These aren't the boards you're looking for"
  end
end
```
</details>


Here's a couple of things to notice about those code styles:

**They use blocks more often.** The interfaces use blocks or allow them. Longer chains become a norm, which goes against [current Rubocop defaults](https://rubocop.readthedocs.io/en/latest/cops_style/#stylemultilineblockchain).

**There's no need for unnecessary naming.** Since there's an option to easily chain transformations using `#fmap` and other methods, we can avoid coming up with names we _don't really need_. I often feel frustrated about having to come up with names for intermediate data..

**We don't build objects using `#new`.** Instead, we use constructors that look like `Kernel#Array`, `Kernel#String` and similar methods. It looks pretty much like the standard Ruby code.

**We cherry-pick abstractions we need.** This helps prevent clutter and communicate more clearly. It looks boilerplaty, so folks move the includes to base classes.

**We can cherry-pick using a single `include`.** It's not a new pattern, but an uncommon one. Instead of using `include` multiple times to get each abstraction, we list whatever we need: `[:result, :maybe, :try]`.

**Conditional logic uses predicates.** Nobody really reinvents the wheel, so if you need to add conditional logic — you've still got conditions and methods to check _which_ value you've got.

**There's an extensive support for case and pattern matching.** It enables us to avoid using many built-in interfaces altogether and write expressive and beautiful code. There aren't too many examples, as the features are relatively new. If you've got something to share, please do!

**The library introduces new semantics to `yield`.** Conventionally, we use `yield` whenever we want to call a block. That's exactly what's going on here — we call a block. However, we bring the new semantics. Now, `yield` looks more like `await` in many languages, or similar to `yield` in Python or JavaScript. 

**The “functional” programming part is barely noticeable**. None of those examples show us any mathematics-riddled word-buzzing functional programming some people expected to. Sure, it has _some_ features: naming, using blocks, immutable expressions. That's pretty common in Ruby.

In the end, is it idiomatic? I think so. It may be _unfamiliar_ to many developers, but it's idiomatic almost all the way through. Except for the `yield` expression, perhaps. After all, idiomatic just means following the conventions of the language. 


## What about exceptions?

We use `Result` to express the logic which may fail or not. Let's imagine a simple use-case: user tries to log in and fills in their username/password combination. Here's how we would handle it:

1. We make sure that user has provided username and password. If not, we fail
2. We make sure the username exists in our system. If not, we fail and suggest them to register
3. We make sure the password is correct. 
  * If not, we try to check if it is one of the user's old passwords. If so, fail and tell them they've changed passwords a while ago.
  * If it's just an unknown password, fail and tell them the password is incorrect.
4. Make sure the user is not blocked in our system. Fail and warn them about it if they are
5. Create new session

This is a common, yet complex example. It consists of multiple steps and has six outcomes: five unsuccessful and one successful. 

A lot of programmers would design this process using exceptions. They'd create five exception classes and just `raise` them on demand. The higher-level code would have to `rescue` them and handle as necessary. 

`Result` is an alternative approach to this design. It suggests that you return a `Success` or a `Failure` with whatever data you need. The higher-level code would have to handle it using whatever technique they want – usually it's a combination of Result's built in methods and some `if`, `case` and `case in` calls. 

Which way to choose is actually a matter of preference. How does your code make decisions? Do you need performance? Should we treat those errors like we treat out of memory and HTTP errors? Are errors data? What approach suits you better? We can't answer all of those questions rationally. Trust me, I've tried.

Sure, there are differences and similarities of the two techniques that might help us make a more informed decision. However, they deserve their own article. I'm working on it, so I'm going to just cut it short:

> Exceptions are not an adequate replacement for Result, nor is Result an adequate replacement for exceptions. At least in Ruby

Those things serve different purpose:

1. Result is a way to express your _data_
2. Exceptions are a control flow mechanism

You may replace one with another, but it _might_ be better for them to coexist. 

Remember I said about Rust, Kotlin, Swift, F#, OCaml/ReasonML, Haskell and Elm? Some of them have _both_ Result and exceptions. I encourage you to take a look at how those two ideas coexist in those languages and learn from it. Perhaps, it could bring your Ruby code to the next level.

## My own perspective

I'm a fan of simple, yet efficient designs. Life is harder than that, so I have to deal with complex designs most of the time. 

When I'm dealing with something complex, I want to work with things that don't confuse me. Yet, I'm ready to learn something new, especially if it's something fundamental. 

I'm a domain-driven design enthusiast. I'm always looking for better ways to communicate my intentions via code as clearly as possible. Monads help me with this – they make my intentions clear. 

In [What is a monad](#what-is-a-monad) I've listed four different monads and their purpose. In my business logic,  They help me answer the main question: "what's going on here?". I `return Success(...)` when everything is good, I `Try` to run some code which may fail with an error, I perform an asynchronous `Task`, and I will `Maybe` get a value when I query the database. 

Sure, I can pretend I'm writing Haskell and write code that's hard to read even for someone who's experienced with monads. It's always up to me.

I've been using monads since May/June 2016, and they've become as natural as `if`, `Array` and other built-in parts of the language. The learning curve was not that steep, but it took me over two years of mindless usage to somewhat _understand_ them. I was using them blindly – just returning `Result` and `Maybe` from functions and using whatever methods they provided. I want to emphasize that you can get at least _that_ long without needing to read about category theory.

If you're still skeptical about "having to learn" it, stay with me. There's a website called "F# for fun and profit", which is a source of many delightful resources on functional programming. Even though the `Result` monad is a crucial part of many concepts described there, the word "monad" is actually [banned from this site](https://fsharpforfunandprofit.com/about/#banned). 

There's a problem with a lot of monad tutorials, including mine — they focus on maths instead of the practical application. This make us sound and act like we're enlightened, like we've just had a revelation. We're trying to speak about it because _now we get it_. Regular folks don't get it and think we're some kind of a cult.

In reality, monads are just simple building blocks. They're a nice addition to your toolset, but you don't need to _know_ that they are monads. It's not important in the grand scheme of things — they only enable you to build greater things, like [railway oriented programming](https://fsharpforfunandprofit.com/rop/).

Another example of a better naming for monads is Python's [returns](https://returns.readthedocs.io/), which was heavily inspired by Ruby's dry-monads. They don't use the name monad anywhere. It's just a library of _primitives_ to write _business logic_. Nothing about endofunctors and category theory – that's what I love about them.

Monads sound scary and off-putting. They're not that scary, and there's nothing special about them. They just let us do greater things. Let's move on and talk about that.


# How do I persuade my team to use monads

I had to answer it for the first time when [Janko](https://github.com/janko) approached me after EuRuKo 2018 to talk about it. I had no idea back then. It's safe to say that I've learned something and can now speak about it.

When people speak about introducing monads, they usually speak about using Result to organize domain logic. I'm going to focus on that.

Here's the thing:

> Monads are not the goal. Think bigger

As you might have read in [What is a monad](#what-is-a-monad), monads are just primitive tools that let you express something. Do you _really_ want to get stuck on such details? I thought I did. 

However, just using this piece of tech without seeing a _bigger picture_ will likely be fruitless or even frustrating. Please, don't follow this path unless you have the authority to _just do it_. You wouldn't have needed this article in this case though, would you?

Let's try and see the bigger picture here. What exactly are you trying to solve? 

* Are you stuck with plain old fat models / fat controllers? 
* Are you struggling with exceptions in domain logic?
* Do you need better performance than exceptions give you? 
* Do you want to introduce [railway-oriented programming](https://fsharpforfunandprofit.com/rop/)?
* Are you frustrated with your current interactor / use case / service object implementation?
* Do you just want to bring something new to your project to make it more appealing?
* Do you want your development team to get out of their comfort zone and persuade them to learn something new?

Once you've answered those questions _honestly_, we can move on to the next question.

> What larger problems does it solve?

Please take your time to carefully assess the problems your project and business is facing. Talk to your peers, people from other departments and upper management. Talk about their problems, what they'd love to see and _maybe_ you'll find out that you've got the solution. Perhaps not a solution but a part of it. 

Lots of things are easier when you've got allies
{: .notice--info }

Once you've done those steps, you should have enough evidence that your project needs some change. It may seem like monads are the only solution. Trust me, they're not.

> What are the alternatives? How good would they fit your situation?

Perhaps, you'd be better off with things like [Interactor](https://github.com/collectiveidea/interactor/), [ActiveInteractor](https://github.com/aaronmallen/activeinteractor). They let you implement the same things you could with Result, but in a little different fashion. 

If you're already using Interactor or ActiveInteractor, you might just patch the Context class to make it behave like a Result
{: .notice--info }

If you're thinking about something greater, you might consider other kinds of architecture or even something like [Eventide](https://eventide-project.org/). In this case, you'll probably have to plan out the great refactoring, plan it out and try and push the idea. I'm in no position to give advice here, as it's a pretty complex task and I can't generalize it.

If you're still looking for a way to organize domain logic, you'll have to learn and teach. Best way to learn is to practise: build a couple of tiny playgrounds. Try using `Result` to organize the domain logic. Speak about it on [dry-rb chat](https://dry-rb.zulipchat.com). 

Once you've learned enough to hold a conversation, gradually introduce your team to the new approaches. It works well if you have a designated space for sharing knowledge – talks, articles, tutorials, etc. If you don't, you might as well just create one. It's a nice improvement to your _engineering culture_.


# The answer

I've covered a lot of ideas in a way that looks like a rant, but haven't gotten to the main point: "should I _really_ use monads?". Here's the answer:

> **It depends**. <br />
> Will they help you do greater things? Then the answer is yes. <br />
> Do they seem off-putting and less enjoyable than other things? The answer would be "no".

It's okay if you haven't understood the new tool yet. It's also okay if you didn't like it. 

Here's the thing: the question is actually more of a _stylistic_ preference than something substantial. Decision to use a monad or not is a lot like the decision to use `if` instead of `case`, or `collect` instead of `reduce`. Just like pattern matching lets you express yourself, each monad contributes to expressiveness to your code. 

Use whatever suits you better. Yet, be open-minded.

# Links and references

* [dry-monads](https://dry-rb.org/gems/dry-monads/)
* [dry-rb chat](https://dry-rb.zulipchat.com)
* [Eventide](https://eventide-project.org/)
* [F# for fun and profit](https://fsharpforfunandprofit.com/)
* [Railway oriented programming](https://fsharpforfunandprofit.com/rop/)
* [Vasily Kolesnikov's asynchronous file downloader](https://gist.github.com/v-kolesnikov/c5807aab0ac7ba5d1ba5e31be32e21e6)
* [ActiveInteractor](https://github.com/aaronmallen/activeinteractor)
* [Interactor](https://github.com/collectiveidea/interactor/)
* [Concurrent ruby](https://github.com/ruby-concurrency/concurrent-ruby)
* [returns: monads in Python](https://returns.readthedocs.io/)
* [Vitaly Pushkar's article on Error handling with Monads in Ruby](http://nywkap.com/programming/either-monads-ruby.html)
* [My own article on Do notation and railway oriented programming](/2018/05/27/do-notation-ruby.html)
* [My own article on monad laws](/2018/09/08/monad-laws-in-ruby.html)
* [rubytalks.org repo](https://github.com/saintprug/rubytalks.org)
* [Anton Davydov's cookie box repo](https://github.com/davydovanton/cookie_box/)
* [Saint P Ruby's retro board](https://github.com/saintprug/retro-board/)
