# ⚡ Быстрый старт

## 1. Загрузите на GitHub (2 минуты)

```bash
# 1. Создайте новый репозиторий на GitHub
# https://github.com/new

# 2. Загрузите код
git remote add origin https://github.com/ВАШ_USERNAME/ВАШ_REPO.git
git push -u origin main
```

## 2. Настройте Secrets (3 минуты)

1. Откройте https://webhook.site - скопируйте URL
2. В GitHub: **Settings → Secrets → Actions → New secret**

Добавьте:
- `BACKEND_URL` = ваш webhook.site URL
- `BACKEND_TOKEN` = любое значение (например: `test123`)

## 3. Замените ссылки на бинарники (1 минута)

Откройте `.github/workflows/code-review.yml` в GitHub и замените строки 30-32:

```yaml
# Было:
curl -L "https://cloud.tstservice.tech/public.php/dav/files/1" -o tools/swift-style-check

# Стало:
curl -L "https://ВАША_ССЫЛКА/swift-style-check" -o tools/swift-style-check
```

## 4. Протестируйте через UI (1 минута)

1. **Actions** → **Code Review (Optimized)**
2. **Run workflow** → выбрать `main` → **Run**
3. Подождать ~90 секунд
4. Проверить webhook.site - должен прийти JSON

✅ Работает? Отлично!

## 5. Тест через API (эмуляция сервера) (5 минут)

### Получите GitHub токен

1. https://github.com/settings/tokens
2. **Generate new token (classic)**
3. Выберите: `repo` (все галочки)
4. Скопируйте токен

### Настройте скрипты

```bash
# Откройте test-triggers.sh и замените:
export GITHUB_TOKEN="ghp_ваш_токен"
export GITHUB_OWNER="ваш_username"
export GITHUB_REPO="название_репо"
```

### Запустите

```bash
./trigger-workflows.sh
```

Выберите `1` для Code Review или `2` для Build Check.

---

## 🎯 Результат

Теперь вы можете запускать workflows с вашего сервера:

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_GITHUB_TOKEN" \
  https://api.github.com/repos/OWNER/REPO/dispatches \
  -d '{"event_type":"code-review"}'
```

**Время:**
- Code Review: ~90 секунд ✅
- Build Check: ~3-5 минут

**Экономия:** 18x быстрее (было 20 минут, стало 1.5 минуты)

---

## 📚 Подробности

- Полная инструкция: [TESTING.md](./TESTING.md)
- Документация workflows: [.github/workflows/README.md](./.github/workflows/README.md)

## ❓ Проблемы?

**Workflow не запускается:**
```bash
# Проверьте токен
curl -H "Authorization: Bearer YOUR_TOKEN" https://api.github.com/user
```

**Бинарники не скачиваются:**
```bash
# Проверьте ссылку
curl -I "https://ваша-ссылка"
# Должно быть: HTTP/2 200
```

**Отчеты не приходят на webhook:**
- Проверьте что `BACKEND_URL` добавлен в Secrets
- Откройте логи workflow в GitHub Actions
