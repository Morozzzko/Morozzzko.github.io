---
layout: single
title: "dry-rb 1.0: upgrading validations, types and schemas"
date: "2019-05-31 09:48:00 +0300"
header:
  og_image: "/assets/images/previews/upgrading_dry_gems.png"
---

I'm enthusiastic about [dry-rb gems](https://dry-rb.org/). Actually, I've never worked on Ruby projects without a dry-rb gem. However, some people are sceptical, as a lot of core dry-rb gems are still in their `0.x` phase, which leads to a lot of breaking changes and hours of refactoring.

I'm happy to see dry-rb mature: dry-monads entered 1.0 phase in Summer 2018, and now [two more libraries](https://dry-rb.org/news/2019/04/23/dry-types-and-dry-struct-1-0-0-released/) hit v1.0 milestones: dry-types and dry-struct; and dry-validation is in its 1.0 RC phase.

I haven't updated my dry-rb gems for a couple of months, so I've missed a lot of breaking changes. Finally, I decided to upgrade the gems and write about the process. I'll take a swing at _automating_ my upgrade process as much as I can.

<!-- excerpt -->

## Prerequisites

Here's what my dry-rb gems look like:

```
$ bundle list | grep dry
  * dry-auto_inject (0.4.6)
  * dry-configurable (0.7.0)
  * dry-container (0.6.0)
  * dry-core (0.4.7)
  * dry-equalizer (0.2.1)
  * dry-events (0.1.0)
  * dry-inflector (0.1.2)
  * dry-initializer (2.5.0)
  * dry-logic (0.4.2)
  * dry-matcher (0.7.0)
  * dry-monads (1.2.0)
  * dry-struct (0.6.0)
  * dry-transaction (0.13.0)
  * dry-types (0.13.2)
  * dry-validation (0.12.1)
```

I've got 15 gems, but I only care about four of them: monads, types, struct and validation. Since monads are up-to-date, I'm only going to talk about types, struct and validation.

In this post, I'll try to give a step-by-step guide that will _simplify_ the upgrading process. It won't give a 100% working solutions, but it will probably save you a couple of hours.

**Note**. I use macOS with GNU sed (`gsed`) instead of built-in `sed` command. So if you want to follow my instructions, install it via `brew install gnu-sed`. Since I'm using [fish](https://fishshell.com/) instead of `bash` / `zsh`, some commands might need slight modifications to work.

**Note**. I wrote this article while upgrading the dry-rb gems on my project. I decided to do it gradually — so you might encounter some redundant steps. If you do, please contact me via email and I'll upgrade it.

## dry-validation to dry-schema

The gem we knew as `dry-validation` has evolved from a complex schema validation & coercion into a high-level contract DSL with domain logic.

Meanwhile, it has become so complex they decided to break it down into two gems: dry-validation and [dry-schema](https://solnic.codes/2019/01/31/introducing-dry-schema/). The latter provides the old functionality of `dry-validation` — the schema validations, coercions, and they fixed _all_ known issues. `dry-validation` adds domain rules and validations on top of that.

I don't want to go around and update everything manually, so I'm going to replace `dry-validation` with `dry-schema` as much as I can, and manually refactor the rest.

**Step 1**. Upgrade dry-validation to `0.13`. It's the last version before the switch, so if your builds pass — you're good to go. You'll have to update dry-types to `0.14` too.

**Step 2**. Replace dry-validation with equivalent dry-schema version (0.1.0) and replace all `Dry::Validation` occurrences with `Dry::Schema`. Also replace all `Dry::Validation.Schema` with `Dry::Validation.define`.

```
$ bundle remove dry-validation && bundle add dry-schema --version 0.1.0`
$ grep -rl 'Dry::Validation' ./**/*.rb | xargs gsed -i 's/Dry::Validation/Dry::Schema/g'
$ grep -rl 'Dry::Schema.Schema' ./**/*.rb | xargs gsed -i 's/Dry::Schema.Schema/Dry::Schema.define/g'
```

If you've used [struct extension](https://dry-rb.org/gems/dry-validation/extensions/struct/), don't forget to search for `Dry::Schema.load_extensions` and remove `:struct` from the list.

**Step 3**. Replace `.each(&:type?)` predicates with `.each(:type?)`. The same goes for `maybe`, `filled` and `value`. You might get `ArgumentError: no receiver given` if you don't.

```
$ grep -rl 'Schema' ./**/*.rb | xargs gsed -i 's/\.\(filled\|value\|each\|maybe\)(&/.\1(/g'
```

**Step 4**. Refactor schemas that use [arrays as input](https://dry-rb.org/gems/dry-validation/0.13/array-as-input/).

The feature has been removed and it's not coming back until dry-schema 1.0. Here's [an issue](https://github.com/dry-rb/dry-schema/issues/22) with the feature.

The refactoring will look like this:

```ruby
# Before

ItemSchema = Dry::Schema.Params do
  each do
    schema do
      required(item_id).filled(:int?)
      required(option_ids).each(:int?)
    end
  end
end

ItemSchema.call(input)

# After

ItemSchema = Dry::Schema.Params do
  required(:input).each do
    schema do
      required(:item_id).filled(:int?)
      required(:option_ids).each(:int?)
    end
  end
end


ItemSchema.call(input: input)
```

**Step 5**. Check you've ever inherited from `Dry::Validation` schemas. If you did, do the following transformations:

1. Rename classes

- `Dry::Validation::Schema::Params` → `Dry::Schema::Params`
- `Dry::Validation::Schema::JSON` → `Dry::Schema::JSON`
- `Dry::Validation::Schema` → `Dry::Schema`

2. Replace `define!` block with `define`
3. Move `configure` block under `define`

```ruby

# Before:

class ApplicationSchema < Dry::Validation::Schema::Params
  configure do
    config.messages = :i18n
  end
end

# After:

class ApplicationSchema < Dry::Schema::Params
  define do
    config.messages = :i18n
  end
end
```

And update its subclasses:

```ruby
# Before

class MySchema < ApplicationSchema
  configure do
    config.messages = :yaml
  end

  define! do
    ...
    # your params go here
  end
end

# After

class MySchema < ApplicationSchema
  define do
    config.messages = :yaml

    ...
    # your params go here
  end
end
```

**Step 6**. Update DSL inheritance.

Replace `Dry::Schema.Params(BaseClass)` with `Dry::Schema.Params(parent: BaseClass)`.

```
$ grep -rl 'Schema' ./**/*.rb | xargs gsed -i 's/Dry::Schema\(\(::\)\|\.\)\(Params\|JSON\|Schema\)(\([[:alnum:]]*\))/Dry::Schema\1\3(parent: \4)/g'
```

**Before you proceed** Skip steps 7 and 8 if you've never used [type specs API](https://dry-rb.org/gems/dry-validation/0.13/type-specs/).

**Step 7**. Remove `config.type_specs` from your schemas

```
$ grep -rl 'config.type_specs' ./**/*.rb | xargs gsed -i '/config\.type_specs/d'
```

**Step 8**. Remove type spec usages from `required` and `optional`.

```
$ grep -rl 'Schema' ./**/*.rb | xargs gsed -i 's/\(required\|optional\)(\(:[[:alnum:]_]*\), [[:print:]]*)\(\.\|$\)/\1(\2)\3/g'
```

## Updating dry-schema to 0.3

**Step 9**. Update your gemfile to specify `gem 'dry-schema', '~> 0.3.0'` and run `bundle install`

**Step 10**. If you're using I18n, move `errors` under `dry_schema` namespace. This way,

```yaml
en:
  errors:
    array?: must be an array
```

will turn into

```yaml
en:
  dry_schema:
    errors:
      array?: must be an array
```

**Step 11**. Find any `schema` macro usages and replace them with `hash`, as `schema` no longer prepends `value(:hash?)` check.

```ruby
# Before

required(:foo).schema do
end

# After

required(:foo).hash do
end
```

```
$ grep -rl 'Schema' ./**/*.rb | xargs gsed -i 's/schema \(do\|{\)/hash \1/g'
```

**Step 12**. Find any `each` macro usages and replace them with `array` to add type check. Since Ruby has a `Enumerable#each` function, we can't automate it, but we can still find possible occurrences:

```
$ grep -rl 'Schema' ./**/*.rb | xargs grep -n 'each \(do\|{\)'
```

Feel free to skip if you feel like you don't need type checks.

**Step 13**. Load [hints extension](https://dry-rb.org/gems/dry-schema/extensions/hints/) if you use monads or `.messages`.

```ruby
Dry::Schema.load_extensions(:hints)
```

## The leap towards 1.0.0

**Step 14**. Update dry-struct, dry-types and dry-schema and run `bundle install`.

```ruby
gem 'dry-schema', '~> 1.1.0'
gem 'dry-struct', '~> 1.0.0'
gem 'dry-types', '~> 1.0.0'
```

**Step 15**. Replace `Dry::Types.module` with `Dry.Types(default: :nominal)`

If you've never used nominal types (i.e. `Types::Hash`, `Types::Integer`), feel free to use `Dry.Types` instead.

```
$ gsed -i 's/Dry::Types\.module/Dry.Types(default: :nominal)/g' ./**/*.rb
```

**Step 16**. Replace legacy hash schemas with new ones. See https://dry-rb.org/gems/dry-types/0.15/hash-schemas/

**Step 17**. Update error message config

1. Replace `config.messages` with `config.messages.backend`
2. Replace `config.messages_file = '/path/to/my/errors.yml'` with `config.messages.load_paths << '/path/to/my/errors.yml'`
3. Replace `config.namespace = :user` with `config.messages.namespace = :user`

```
$ grep -rl 'Schema' ./**/*.rb | xargs gsed -i 's/config\.messages =/config.messages.backend =/g'
$ grep -rl 'Schema' ./**/*.rb | xargs gsed -i 's/config\.messages_file =/config.messages.load_paths <</g'
$ grep -rl 'Schema' ./**/*.rb | xargs gsed -i 's/config\.namespace =/config.messages.namespace =/g'
```

**Step 18**. Symbolize all string keys

```
$ grep -rl 'Schema' ./**/*.rb | xargs gsed -i 's/\(required\|optional\)(\(\'\|"\)\([[:alnum:]_]*\)\(\'\|"\)/\1(:\3/g'
```

**Step 19**. Replace `Types.Definition` with `Types.Nominal`

```
$ gsed -i 's/Types\.Definition/Types.Nominal/' ./**/*.rb
```

**Step 20**. If you rely on `Types::Params` and `Types::JSON` not to raise an exception on invalid input, decorate the definitions with `.lax`

```
$ gsed -i 's/Types::JSON::\([[:alnum:]]*\)/Types::JSON::\1.lax/g' ./**/*.rb
$ gsed -i 's/Types::Params::\([[:alnum:]]*\)/Types::Params::\1.lax/g' ./**/*.rb
```

**Step 21**. Replace `:type?` predicates with type checks wherever you need this

```
$ grep -rl 'Schema' ./**/*.rb | xargs gsed -i 's/\(filled\|maybe\|value\)(:str?/\1(:string/g'
$ grep -rl 'Schema' ./**/*.rb | xargs gsed -i 's/\(filled\|maybe\|value\)(:int?/\1(:integer/g'
$ grep -rl 'Schema' ./**/*.rb | xargs gsed -i 's/\(filled\|maybe\|value\)(:date?/\1(:date/g'
```

**Step 22**. `Result#{messages, errors, hints}` now return `MessageSet`, which can be converted to `Hash`. So we need to go and update the usages _everywhere_. Also `Result#to_monad` now wraps entire `Result` object, so we have to update our code.

```ruby
# Before

render errors: Schema.call(params).errors
render errors: Schema.call(params).to_monad.failure

# After

render errors: Schema.call(params).errors.to_h
render errors: Schema.call(params).to_monad.failure.errors.to_h
```

I've used the scripts to help me look and trace those values:

```
$ grep -rl 'Schema' ./**/*.rb | xargs grep -n '\.messages'
$ grep -rl 'Schema' ./**/*.rb | xargs grep -n '\.errors'
$ grep -rl 'Schema' ./**/*.rb | xargs grep -n '\.to_monad'
$ grep -rl 'Schema' ./**/*.rb | xargs grep -n '\.failure'
$ grep -rl 'Schema' ./**/*.rb | xargs grep -n '\.value_or'
$ grep -rl 'Schema' ./**/*.rb | xargs grep -n '\.value!'
```

## Refactoring to dry-validation

The steps above should be good enough to update most of the features, but if you 've ever used [high-level rules](https://dry-rb.org/gems/dry-validation/0.13/high-level-rules/), [validation blocks](https://dry-rb.org/gems/dry-validation/0.13/custom-validation-blocks/), you have two options: either remove those features from your schemas, or use dry-validation 1.0. I decided to refactor most of my schemas, that's what came out of it.

There are things to keep in mind during the update:

- `dry-validation` is a library to validate _domain_ logic and rules. The core concept is a `Contract`.
- All contracts must be instantiated — no more `Schema.call`. We need to use `Contract.new.call` now
- The idiomatic way to define a contract is to use standard Ruby syntax: `class Contract < Dry::Validation::Contract` as opposed to dry-schema's `Dry::Schema.Params { }`

**Step 23**. Update dependency injection. The new version uses [dry-initializer](http://dry-rb.org/gems/dry-initializer/) under the hood, so it works like this:

- use `option` for keyword arguments
- use `param` for positional arguments

You'll have to pass the arguments when you instantiate the method

```ruby
# Before

Schema = Dry::Validation.Schema do
  configure do
    option :repo
  end

  ...
end

Schema.with(repo: my_repo).call(params)

# After

class Contract < Dry::Validation::Contract
  option :repo
end

contract = Contract.new(repo: repo)
contract.call(params)
```

I used the script to find the files I need to refactor:

```
$ grep -rl 'Schema' ./**/*.rb | xargs grep -n 'option :[[:alnum:]_]*$'
```

**Step 24**. Rewrite rules and validations. I can't provide a comprehensive migration guide because I've just refactored everything and tried to make my specs pass without giving it much thought.

```ruby
# Before


class CreditCardSchema < Dry::Validation::Schema::Params
  configure do
    config.type_specs = true
  end

  define! do
    required(:number, :string).filled(format?: /\A\d{13,19}\z/)
    required(:month, :string).filled(format?: /\A(0?[1-9]|1[012])\z/)

    validate(expired: %i[year month]) do |year, month|
      Date.new("20#{year}".to_i, month.to_i).end_of_month >= Date.current
    end
  end
end

# After
class CreditCardSchema < Dry::Validation::Contract
  params do
    required(:month).filled(:string, format?: /\A(0?[1-9]|1[012])\z/)
    required(:year).filled(:string, format?: /\A\d{2}\z/)
  end

  rule(:year, :month) do
    year = values[:year]
    month = values[:month]

    if Date.new("20#{year}".to_i, month.to_i).end_of_month < Date.now
      key(:expired).failure(:expired)
      # ^ a little duplication here to produce the expected error message
      # without refactoring anything else
    end
  end
end
```

I used this script to search for all schemas that need rewriting:

```
$ grep -rl 'Schema' ./**/*.rb | xargs grep -n 'rule\|validate('
```

**Step 25** (optional). If you're using Reform, you're in for a disappointment, especially if you've been using its `dry-validation` DSL.

We have Reform 2.2.4 with ActiveModel validations, so we [forked it](https://github.com/Qlean/reform/) and removed all the dry-validation stuff. Feel free to fork and use!

**Step 26**. Fix the rest of failing specs. All done!

## Recap

The upgrade process took me about 3 work days of refactoring, and I was glad I learned basic `sed` to help me — it's annoying to do so much manual work.

However, I think the improvements are worth it. The ones I like the most:

- `dry-types` is stricter and less verbose now — if you're not including nominal types, then `Types::String` is the same as `Types::Strict::String`
- The known dry-validation bugs were fixed
- Decreased complexity of schema validations
- New library to design domain validations and contracts

I urge you to try the new dry-rb gems — and write about your experience. If you've upgraded your gems and wrote a post about your journey and update process — please send me an email and I'll add a link to your page. And of course, it would be great to see new contributions to [official docs](https://github.com/dry-rb/dry-rb.org).

## References

- [Introducing dry-schema](https://solnic.codes/2019/01/31/introducing-dry-schema/) @ solnic.codes
- [How it all started](https://discourse.dry-rb.org/t/plans-for-dry-validation-dry-schema-a-new-gem/215)
- [dry-schema](https://dry-rb.org/gems/dry-schema/)
- [dry-validation](https://dry-rb.org/gems/dry-validation/)
- [dry-types](https://dry-rb.org/gems/dry-types/1.0/)

**Update (01.06.2019)**. [flash-gordon](https://github.com/flash-gordon) pointed out that you don't need to wrap config into the `configure` block. So I've replaced

```ruby
define do
  configure do
    config.xxx = yyy
  end
end
```

with a less nested version:

```ruby

define do
  config.xxx = yyy
end
```

**Update (07.06.2019)**. [solnic](https://github.com/solnic/) pointed out that I made a typo in **Step 10**: it used to say `dry_struct` instead of `dry_schema`. I've updated the step accordingly.
