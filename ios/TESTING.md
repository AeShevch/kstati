# Проверка первого OpenSpec change

## Единая проверка iOS

Из корня репозитория установите закреплённые SwiftLint 0.65.1 и XcodeGen 2.46.0 без прав администратора. Установщик сверяет SHA-256 архивов и кладёт инструменты в игнорируемый каталог `.tools/`. Нужны Xcode 27.2 (`swift-format` 6.4.4), `python3`, `curl` и `unzip`. На текущем этапе GitHub CI использует runner `xcode-27`; локально нужен доступный iPhone 17e с iOS 27.2.

```sh
./scripts/install-ios-tools.sh
./scripts/ios-checks.sh fast
./scripts/ios-checks.sh smoke
./scripts/ios-checks.sh full
```

Скрипты работают и из `ios/` через `../scripts/`. `fast` проверяет Swift-формат, шесть правил SwiftLint, 11 Swift-тестов и воспроизводимость XcodeGen. `smoke` и `full` сначала выполняют `fast`, дожидаются полной загрузки симулятора, затем собирают приложение и запускают соответствующий последовательный E2E-план. Симулятор выбирается по имени и версии runtime, а не по UDID; при необходимости задайте `KSTATI_SIMULATOR_NAME` и `KSTATI_SIMULATOR_RUNTIME`. `xcresult` сохраняется в игнорируемый `.artifacts/` либо в `KSTATI_RESULT_DIR`.

На GitHub-hosted macOS runner Vision возвращает `_GenericObjCError.nilError` при распознавании сгенерированного PNG в SwiftPM-тесте. Этот один платформенный тест явно помечен как пропущенный при `CI=true`; остальные десять Swift-тестов выполняются. `Smoke` в iOS Simulator проверяет реальный OCR через Share Extension. Локально Vision-тест выполняется вместе с остальными.

Проверка 2026-11-07: `fast` из корня и `ios/` прошёл, рабочий каталог после прогона остался чистым. `smoke` — 1/1, `full` — 4/4 без пропусков; диагностические пакеты сохранены в `/tmp/kstati-quality-results/`.

GitHub PR #1: [iOS PR checks, run 42356197869](https://github.com/AeShevch/kstati/actions/runs/42356197869) — OpenSpec и actionlint прошли; формат, SwiftLint, десять Swift-тестов, сборка и `Smoke` 1/1 прошли на `xcode-27`. Один SwiftPM-тест Vision отмечен пропущенным по указанной выше причине; распознавание OCR проверено в `Smoke`.

Итоговые прогоны на коммите `4ae52ed`: [PR checks](https://github.com/AeShevch/kstati/actions/runs/42358843698) — OpenSpec, actionlint, формат, SwiftLint, десять Swift-тестов, сборка и `Smoke` 1/1 прошли; [Full E2E](https://github.com/AeShevch/kstati/actions/runs/42358843686) — `Full` 4/4 без ошибок и пропусков, включая сценарий ошибки записи. Единственный пропуск в SwiftPM — описанный выше macOS Vision-тест; тот же реальный OCR проверен в обоих UI-планах на iOS Simulator.

## Baseline перед реорганизацией iOS-кода

На 2026-11-06: Apple Swift 6.4.2, `swift-format` 6.4.4, XcodeGen 2.46.0, Xcode 27.2. SwiftPM содержит `MemoryCore`, `MemoryPersistence`, `MemoryOCR` и соответствующие test targets; `cd ios && swift test -j 1` завершился успешно: 6 + 4 + 1 = 11 тестов. `xcodebuild -list -project ios/Kstati.xcodeproj` показывает app, Share Extension, UI-test target и fixture host. Исходный UI-набор содержит `testShareImageFromAnotherApp`, `testEditKeepsOriginalAndDeletingGroupKeepsMemory`, `testManualCaptureSearchAndReopen` и условный `testShareReportsWriteFailure`; результаты предыдущего полного прогона приведены ниже.

Дата: 2026-11-06. Xcode 27.2, iOS 27.2 Simulator (iPhone 17e, `9E66650E-10CF-47C4-8FF7-D0D63B84C1BD`). Deployment target — iOS 17.0.

## Результаты

| Проверка | Команда | Результат |
| --- | --- | --- |
| OpenSpec | `npx -y @fission-ai/openspec@1.16.0 validate establish-offline-memory-foundation --strict` | Change valid |
| Swift unit/integration | `cd ios && swift test -j 1` | 11/11 тестов прошли |
| Xcode targets | `xcodebuild -list -project ios/Kstati.xcodeproj` | App, Share Extension, UI tests и fixture host доступны |
| Все targets | `xcodebuild -project ios/Kstati.xcodeproj -scheme Kstati -destination 'platform=iOS Simulator,id=9E66650E-10CF-47C4-8FF7-D0D63B84C1BD' build` | BUILD SUCCEEDED |
| UI | `xcodebuild -project ios/Kstati.xcodeproj -scheme Kstati -destination 'platform=iOS Simulator,id=9E66650E-10CF-47C4-8FF7-D0D63B84C1BD' test` | 3 сценария прошли, условный тест ошибки записи пропущен, 0 ошибок |
| Офлайн UI | На чистом симуляторе при выключенном Wi-Fi Mac: `xcodebuild -project ios/Kstati.xcodeproj -scheme Kstati -destination 'platform=iOS Simulator,id=9E66650E-10CF-47C4-8FF7-D0D63B84C1BD' -only-testing:KstatiUITests/KstatiUITests/testShareImageFromAnotherApp test` | 1 тест прошёл, 0 ошибок; Wi-Fi включён обратно после теста |
| Ошибка записи | Исторический прогон с ручным запретом записи в `originals` | Тест прошёл; теперь выполняется автоматически в `Full` |

`ShareFixtureHost` передаёт [тестовый PNG](KstatiApp/Tests/Fixtures/appointment.png) через системное меню «Поделиться». `testShareImageFromAnotherApp` проверяет сохранение в расширении, оригинал, OCR `12:30`, исправление, поиск, пустой результат и перезапуск. `testEditKeepsOriginalAndDeletingGroupKeepsMemory` проверяет исходный текст, правку, две группы и удаление одной из них. `testManualCaptureSearchAndReopen` проверяет ручной захват.

## Текущий E2E-набор

`KstatiUITests` использует XCTest UI, Page Objects в `KstatiApp/Tests/UITests/Pages/` и тестовый host для системного Share Sheet. Каждый сценарий передаёт новый test ID приложению; debug-сборка очищает только файлы памяти в App Group до открытия БД. Повторный запуск в рамках сценария сохраняет запись. Сценарий ошибки записи использует debug-only переключатель; ручной `chmod` больше не нужен. UI-тесты выполняются последовательно из-за общей App Group.

`Smoke` запускает сквозной Share-сценарий. `Full` запускает четыре сценария, включая ошибку записи. При падении Xcode сохраняет снимки и диагностику в `.xcresult`. Для iPhone 17e с iOS 27.2:

```sh
cd ios
xcodegen generate --spec project.yml
xcodebuild -project Kstati.xcodeproj -scheme Kstati -showTestPlans
xcodebuild -project Kstati.xcodeproj -scheme Kstati -destination 'platform=iOS Simulator,id=9E66650E-10CF-47C4-8FF7-D0D63B84C1BD' -testPlan Smoke -parallel-testing-enabled NO -resultBundlePath "/tmp/kstati-smoke-$(date +%s).xcresult" test
xcodebuild -project Kstati.xcodeproj -scheme Kstati -destination 'platform=iOS Simulator,id=9E66650E-10CF-47C4-8FF7-D0D63B84C1BD' -testPlan Full -parallel-testing-enabled NO -resultBundlePath "/tmp/kstati-full-$(date +%s).xcresult" test
```

Проверка 2026-11-06: `Smoke` — 1/1, `Full` — 4/4 без пропусков. `Full` прошёл второй раз подряд на том же симуляторе без очистки: 4/4. Release-сборка приложения и расширения не содержит тестовых переключателей.

После форматирования, 2026-11-07: `swift test -j 1` — 11/11 (6 + 4 + 1), сборка схемы `Kstati` для iOS Simulator — `BUILD SUCCEEDED`, `Smoke` — 1/1, `Full` — 4/4 без пропусков и ошибок. Результаты UI-прогонов: `/tmp/kstati-final-smoke-2026-11-06.xcresult` и `/tmp/kstati-final-full-2026-11-06.xcresult`. Исходный набор имел три успешных сценария и один пропуск ошибки записи; итоговый набор проверяет все четыре сценария автоматически. Публичные пользовательские пути и 11 Swift-проверок сохранены.

Повторный `xcodegen generate --spec project.yml` сохранил байт-в-байт тот же `project.pbxproj` (SHA-256 `992f35da16190b94447d0714177d209da5ef7637d9a4aa1ca305ec74da56c3d3`). Строгая проверка OpenSpec и `git diff --check` прошли. Шесть многострочных SQL-запросов, включая миграцию `initial`, совпадают с baseline после нормализации отступов; четыре прежних UI-сценария сохранены.

## Формат Swift

Используется `xcrun swift-format` 6.4.4 из Xcode 27.2. Запускать из корня репозитория; команды охватывают все собственные Swift-файлы в `ios/`, включая `ios/Package.swift`. Первая команда изменяет файлы, вторая только проверяет их и завершается с ошибкой при нарушении формата.

```sh
rg --files -0 ios -g '*.swift' | xargs -0 xcrun swift-format format --in-place
rg --files -0 ios -g '*.swift' | xargs -0 xcrun swift-format lint --strict
```

## Покрытие требований

| Delta spec | Проверка |
| --- | --- |
| `memory-capture` | Текст, пустой ввод, повтор capture ID, целостность файла — Swift tests; Share Sheet и ошибка записи — UI tests |
| `memory-records` | Оригинал, перезапуск, N:M группы, удаление — Swift и UI tests |
| `memory-review` | Успешный и неуспешный Vision OCR, отклонение предложения, раздельное хранение предложения и подтверждения — Swift tests; карточка и правка — UI test |
| `memory-search` | FTS5 после правки/удаления — Swift tests; поиск скриншота, пустой результат и открытие оригинала — UI test |

## Офлайн-прогон

Перед запуском целевого теста симулятор iPhone 17e был очищен, а `Kstati.app` и `ShareFixtureHost.app` установлены заново. Wi-Fi Mac (`en0`) был выключен на время `xcodebuild test` и включён обратно сразу после его завершения. Лог зафиксировал `Wi-Fi Power (en0): Off`, прохождение `testShareImageFromAnotherApp` за 57,806 с и `TEST SUCCEEDED`. Сценарий охватывает Share Extension, сохранение изображения, локальный OCR, исправление и поиск текста, открытие оригинала и перезапуск приложения. Проверка ошибки записи проведена отдельным UI-тестом, указанным выше. Все сценарии четырёх delta specs покрыты тестами, перечисленными в таблице покрытия.
