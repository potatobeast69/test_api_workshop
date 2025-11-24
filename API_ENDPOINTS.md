# API Endpoints для запуска GitHub Actions

## Общая информация

Для запуска workflows используется GitHub API endpoint `repository_dispatch`.

**Base URL:** `https://api.github.com`

## Требования

1. **GitHub Personal Access Token** с правами `repo`
2. **Название репозитория:** `{OWNER}/{REPO}`

### Как получить токен:
1. https://github.com/settings/tokens
2. Generate new token (classic)
3. Выберите права: `repo` (все подпункты)
4. Generate token

---

## Endpoint 1: Code Review (быстрый, ~90 сек)

### Описание
Запускает проверку кода без компиляции:
- 🎨 Проверка стиля кода (SwiftLint)
- 💾 Статический анализ утечек памяти

### HTTP Request

```http
POST https://api.github.com/repos/{OWNER}/{REPO}/dispatches
```

### Headers

```
Accept: application/vnd.github+json
Authorization: Bearer {GITHUB_TOKEN}
X-GitHub-Api-Version: 2022-11-28
Content-Type: application/json
```

### Body

```json
{
  "event_type": "code-review",
  "client_payload": {
    "triggered_by": "backend-server",
    "student_id": "optional-student-id",
    "assignment_id": "optional-assignment-id"
  }
}
```

### cURL Example

```bash
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ghp_ваш_токен_здесь" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -H "Content-Type: application/json" \
  https://api.github.com/repos/username/repo-name/dispatches \
  -d '{
    "event_type": "code-review",
    "client_payload": {
      "triggered_by": "backend-server"
    }
  }'
```

### Response

**Success:**
- HTTP Status: `204 No Content`
- Body: (пустой)

**Error:**
- HTTP Status: `401` - неверный токен
- HTTP Status: `404` - репозиторий не найден
- HTTP Status: `422` - неверный формат запроса

---

## Endpoint 2: Build Check (медленный, ~3-5 мин)

### Описание
Запускает полную компиляцию проекта для iOS Simulator.

### HTTP Request

```http
POST https://api.github.com/repos/{OWNER}/{REPO}/dispatches
```

### Headers

```
Accept: application/vnd.github+json
Authorization: Bearer {GITHUB_TOKEN}
X-GitHub-Api-Version: 2022-11-28
Content-Type: application/json
```

### Body

```json
{
  "event_type": "build-check",
  "client_payload": {
    "triggered_by": "backend-server",
    "student_id": "optional-student-id",
    "assignment_id": "optional-assignment-id"
  }
}
```

### cURL Example

```bash
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ghp_ваш_токен_здесь" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -H "Content-Type: application/json" \
  https://api.github.com/repos/username/repo-name/dispatches \
  -d '{
    "event_type": "build-check",
    "client_payload": {
      "triggered_by": "backend-server"
    }
  }'
```

### Response

**Success:**
- HTTP Status: `204 No Content`
- Body: (пустой)

**Error:**
- HTTP Status: `401` - неверный токен
- HTTP Status: `404` - репозиторий не найден
- HTTP Status: `422` - неверный формат запроса

---

## Получение результатов

После запуска workflow, результаты будут отправлены на ваш backend через webhook.

### Webhook URL

Настройте в GitHub Secrets:
- `BACKEND_URL` - URL вашего backend для получения результатов
- `BACKEND_TOKEN` - токен для авторизации (опционально)

**Settings → Secrets and variables → Actions → New repository secret**

### Формат результатов (JSON)

**Code Review:**
```json
{
  "repository": "owner/repo",
  "branch": "main",
  "commit": "abc123...",
  "author": "username",
  "timestamp": "2025-11-24T12:00:00Z",
  "workflow_run_id": "123456789",
  "reports": {
    "style": {
      "summary": {
        "errors": 1,
        "warnings": 5,
        "infos": 0
      },
      "issues": [...]
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
        "warnings": 2,
        "infos": 0
      },
      "issues": [...]
    }
  }
}
```

**Build Check:**
```json
{
  "repository": "owner/repo",
  "branch": "main",
  "commit": "abc123...",
  "author": "username",
  "timestamp": "2025-11-24T12:00:00Z",
  "workflow_run_id": "123456789",
  "build_status": "success",
  "build_time": "180s"
}
```

---

## Примеры для разных языков

### Python

```python
import requests

GITHUB_TOKEN = "ghp_ваш_токен"
OWNER = "username"
REPO = "repo-name"

def trigger_code_review():
    url = f"https://api.github.com/repos/{OWNER}/{REPO}/dispatches"
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "X-GitHub-Api-Version": "2022-11-28"
    }
    data = {
        "event_type": "code-review",
        "client_payload": {
            "triggered_by": "python-script"
        }
    }

    response = requests.post(url, headers=headers, json=data)

    if response.status_code == 204:
        print("✅ Workflow запущен успешно!")
    else:
        print(f"❌ Ошибка: {response.status_code}")
        print(response.text)

trigger_code_review()
```

### Node.js

```javascript
const axios = require('axios');

const GITHUB_TOKEN = 'ghp_ваш_токен';
const OWNER = 'username';
const REPO = 'repo-name';

async function triggerCodeReview() {
  const url = `https://api.github.com/repos/${OWNER}/${REPO}/dispatches`;

  try {
    await axios.post(url, {
      event_type: 'code-review',
      client_payload: {
        triggered_by: 'nodejs-script'
      }
    }, {
      headers: {
        'Accept': 'application/vnd.github+json',
        'Authorization': `Bearer ${GITHUB_TOKEN}`,
        'X-GitHub-Api-Version': '2022-11-28'
      }
    });

    console.log('✅ Workflow запущен успешно!');
  } catch (error) {
    console.error('❌ Ошибка:', error.response?.status, error.response?.data);
  }
}

triggerCodeReview();
```

### PHP

```php
<?php

$githubToken = 'ghp_ваш_токен';
$owner = 'username';
$repo = 'repo-name';

$url = "https://api.github.com/repos/$owner/$repo/dispatches";

$data = json_encode([
    'event_type' => 'code-review',
    'client_payload' => [
        'triggered_by' => 'php-script'
    ]
]);

$options = [
    'http' => [
        'header'  => [
            'Accept: application/vnd.github+json',
            "Authorization: Bearer $githubToken",
            'X-GitHub-Api-Version: 2022-11-28',
            'Content-Type: application/json',
            'User-Agent: PHP'
        ],
        'method'  => 'POST',
        'content' => $data
    ]
];

$context = stream_context_create($options);
$result = file_get_contents($url, false, $context);

if ($http_response_header[0] === 'HTTP/1.1 204 No Content') {
    echo "✅ Workflow запущен успешно!\n";
} else {
    echo "❌ Ошибка: " . $http_response_header[0] . "\n";
}
?>
```

---

## Проверка статуса workflow

### Получить список запущенных workflows

```bash
curl -H "Authorization: Bearer {GITHUB_TOKEN}" \
  https://api.github.com/repos/{OWNER}/{REPO}/actions/runs
```

### Получить детали конкретного workflow run

```bash
curl -H "Authorization: Bearer {GITHUB_TOKEN}" \
  https://api.github.com/repos/{OWNER}/{REPO}/actions/runs/{RUN_ID}
```

---

## Troubleshooting

### Ошибка 401 Unauthorized
- Проверьте что токен валидный
- Убедитесь что токен имеет права `repo`

### Ошибка 404 Not Found
- Проверьте OWNER и REPO
- Убедитесь что у токена есть доступ к репозиторию

### Workflow не запускается
- Проверьте что workflows включены: Settings → Actions → Allow all actions

### Не приходят результаты
- Проверьте что BACKEND_URL настроен в Secrets
- Проверьте логи workflow в GitHub Actions

---

## Контакты и поддержка

GitHub API Documentation: https://docs.github.com/en/rest/repos/repos#create-a-repository-dispatch-event
