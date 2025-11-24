# API Endpoints - Краткая справка

## 🚀 Запуск Code Review (~90 сек)

```bash
POST https://api.github.com/repos/{OWNER}/{REPO}/dispatches

Headers:
  Authorization: Bearer {GITHUB_TOKEN}
  Accept: application/vnd.github+json
  X-GitHub-Api-Version: 2022-11-28

Body:
{
  "event_type": "code-review",
  "client_payload": {
    "triggered_by": "your-server"
  }
}

Response: 204 No Content (success)
```

**cURL:**
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/OWNER/REPO/dispatches \
  -d '{"event_type":"code-review"}'
```

---

## 🔨 Запуск Build Check (~3-5 мин)

```bash
POST https://api.github.com/repos/{OWNER}/{REPO}/dispatches

Headers:
  Authorization: Bearer {GITHUB_TOKEN}
  Accept: application/vnd.github+json
  X-GitHub-Api-Version: 2022-11-28

Body:
{
  "event_type": "build-check",
  "client_payload": {
    "triggered_by": "your-server"
  }
}

Response: 204 No Content (success)
```

**cURL:**
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/OWNER/REPO/dispatches \
  -d '{"event_type":"build-check"}'
```

---

## 📝 Параметры

**Замените:**
- `{OWNER}` - владелец репозитория (например: `potatobeast69`)
- `{REPO}` - название репозитория (например: `test_api_workshop`)
- `{GITHUB_TOKEN}` - Personal Access Token с правами `repo`

**Получить токен:** https://github.com/settings/tokens

---

## 📊 Получение результатов

Результаты отправляются POST запросом на ваш `BACKEND_URL` (настройте в GitHub Secrets).

**Пример результата Code Review:**
```json
{
  "repository": "owner/repo",
  "commit": "abc123",
  "reports": {
    "style": {"summary": {"errors": 1, "warnings": 5}},
    "memory": {"summary": {"errors": 0, "warnings": 2}}
  }
}
```

**Пример результата Build Check:**
```json
{
  "repository": "owner/repo",
  "commit": "abc123",
  "build_status": "success"
}
```
