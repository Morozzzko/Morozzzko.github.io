# Securing remote file uploads with Shrine

What to say:

* We upload files using Shrine
* We get pre-signed URL and upload our files somewhere
* Uploader is easy to abuse
* How to perform authentication

======

I've been using Shrine since summer 2016 when I worked at [Planado](https://planadoapp.com).
We had a Rails 4 application with a  decently complex codebase, and we were
just starting our migration from Rails. During the migration, we switched
from ActiveRecord to ROM, from Rails controllers to Roda, and from CarrierWave
to Shrine.

When I replaced old CarrierWave code with Shrine, I fell in love with the
library's design: it was minimalistic, yet powerful. It was easy to implement
simple things, and it was not painfully difficult to implement complex ones.

In this article, I'd like to talk about one of the greatest built-in features
of Shrine: direct file uploads to Amazon S3. There's a list of articles
which explain how direct uploads work with and without Shrine:

* With shrine
* Other with shrine
* Without shrine

In a comment to the INSERT ARTICLE HERE on Reddit, /u/Someone mentioned
their concern: endpoints in those articles do not handle any authentication or
authorization, which means that anyone can store their files and you will pay
for it. I want to address it and build a secure file uploader.

## Prerequisites

Here's the setup I used for the task:

* Rails 5.0.7
* Shrine 2.12.0
* fog-aws 3.0.0

## Creating the endpoint

First, we have to install Shrine and shrine-fog:

```ruby
gem 'shrine', '~> 2.0'
gem 'shrine-fog'
```

Then, we create a file `app/uploaders/file_uploader.rb`

```ruby
class FileUploader < Shrine
  plugin :presign_endpoint # <= to allow us to presign
end
```

```ruby
Application.routes.draw do
  # ...
  mount FileUploader.presign_endpoint(:cache) => '/files/upload_url'
  # ...
end
```
