---
revealOptions:
    transition: none
    slideNumber: 'c/t'
---

<style type="text/css">
  .hljs {
    background: transparent;
  }

  .reveal pre {
    box-shadow: none;
  }

  .reveal blockquote {
    background: transparent;
    border: none;
  }

  img {
    max-height: 600px !important;
    width: auto !important;
  }

  .green {
    color: lightgreen;
  }

  h1, h2, h3, h4, h5, h6 {
    text-transform: none !important;
  }
</style>

## Кулстори про CLI

---

## Я — Игорь

* В руби с 2016
* Писал на всяком, в основном на руби
* Не очень хорош с рельсой
* ❤️  энтерпрайзную разработку
* Делаю Bookmate.com

---

## Иногда надо делать CLI

И это бывает больно

---

## А зачем?

---

## А зачем?

* Оптимизировать рутину
* Шорткаты

---

## Шорткаты

```bash
# Было

npx reveal-md slide-sources/saint_p_lightning/index.md  \
    --static assets/slides/saint_p_meetup_2021 \
    --static-dirs=slide-sources/saint_p_lightning/img

# Стало

make slides-2021-saint-p
```

---

## Мейк — это хорошо

---

<figure>
<img src="img/makefile.png" />
<figcaption><a href="https://malefile.site">makefile.site</a></figcaption>
</figure>

---

## А что с рутиной?

* Сходи туда
* Скачай то
* Распакуй
* Переименуй
* Выстави значения

---

## Шелл скриптинг не всегда хорош

На fish хорош, а вот на (ba|z)sh не очень

---

## Альтернативы — библиотеки для CLI

* argparse
* click
* thor
* hanami-cli → dry-cli


---


## Не люблю чувствовать себя тупым

Самое важное требование к библиотекам

---

## Тор не помогает

```ruby
class MyCLI < Thor
  desc "hello NAME", "say hello to NAME"
  def hello(name)
    puts "Hello #{name}"
  end
end

MyCLI.start(ARGV)
```

---

## method_defined — хорошо

Но не очень просто

---

## А как тестить?

Очевидно: запускать и смотреть на stdout
Не очень очевидно: запускать через rspec/minitest и тоже тестить

---

## dry-cli: теперь проще


```ruby
module MyCLI
  extend Dry::CLI::Registry

  class Hello < Dry::CLI::Command
    desc "say hello to NAME"
    argument :name

    def call(name:, **)
      puts "Hello #{name}"
    end
  end

  register 'hello', Hello
end

Dry::CLI.new(MyCLI).call
```

---

## Больше текста, проще кот

Your mileage may vary, though

---

## А ещё там меньше интеграций

Спросить у пользователя ввести что-нибудь? Ставь tty-shell

Нужны цвета? Ставь tty-color

---

# Спасибо

* https://dry-rb.org/gems/dry-cli/
* https://makefile.site
* http://whatisthor.com/

