#!/bin/bash

# ============================================
# Конфигурация для тестирования workflows
# ============================================

# ЗАМЕНИТЕ НА ВАШИ ЗНАЧЕНИЯ:
export GITHUB_TOKEN="ghp_замените_на_ваш_токен"
export GITHUB_OWNER="ваш_username"
export GITHUB_REPO="название_репозитория"

# Проверка что переменные заданы
if [ "$GITHUB_TOKEN" = "ghp_замените_на_ваш_токен" ]; then
  echo "❌ Ошибка: GITHUB_TOKEN не настроен!"
  echo ""
  echo "Откройте этот файл в редакторе и замените:"
  echo "  GITHUB_TOKEN='ghp_замените_на_ваш_токен'"
  echo "на ваш реальный токен."
  echo ""
  echo "Как получить токен:"
  echo "  1. https://github.com/settings/tokens"
  echo "  2. Generate new token (classic)"
  echo "  3. Выберите права: repo (все подпункты)"
  echo "  4. Generate token"
  exit 1
fi

if [ "$GITHUB_OWNER" = "ваш_username" ]; then
  echo "❌ Ошибка: GITHUB_OWNER не настроен!"
  echo ""
  echo "Откройте этот файл и замените:"
  echo "  GITHUB_OWNER='ваш_username'"
  echo "на ваш GitHub username"
  exit 1
fi

if [ "$GITHUB_REPO" = "название_репозитория" ]; then
  echo "❌ Ошибка: GITHUB_REPO не настроен!"
  echo ""
  echo "Откройте этот файл и замените:"
  echo "  GITHUB_REPO='название_репозитория'"
  echo "на название вашего репозитория"
  exit 1
fi

echo "✅ Переменные настроены:"
echo "   Owner: $GITHUB_OWNER"
echo "   Repo: $GITHUB_REPO"
echo "   Token: ${GITHUB_TOKEN:0:7}..."
echo ""
