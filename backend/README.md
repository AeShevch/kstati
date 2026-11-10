# Локальный анализ записей

Node.js 24. Для установки и проверки контракта из корня репозитория:

```sh
npm ci --prefix backend
npm test --prefix backend
```

Запустить локальный сервис для симулятора:

```sh
npm run build --prefix backend
KSTATI_ANALYSIS_FIXTURE=1 npm start --prefix backend
```

Сервис слушает 127.0.0.1:48731. Маршрут включается только явным флагом разработки. В production флаг игнорируется. Для полного набора iOS тестов запустите `./scripts/with-analysis-fixture.sh ./scripts/ios-checks.sh full`. Обёртка запускает сервис и завершает его после тестов.
