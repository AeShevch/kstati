# Проверка первого OpenSpec change

Дата: 2026-11-06. Xcode 27.2, iOS 27.2 Simulator (iPhone 17e, `9E66650E-10CF-47C4-8FF7-D0D63B84C1BD`). Deployment target — iOS 17.0.

## Результаты

| Проверка | Команда | Результат |
| --- | --- | --- |
| OpenSpec | `npx -y @fission-ai/openspec@1.16.0 validate establish-offline-memory-foundation --strict` | Change valid |
| Swift unit/integration | `cd ios && swift test -j 1` | 11/11 тестов прошли |
| Xcode targets | `xcodebuild -list -project ios/Kstati.xcodeproj` | App, Share Extension, UI tests и fixture host доступны |
| Все targets | `xcodebuild -project ios/Kstati.xcodeproj -scheme Kstati -destination 'platform=iOS Simulator,id=9E66650E-10CF-47C4-8FF7-D0D63B84C1BD' build` | BUILD SUCCEEDED |
| UI | `xcodebuild -project ios/Kstati.xcodeproj -scheme Kstati -destination 'platform=iOS Simulator,id=9E66650E-10CF-47C4-8FF7-D0D63B84C1BD' test` | 3 сценария прошли, условный тест ошибки записи пропущен, 0 ошибок |
| Ошибка записи | Та же команда с `-only-testing:KstatiUITests/KstatiUITests/testShareReportsWriteFailure` после запрета записи в `originals` | Тест прошёл: ошибка показана, расширение осталось открытым |

`ShareFixtureHost` передаёт [тестовый PNG](Fixtures/appointment.png) через системное меню «Поделиться». `testShareImageFromAnotherApp` проверяет сохранение в расширении, оригинал, OCR `12:30`, исправление, поиск, пустой результат и перезапуск. `testEditKeepsOriginalAndDeletingGroupKeepsMemory` проверяет исходный текст, правку, две группы и удаление одной из них. `testManualCaptureSearchAndReopen` проверяет ручной захват.

Перед полным UI-прогоном используйте чистый симулятор и установите оба приложения. `ios/project.yml` — источник конфигурации Xcode:

```sh
cd ios
xcodegen generate --spec project.yml
xcodebuild -project Kstati.xcodeproj -scheme Kstati -destination 'platform=iOS Simulator,id=9E66650E-10CF-47C4-8FF7-D0D63B84C1BD' build
xcrun simctl shutdown 9E66650E-10CF-47C4-8FF7-D0D63B84C1BD
xcrun simctl erase 9E66650E-10CF-47C4-8FF7-D0D63B84C1BD
xcrun simctl boot 9E66650E-10CF-47C4-8FF7-D0D63B84C1BD
xcrun simctl bootstatus 9E66650E-10CF-47C4-8FF7-D0D63B84C1BD -b
xcrun simctl install 9E66650E-10CF-47C4-8FF7-D0D63B84C1BD ~/Library/Developer/Xcode/DerivedData/Kstati-*/Build/Products/Debug-iphonesimulator/ShareFixtureHost.app
xcrun simctl install 9E66650E-10CF-47C4-8FF7-D0D63B84C1BD ~/Library/Developer/Xcode/DerivedData/Kstati-*/Build/Products/Debug-iphonesimulator/Kstati.app
xcodebuild -project Kstati.xcodeproj -scheme Kstati -destination 'platform=iOS Simulator,id=9E66650E-10CF-47C4-8FF7-D0D63B84C1BD' test
```

Отдельный UI-тест ошибки записи использует другую версию PNG, чтобы повторный capture ID не скрывал ошибку. После успешного Share-теста из корня репозитория:

```sh
xcrun simctl spawn 9E66650E-10CF-47C4-8FF7-D0D63B84C1BD launchctl setenv KST_WRITE_FAILURE_TEST 1
group_dir=$(xcrun simctl get_app_container 9E66650E-10CF-47C4-8FF7-D0D63B84C1BD app.kstati.ios groups | awk '{print $2}')
chmod 555 "$group_dir/originals"
xcodebuild -project ios/Kstati.xcodeproj -scheme Kstati -destination 'platform=iOS Simulator,id=9E66650E-10CF-47C4-8FF7-D0D63B84C1BD' -only-testing:KstatiUITests/KstatiUITests/testShareReportsWriteFailure test
chmod 755 "$group_dir/originals"
xcrun simctl spawn 9E66650E-10CF-47C4-8FF7-D0D63B84C1BD launchctl unsetenv KST_WRITE_FAILURE_TEST
```

## Покрытие требований

| Delta spec | Проверка |
| --- | --- |
| `memory-capture` | Текст, пустой ввод, повтор capture ID, целостность файла — Swift tests; Share Sheet и ошибка записи — UI tests |
| `memory-records` | Оригинал, перезапуск, N:M группы, удаление — Swift и UI tests |
| `memory-review` | Успешный и неуспешный Vision OCR, отклонение предложения, раздельное хранение предложения и подтверждения — Swift tests; карточка и правка — UI test |
| `memory-search` | FTS5 после правки/удаления — Swift tests; поиск скриншота, пустой результат и открытие оригинала — UI test |

## Оставшаяся проверка

Приложение, расширение и fixture host не используют сетевые API; сохранение, OCR и поиск реализованы локально. Полный сценарий **не запускался при физически отключённой сети**: в установленном iOS 27.2 Simulator переключатель авиарежима отсутствует в Settings и Control Center. Поэтому задачи 2.3 и 5.1 остаются открытыми до прогона на iPhone или управляемом симуляторе с отключённой сетью. Остальные шаги этих задач прошли.
