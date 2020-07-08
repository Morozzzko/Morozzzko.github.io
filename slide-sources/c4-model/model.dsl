workspace "Baqers" "Заказ выпечки онлайн" {
  model {
    user = person "Пользователь" "Хочет булочки с корицей"

    rollbar = softwareSystem "Rollbar" "Трекинг ошибок"

    enterprise "ООО Рога и Копыта (Baqers)" {

      billing = softwareSystem "Биллинг" "занимается обработкой платежей" {
        billingDb = container "База данных" "" "PostgreSQL"
      }

      billing -> rollbar "Шлёт информацию об ошибках"

      baqers = softwareSystem "Baqers" "Система для размещения и обработки заказов" {
        baqerDb = container "База данных" "" "PostgreSQL"
        app = container "Android приложение" "" "Kotlin"
        monolith = container "Бэкенд" "Монолит" "Ruby: roda / rom / dry" {
          billingBC = component "Billing" "" "Связанный контекст"
          orders = component "Orders" "" "Связанный контекст"
          api = component "API" "" "Приложение"
          admin = component "Админка" "" "Приложение"
        }
        user -> app "Пользуется приложением чтобы размещать заказы"

        monolith -> baqerDb "Использует" "sequel"
        monolith -> rollbar "Шлёт информацию об ошибках"
        app -> api "Ходит в API" "OkHttp"
        api -> orders
        orders -> billingBC

        admin -> billingBC "Берет информацию о платежах"
        admin -> orders "Отображает информацию о заказах"
      }

      billingBC -> billing "Делегирует управление платежами" "HTTP API"
    }
  }

  views {
    systemLandscape {
      include *
      autoLayout lr
    }

    systemContext baqers {
      include *
      autoLayout lr
    }

    container baqers {
      include *
      autoLayout lr
    }

    component monolith {
      include *
      autoLayout lr
    }

    styles {
      element "Software System" {
        fontSize 32
        shape roundedBox
        background #1168bd
        color #ffffff
      }
      element Component {
        fontSize 32
        shape roundedBox
        background #85bbf0
        color #ffffff
      }
      element Container {
        fontSize 32
        shape roundedBox
        background #438dd5
        color #ffffff
      }
      element Enterprise {
        fontSize 32
      }

      relationship Relationship {
        fontSize 32
      }

      element Person {
        shape person
        fontSize 32
        background #08427b
        color #ffffff
      }
    }
  }
}
