# Проверка первого OpenSpec change

Дата: 2026-11-05. Среда: macOS, Swift 6.2.3 Command Line Tools. Xcode.app и iOS Simulator не установлены.

## Выполнено

- `cd ios && swift test -j 1` — 9 Swift Testing тестов прошли. Покрыты инвариант оригинала, миграция/повторное открытие, пустой текст, идемпотентный capture ID, целостность вложения, очистка осиротевшего файла, группы, FTS5, исправление и удаление, ошибка OCR и реальное локальное распознавание Vision на созданном тестом изображении. Первый вызов Vision занял около 52 секунд.
- При компиляции Swift Testing из отдельного пакета Command Line Tools печатает `Internal Error: DecodingError.dataCorrupted` для macro plugin, но команда завершилась с кодом 0 и все 9 тестов выполнились. Проверку на полном Xcode следует повторить.
- `cd ios && xcodegen generate --spec project.yml` — `Kstati.xcodeproj` создан.
- `npx -y @fission-ai/openspec@1.16.0 validate establish-offline-memory-foundation --strict` — change валиден.

## Не проверено в этой среде

- `xcodebuild -list -project ios/Kstati.xcodeproj` — завершился ошибкой `tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance`.
- Сборка app, Share Extension и UI tests для iOS Simulator, передача скриншота из другого приложения без сети, состояние после перезапуска и сообщение об ошибке записи в расширении. Нужен установленный Xcode с iOS Simulator.

После установки Xcode выполнить из корня репозитория:

```sh
cd ios
xcodegen generate --spec project.yml
xcodebuild -list -project Kstati.xcodeproj
xcodebuild -project Kstati.xcodeproj -scheme Kstati -destination 'platform=iOS Simulator,name=iPhone 16' build test
```

Для ручной проверки: отключить сеть в симуляторе, поделиться скриншотом в «Кстати», открыть запись, дождаться OCR, исправить текст, найти его поиском, открыть оригинал и повторить после перезапуска. Если App Group недоступна или запись невозможна, расширение должно показать ошибку и не закрыться с подтверждением.
