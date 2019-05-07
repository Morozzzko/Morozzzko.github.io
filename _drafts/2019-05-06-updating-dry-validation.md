---
layout: single
title: "Moving to dry-schema"
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

## Steps

Step 1. Bump dry-validation to `0.13.0` and `dry-types` to `0.14`.

Step 2. Bump dry-validation to `1.0.0.alpha1`

Step 3. See if you've ever used [struct extension](https://dry-rb.org/gems/dry-validation/extensions/struct/). Remove `Dry::Validation.load_extensions(:struct)`

Step 4. Replace `Dry::Validation.Form`, `Dry::Validation.Params`, `Dry::Validation.Schema` with `Dry::Validations
