# 🧪 Инструкция по тестированию workflows

## Шаг 1: Загрузка на GitHub

### 1.1 Создайте новый репозиторий на GitHub

1. Перейдите на https://github.com/new
2. Назовите репозиторий, например `ios-code-review-test`
3. Выберите **Private** (для приватных репозиториев)
4. НЕ создавайте README (у вас уже есть код)
5. Нажмите **Create repository**

### 1.2 Запуште код

```bash
cd /Users/halftime/Desktop/TemplateResultTest

# Если еще не связали с GitHub
git remote add origin https://github.com/YOUR_USERNAME/ios-code-review-test.git

# Или если нужно изменить origin
git remote set-url origin https://github.com/YOUR_USERNAME/ios-code-review-test.git

# Отправляем
git push -u origin main
```

**Замените `YOUR_USERNAME`** на ваш GitHub username!

---

## Шаг 2: Настройка Secrets

### 2.1 Создайте тестовый backend endpoint

Для тестирования можете использовать **webhook.site** (бесплатно):

1. Откройте https://webhook.site
2. Скопируйте **Your unique URL** (например: `https://webhook.site/abc123...`)
3. Эта страница будет показывать все входящие запросы

### 2.2 Добавьте GitHub Secrets

1. Перейдите в ваш репозиторий на GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Нажмите **New repository secret**

Добавьте 2 секрета:

| Name | Value |
|------|-------|
| `BACKEND_URL` | `https://webhook.site/abc123...` (ваш URL) |
| `BACKEND_TOKEN` | `test-token-123` (любое значение для теста) |

---

## Шаг 3: Замените ссылки на бинарники

### 3.1 Откройте файл на GitHub

1. В репозитории перейдите: `.github/workflows/code-review.yml`
2. Нажмите кнопку **Edit** (карандаш)

### 3.2 Найдите строки 30-32

```yaml
curl -L "https://cloud.tstservice.tech/public.php/dav/files/1" -o tools/swift-style-check
curl -L "https://cloud.tstservice.tech/public.php/dav/files/2" -o tools/swift-dead-code
curl -L "https://cloud.tstservice.tech/public.php/dav/files/3" -o tools/swift-memory-check
```

### 3.3 Замените на ВАШИ реальные ссылки

```yaml
curl -L "https://ваш-облако.com/swift-style-check" -o tools/swift-style-check
curl -L "https://ваш-облако.com/swift-dead-code" -o tools/swift-dead-code
curl -L "https://ваш-облако.com/swift-memory-check" -o tools/swift-memory-check
```

4. Нажмите **Commit changes**

---

## Шаг 4: Тестирование через GitHub UI (самое простое)

### 4.1 Запуск Code Review

1. Перейдите: **Actions** → **🔍 Code Review (Optimized)**
2. Нажмите **Run workflow** (справа)
3. Выберите ветку `main`
4. Нажмите зеленую кнопку **Run workflow**

**Ожидаемый результат:**
- Workflow запустится (~90 секунд)
- В логах увидите все этапы
- На webhook.site придет POST запрос с JSON отчетом

### 4.2 Запуск Build Check

1. Перейдите: **Actions** → **🔨 Build Check**
2. Нажмите **Run workflow**
3. Выберите ветку `main`
4. Нажмите **Run workflow**

**Ожидаемый результат:**
- Workflow запустится (~3-5 минут)
- Проект скомпилируется
- Результат придет на webhook.site

---

## Шаг 5: Тестирование через API (эмуляция сервера)

Теперь самое интересное - запуск workflows так, как это будет делать ваш backend!

### 5.1 Создайте GitHub Personal Access Token

1. Перейдите: https://github.com/settings/tokens
2. Нажмите **Generate new token** → **Generate new token (classic)**
3. Дайте имя: `code-review-test`
4. Выберите права:
   - ✅ **repo** (все подпункты)
5. Нажмите **Generate token**
6. **СКОПИРУЙТЕ токен** (больше не увидите!)

Пример токена: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### 5.2 Подготовьте переменные окружения

Создайте файл `test-triggers.sh` на вашем компьютере:

```bash
#!/bin/bash

# ЗАМЕНИТЕ НА ВАШИ ЗНАЧЕНИЯ:
export GITHUB_TOKEN="ghp_ваш_токен_здесь"
export GITHUB_OWNER="ваш_username"
export GITHUB_REPO="ios-code-review-test"

echo "✅ Переменные настроены:"
echo "   Owner: $GITHUB_OWNER"
echo "   Repo: $GITHUB_REPO"
echo "   Token: ${GITHUB_TOKEN:0:7}..."
```

Сделайте исполняемым:
```bash
chmod +x test-triggers.sh
```

### 5.3 Тест #1: Запуск Code Review через API

```bash
# Загрузите переменные
source test-triggers.sh

# Запустите Code Review
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/dispatches \
  -d '{
    "event_type": "code-review",
    "client_payload": {
      "branch": "main",
      "commit": "test",
      "triggered_by": "manual-test"
    }
  }'
```

**Что должно произойти:**
```
(пустой ответ = успех)
```

### 5.4 Тест #2: Запуск Build Check через API

```bash
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/dispatches \
  -d '{
    "event_type": "build-check",
    "client_payload": {
      "branch": "main",
      "commit": "test",
      "triggered_by": "manual-test"
    }
  }'
```

### 5.5 Проверьте что workflow запустился

1. Перейдите в **Actions** на GitHub
2. Вы увидите запущенные workflows
3. Кликните на workflow чтобы посмотреть логи

---

## Шаг 6: Проверка результатов на webhook.site

### 6.1 Откройте webhook.site

Вернитесь на страницу webhook.site которую открыли в Шаге 2.

### 6.2 Проверьте входящие запросы

Вы должны увидеть POST запросы с такой структурой:

```json
{
  "repository": "username/ios-code-review-test",
  "branch": "main",
  "commit": "abc123...",
  "author": "username",
  "timestamp": "2025-01-22T12:34:56Z",
  "workflow_run_id": "123456789",
  "reports": {
    "style": {
      "summary": {
        "errors": 0,
        "warnings": 0
      },
      "files": []
    },
    "dead_code": {
      "summary": {
        "errors": 0,
        "warnings": 0,
        "infos": 0
      },
      "issues": []
    },
    "memory": {
      "summary": {
        "errors": 0,
        "warnings": 0,
        "infos": 0
      },
      "issues": []
    }
  }
}
```

---

## Шаг 7: Создайте удобный скрипт для тестов

Создайте файл `trigger-workflows.sh`:

```bash
#!/bin/bash

# Загрузка переменных
source test-triggers.sh

echo "╔════════════════════════════════════════════════════════╗"
echo "║       🚀 GitHub Actions Workflow Trigger Tool          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Выберите действие:"
echo "  1) Code Review (быстрый, ~90 сек)"
echo "  2) Build Check (медленный, ~3-5 мин)"
echo "  3) Оба workflow параллельно"
echo ""
read -p "Ваш выбор (1-3): " choice

case $choice in
  1)
    echo "🚀 Запускаю Code Review..."
    curl -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/dispatches \
      -d '{"event_type":"code-review","client_payload":{"triggered_by":"test-script"}}'

    echo ""
    echo "✅ Code Review запущен!"
    echo "📊 Смотрите результаты:"
    echo "   GitHub: https://github.com/$GITHUB_OWNER/$GITHUB_REPO/actions"
    echo "   Webhook: https://webhook.site (откройте ваш URL)"
    ;;

  2)
    echo "🔨 Запускаю Build Check..."
    curl -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/dispatches \
      -d '{"event_type":"build-check","client_payload":{"triggered_by":"test-script"}}'

    echo ""
    echo "✅ Build Check запущен!"
    echo "📊 Смотрите результаты:"
    echo "   GitHub: https://github.com/$GITHUB_OWNER/$GITHUB_REPO/actions"
    ;;

  3)
    echo "🚀 Запускаю оба workflow..."

    curl -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/dispatches \
      -d '{"event_type":"code-review","client_payload":{"triggered_by":"test-script"}}'

    sleep 1

    curl -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/dispatches \
      -d '{"event_type":"build-check","client_payload":{"triggered_by":"test-script"}}'

    echo ""
    echo "✅ Оба workflow запущены!"
    echo "📊 Смотрите результаты:"
    echo "   GitHub: https://github.com/$GITHUB_OWNER/$GITHUB_REPO/actions"
    echo "   Webhook: https://webhook.site (откройте ваш URL)"
    ;;

  *)
    echo "❌ Неверный выбор"
    exit 1
    ;;
esac

echo ""
echo "⏱️ Примерное время:"
echo "   Code Review: ~90 секунд"
echo "   Build Check: ~3-5 минут"
```

Сделайте исполняемым:
```bash
chmod +x trigger-workflows.sh
```

Теперь запускайте просто:
```bash
./trigger-workflows.sh
```

---

## Шаг 8: Проверка логов

### 8.1 В GitHub Actions

1. Перейдите: **Actions** в вашем репозитории
2. Кликните на запущенный workflow
3. Кликните на job `code-analysis` или `build`
4. Раскройте каждый шаг чтобы посмотреть подробные логи

**Что искать:**
- ✅ Зеленые галочки = успех
- ❌ Красные крестики = ошибки
- ⏱️ Время выполнения каждого шага

### 8.2 На webhook.site

Проверьте:
- Пришел ли POST запрос
- Правильная ли структура JSON
- Есть ли данные в `reports.style`, `reports.dead_code`, `reports.memory`

---

## Шаг 9: Тестирование с реальным Swift проектом

Если у вас есть Swift проект, скопируйте его файлы в репозиторий:

```bash
# Например, если у вас есть MyApp.xcodeproj
cp -r ~/Projects/MyApp/*.swift ./
cp -r ~/Projects/MyApp/MyApp.xcodeproj ./

git add .
git commit -m "Add test Swift project"
git push

# Запустите workflow
./trigger-workflows.sh
```

Теперь workflow найдет реальные проблемы в коде!

---

## Шаг 10: Проверка времени выполнения

### 10.1 Откройте завершенный workflow

1. **Actions** → выберите завершенный workflow
2. В правом верхнем углу увидите общее время

### 10.2 Проверьте время каждого шага

Раскройте job и посмотрите время каждого step:

**Ожидаемое время для Code Review:**
```
📥 Checkout кода               ~5 сек
📦 Скачивание инструментов     ~5 сек
🔧 Установка SwiftLint         ~25 сек
🔧 Установка Periphery         ~15 сек
🎨 Проверка стиля кода         ~10 сек
🗑️ Поиск неиспользуемого кода  ~15 сек
💾 Проверка утечек памяти      ~10 сек
📊 Сводный отчет              ~3 сек
📤 Отправка на backend        ~2 сек
────────────────────────────────────
ИТОГО:                        ~90 сек
```

Если время больше 100 секунд - смотрите раздел оптимизации в README.

---

## 🎯 Чеклист успешного теста

- [ ] Репозиторий создан на GitHub
- [ ] Код запушен (`git push`)
- [ ] Secrets настроены (`BACKEND_URL`, `BACKEND_TOKEN`)
- [ ] Ссылки на бинарники заменены в `code-review.yml`
- [ ] Webhook.site открыт и готов принимать запросы
- [ ] GitHub Personal Access Token создан
- [ ] Скрипт `test-triggers.sh` настроен с вашими данными
- [ ] Скрипт `trigger-workflows.sh` создан
- [ ] Code Review запущен через UI - **успешно** ✅
- [ ] Build Check запущен через UI - **успешно** ✅
- [ ] Code Review запущен через API - **успешно** ✅
- [ ] Build Check запущен через API - **успешно** ✅
- [ ] Отчеты приходят на webhook.site ✅
- [ ] Время выполнения Code Review < 100 сек ✅

---

## 🐛 Частые проблемы

### Workflow не запускается через API

**Причина:** Неправильный токен или права

**Решение:**
```bash
# Проверьте токен
curl -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user

# Должен вернуть ваш профиль, а не 401 Unauthorized
```

### Бинарники не скачиваются

**Причина:** Ссылки неверные или требуют авторизации

**Решение:**
```bash
# Проверьте ссылку в браузере
# Должна начаться загрузка файла, а не открыться страница входа

# Или через curl:
curl -I "https://ваша-ссылка"
# Должно быть: HTTP/2 200
```

### Backend не получает отчеты

**Причина:** Secret `BACKEND_URL` не настроен

**Решение:**
1. Проверьте что secret существует: **Settings** → **Secrets** → **Actions**
2. В логах workflow должна быть строка: `📤 Отправляю отчет на backend...`
3. Если написано `⚠️ BACKEND_URL не настроен` - добавьте secret

### Время выполнения > 100 секунд

**Причина:** Долгая установка SwiftLint/Periphery через brew

**Решение:** Добавьте кеширование или используйте готовые бинарники

См. раздел "Что делать если превышен лимит 100 секунд" в `.github/workflows/README.md`

---

## 📚 Полезные ссылки

- GitHub API docs: https://docs.github.com/en/rest/repos/repos#create-a-repository-dispatch-event
- Webhook.site: https://webhook.site
- GitHub Tokens: https://github.com/settings/tokens
- Actions UI: https://github.com/YOUR_USERNAME/YOUR_REPO/actions

---

## ✅ Следующие шаги

После успешного теста:

1. **Интегрируйте с вашим backend**
   - Замените webhook.site на реальный URL
   - Добавьте обработку отчетов
   - Сохраняйте в БД

2. **Настройте автоматический запуск**
   - На создание PR
   - На важные коммиты
   - По расписанию

3. **Добавьте уведомления**
   - Slack/Telegram при ошибках
   - Email дайджест
   - Dashboard с метриками

Удачи! 🚀
