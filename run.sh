#!/bin/bash
# Запуск задач практики и служебных действий.
#   ./run.sh <команда> [аргументы]   задача из src/pract1.sh
#   ./run.sh test                    тесты
#   ./run.sh lint                    проверка ShellCheck

ROOT=$(cd "$(dirname "$0")" && pwd)

case "${1:-}" in
    test) exec bash "$ROOT/tests/test_pract1.sh" ;;
    lint) exec shellcheck "$ROOT"/run.sh "$ROOT"/src/*.sh "$ROOT"/tests/*.sh ;;
    *) exec bash "$ROOT/src/pract1.sh" "$@" ;;
esac
