#!/bin/bash

# ============================================
# Скрипт для запуска GitHub Actions workflows
# ============================================

# Загрузка переменных
if [ ! -f "test-triggers.sh" ]; then
  echo "❌ Файл test-triggers.sh не найден!"
  echo "Убедитесь что вы запускаете скрипт из корня репозитория"
  exit 1
fi

source test-triggers.sh

echo "╔════════════════════════════════════════════════════════╗"
echo "║       🚀 GitHub Actions Workflow Trigger Tool          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Репозиторий: $GITHUB_OWNER/$GITHUB_REPO"
echo ""
echo "Выберите действие:"
echo "  1) Code Review (быстрый, ~90 сек)"
echo "  2) Build Check (медленный, ~3-5 мин)"
echo "  3) Оба workflow параллельно"
echo "  4) Проверить статус токена"
echo ""
read -p "Ваш выбор (1-4): " choice

case $choice in
  1)
    echo ""
    echo "🚀 Запускаю Code Review..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/dispatches \
      -d '{"event_type":"code-review","client_payload":{"triggered_by":"test-script"}}')

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" = "204" ]; then
      echo "✅ Code Review успешно запущен!"
      echo ""
      echo "📊 Смотрите результаты:"
      echo "   GitHub: https://github.com/$GITHUB_OWNER/$GITHUB_REPO/actions"
      echo "   Время выполнения: ~90 секунд"
      echo ""
      echo "💡 Отчет придет на ваш BACKEND_URL (webhook.site)"
    else
      echo "❌ Ошибка: HTTP $HTTP_CODE"
      echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    fi
    ;;

  2)
    echo ""
    echo "🔨 Запускаю Build Check..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/dispatches \
      -d '{"event_type":"build-check","client_payload":{"triggered_by":"test-script"}}')

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" = "204" ]; then
      echo "✅ Build Check успешно запущен!"
      echo ""
      echo "📊 Смотрите результаты:"
      echo "   GitHub: https://github.com/$GITHUB_OWNER/$GITHUB_REPO/actions"
      echo "   Время выполнения: ~3-5 минут"
    else
      echo "❌ Ошибка: HTTP $HTTP_CODE"
      echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    fi
    ;;

  3)
    echo ""
    echo "🚀 Запускаю оба workflow..."
    echo ""

    # Code Review
    echo "1/2: Code Review..."
    RESPONSE1=$(curl -s -w "\n%{http_code}" -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/dispatches \
      -d '{"event_type":"code-review","client_payload":{"triggered_by":"test-script"}}')

    HTTP_CODE1=$(echo "$RESPONSE1" | tail -n1)

    if [ "$HTTP_CODE1" = "204" ]; then
      echo "✅ Code Review запущен"
    else
      echo "❌ Code Review ошибка: HTTP $HTTP_CODE1"
    fi

    sleep 1

    # Build Check
    echo "2/2: Build Check..."
    RESPONSE2=$(curl -s -w "\n%{http_code}" -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/dispatches \
      -d '{"event_type":"build-check","client_payload":{"triggered_by":"test-script"}}')

    HTTP_CODE2=$(echo "$RESPONSE2" | tail -n1)

    if [ "$HTTP_CODE2" = "204" ]; then
      echo "✅ Build Check запущен"
    else
      echo "❌ Build Check ошибка: HTTP $HTTP_CODE2"
    fi

    echo ""
    echo "📊 Смотрите результаты:"
    echo "   GitHub: https://github.com/$GITHUB_OWNER/$GITHUB_REPO/actions"
    echo ""
    echo "⏱️ Примерное время:"
    echo "   Code Review: ~90 секунд"
    echo "   Build Check: ~3-5 минут"
    ;;

  4)
    echo ""
    echo "🔍 Проверяю токен..."
    RESPONSE=$(curl -s -w "\n%{http_code}" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      https://api.github.com/user)

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" = "200" ]; then
      USERNAME=$(echo "$BODY" | jq -r '.login')
      echo "✅ Токен валидный!"
      echo "   User: $USERNAME"
      echo ""

      # Проверка прав на репозиторий
      echo "🔍 Проверяю доступ к репозиторию..."
      REPO_RESPONSE=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO)

      REPO_HTTP_CODE=$(echo "$REPO_RESPONSE" | tail -n1)

      if [ "$REPO_HTTP_CODE" = "200" ]; then
        echo "✅ Доступ к репозиторию есть!"
        echo "   Все готово для запуска workflows"
      else
        echo "❌ Нет доступа к репозиторию"
        echo "   Проверьте что GITHUB_OWNER и GITHUB_REPO правильные"
      fi
    else
      echo "❌ Токен невалидный! HTTP $HTTP_CODE"
      echo ""
      echo "Получите новый токен:"
      echo "  https://github.com/settings/tokens"
    fi
    ;;

  *)
    echo "❌ Неверный выбор"
    exit 1
    ;;
esac

echo ""
