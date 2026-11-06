# Tasks

## 1. Структура модулей и тестов

- [ ] 1.1 Зафиксировать исходный список SwiftPM/Xcode targets, 11 Swift-тестов и UI-сценарии из `ios/Tests/README.md`; проверить `swift --version`, `xcrun swift-format --version` и `xcodegen --version` перед переносом.
- [ ] 1.2 Перенести исходники и тесты `MemoryCore`, `MemoryPersistence`, `MemoryOCR` в соседние `Sources/` и `Tests/`, обновить явные paths в `ios/Package.swift`; проверить `cd ios && swift test -j 1` и прежний список тестов.
- [ ] 1.3 Перенести исходники приложения и расширения, UI-тесты, fixture host и PNG в каталоги, указанные в design; обновить `ios/project.yml`, сгенерировать проект и проверить `xcodebuild -list -project ios/Kstati.xcodeproj`, сборку всех targets и доступность PNG в fixture host.
- [ ] 1.4 Перенести исторический отчёт в `ios/TESTING.md`, обновить ссылки и пути к fixture в README; проверить, что все локальные ссылки разрешаются и команды используют актуальные пути.

## 2. Один основной тип на файл

- [ ] 2.1 Разделить `MemoryModels.swift` на файлы основных доменных типов и вынести `ShareCaptureID` из `MemoryRepository.swift`, не меняя сигнатур и SQL; проверить `cd ios && swift test -j 1`.
- [ ] 2.2 Разделить `VisionOCR.swift` на файлы распознавателя, порта и процессора; проверить тесты `MemoryOCRTests` и сборку `MemoryOCR`.
- [ ] 2.3 Разделить `MemoryViews.swift` на файлы экранов, а `KstatiApp.swift` — на приложение, store и доступ к App Group; проверить сборку всех Xcode targets и запуск существующих UI-тестов.

## 3. Единый формат Swift

- [ ] 3.1 Добавить корневую `.swift-format` с отступом 4 пробела и длиной строки 120 символов; проверить, что `xcrun swift-format dump-configuration --effective` отражает эти значения для исходника.
- [ ] 3.2 После переноса применить `xcrun swift-format` ко всем собственным Swift-файлам, включая `ios/Package.swift`, отдельным коммитом без правок логики; проверить `xcrun swift-format lint --strict` на тех же путях и отсутствие содержательных изменений при просмотре diff.
- [ ] 3.3 Записать в `ios/TESTING.md` точную команду форматирования и read-only проверки с версией инструмента; проверить команду из чистого рабочего каталога.

## 4. Сквозная проверка реорганизации

- [ ] 4.1 Повторно выполнить `cd ios && swift test -j 1`, сборку всех Xcode targets и полный существующий набор UI-тестов на iOS Simulator; сравнить число и имена тестов с baseline и сохранить результаты в `ios/TESTING.md`.
- [ ] 4.2 Повторно запустить `cd ios && xcodegen generate --spec project.yml` и проверить отсутствие изменений `project.pbxproj`; выполнить `npx -y @fission-ai/openspec@1.16.0 validate organize-ios-code-and-formatting --strict`, `git diff --check` и убедиться, что схема БД и пользовательские сценарии не менялись.

## Workflow follow-up

- После реализации и ревью архивировать change; основным specs синхронизация не требуется, так как `skip_specs: true`.
