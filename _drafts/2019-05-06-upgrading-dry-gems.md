---
layout: single
title: "Updaring dry-rb gems: validations and types"
date: "2019-05-06 23:02:00 +0300"
---

I'm enthusiastic about [dry-rb gems](https://dry-rb.org/). Actually, I've never worked on Ruby projects without a dry-rb gem. However, some people are sceptical about them, as a lot of core dry-rb gems are still in their `0.x` phase, which leads to a lot of breaking changes and eventual bugs.

I'm happy to see dry-rb mature: dry-monads entered 1.0 phase in Summer 2018, and now [two more libraries](https://dry-rb.org/news/2019/04/23/dry-types-and-dry-struct-1-0-0-released/) hit v1.0 milestones: dry-types and dry-struct; and dry-validation is in its 1.0 RC phase.

I haven't updated my dry-rb gems for a couple of months, so I've missed a lot of breaking changes in various gems. So I decided to upgrade the gems and write about the new changes.

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

The upgrade is not going to be easy as there are two issues with the gems:

1. What used to be `dry-validation` is now `dry-schema`, so I have to switch gems
2. `dry-validation`, `dry-schema` and `dry-struct` all depend on `dry-types`, so I can't just bump the version and expect it to work

I'll keep that in mind and try and deliver working updates.

## dry-validation to dry-schema

The gem we knew as `dry-validation` has evolved from a complex schema validation & coercion to a high-level contracts DSL with complex domain logic.

Meanwhile, it has become so complex they decided to break it down into two gems: dry-validation and [dry-schema](https://solnic.codes/2019/01/31/introducing-dry-schema/). The latter provides the old functionality of `dry-validation` — all the schema validations, coercions, and they fixed _all_ known issues. So, essentially, all I need is to switch to dry-schema and update it.

Here's the list of atomic steps: you can deploy your application after each. FIXME: it's probably false, step 2 is getting TOO MASSIVE

**Step 1**. Upgrade dry-validation to `0.13`. It's the last version before the switch, so if your builds pass — you're good to go. You'll have to update dry-types to `0.14` too.

**Step 2**. Replace dry-validation with equivalent dry-schema version (0.1.0) and replace all `Dry::Validation` ocurrences with `Dry::Schema`. Also replace all `Dry::Validation.Schema` with `Dry::Validation.define`.

```
$ bundle remove dry-validation && bundle add dry-schema --version 0.1.0`
$ grep -rl 'Dry::Validation' ./**/*.rb | xargs gsed -i 's/Dry::Validation/Dry::Schema/g'
$ grep -rl 'Dry::Schema.Schema' ./**/*.rb | xargs gsed -i 's/Dry::Schema.Schema/Dry::Schema.define/g'
```

If you've used [struct extension](https://dry-rb.org/gems/dry-validation/extensions/struct/), don't forget to search for `Dry::Schema.load_extensions` and remove `:struct` from the list.

Don't forget to check if you've ever inherited from `Dry::Validation::Schema` and its subclasses. This may break your code

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

# TODO: update line numbers

**Before you proceed** Skip steps 5 and 6 if you've never used [type specs API](https://dry-rb.org/gems/dry-validation/type-specs/).

**Step 5**. Remove `config.type_specs` from your schemas

```
$ grep -rl 'config.type_specs' ./**/*.rb | xargs gsed -i '/config\.type_specs/d'
```

**Step 6**. Remove type spec usages from `required` and `optional`.

```
$ grep -rl 'Schema' ./**/*.rb | xargs gsed -n 's/\(required\|optional\)(\(:[[:alnum:]_]*\), [[:print:]]*)\./\1(\2)./p'
```

## Updating dry-schema

**Step ???**. Update error messages config

1. Replace `config.messages` with `config.messages.backend`
2. Replace `config.messages_file = '/path/to/my/errors.yml'` with `config.messages.load_paths << '/path/to/my/errors.yml'`
3. Replace `config.namespace = :user` with `config.messages.namespace = :user`

```ruby

$ grep -rl 'Schema' ./**/*.rb | xargs gsed -i 's/config\.messages =/config.messages.backend =/g'
$ grep -rl 'Schema' ./**/*.rb | xargs gsed -i 's/config\.messages_file =/config.messages.load_paths <</g'
$ grep -rl 'Schema' ./**/*.rb | xargs gsed -i 's/config\.namespace =/config.messages.namespace =/g'
```

**Step ???**. Update dry-schema to `0.2.0`:

`$ bundle add dry-struct --version 0.2.0`

If you're using I18n, you'll have to put `errors` under `dry_struct` namespace. This way,

```yaml
en:
  errors:
    array?: must be an array
```

will turn into

```yaml
en:
  dry_struct:
    errors:
      array?: must be an array
```

```
grep -rl 'Schema' ./**/*.rb | xargs gsed -n '/[(required|optional)](:[[:alnum:]_]*)\.schema/p'
```

## TL;DR
