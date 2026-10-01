#!/bin/bash
# Практическое занятие №1. Командная строка Linux.
# Все 10 задач собраны в одном скрипте и вызываются как подкоманды:
#   ./pract1.sh <команда> [аргументы]
# Список команд: ./pract1.sh help

REG_DIR=${REG_DIR:-/usr/local/bin}

# Вывести сообщение об ошибке и завершить работу.
die() {
    echo "pract1: $*" >&2
    exit 1
}

# Справка по командам.
cmd_help() {
    cat <<'HELP'
Использование: pract1.sh <команда> [аргументы]

Команды:
  users [файл]                   1. имена пользователей из passwd
  protocols [файл]               2. 5 протоколов с наибольшими номерами
  banner <текст>                 3. текст в рамке
  identifiers <файл>             4. идентификаторы C/C++/Java без повторов
  reg <файл> [имя]               5. регистрация команды в /usr/local/bin
  comments [каталог]             6. комментарий в первой строке .c/.js/.py
  duplicates [каталог]           7. файлы-дубликаты
  archive <расш> [каталог] [tar] 8. архив tar из файлов с расширением
  tabs <вход> <выход>            9. замена 4 пробелов на табуляцию
  empty <каталог>               10. пустые текстовые файлы
  help                              эта справка
HELP
}

# Задача 1. Отсортированный список имён пользователей из passwd.
cmd_users() {
    local file=${1:-/etc/passwd}
    [ -f "$file" ] || die "файл не найден: $file"
    grep -v '^#' "$file" | grep -o '^[^:]*' | sort
}

# Задача 2. 5 протоколов с наибольшими номерами: "номер имя".
cmd_protocols() {
    local file=${1:-/etc/protocols}
    [ -f "$file" ] || die "файл не найден: $file"
    grep -Ev '^[[:space:]]*(#|$)' "$file" |
        awk '{ print $2, $1 }' |
        sort -k1,1nr |
        head -n 5
}

# Задача 3. Текст в рамке, ширина которой зависит от длины текста.
cmd_banner() {
    [ $# -gt 0 ] || die "использование: banner <текст>"
    local text="$*" line
    line=$(printf '%*s' "$((${#text} + 2))" '' | tr ' ' '-')
    echo "+$line+"
    echo "| $text |"
    echo "+$line+"
}

# Задача 4. Все идентификаторы (правила C/C++/Java) в файле без повторов.
cmd_identifiers() {
    [ -f "${1:-}" ] || die "использование: identifiers <файл>"
    grep -oE '[A-Za-z_][A-Za-z0-9_]*' "$1" | sort -u | tr '\n' ' '
    echo
}

# Задача 5. Права 755 и копирование программы в $REG_DIR.
cmd_reg() {
    [ -f "${1:-}" ] || die "использование: reg <файл> [имя]"
    local name=${2:-$(basename "$1" .sh)}
    if [ -w "$REG_DIR" ]; then
        install -m 755 "$1" "$REG_DIR/$name"
    else
        sudo install -m 755 "$1" "$REG_DIR/$name"
    fi || die "не удалось скопировать в $REG_DIR"
    echo "Команда '$name' зарегистрирована: $REG_DIR/$name"
}

# Задача 6. Есть ли комментарий в первой строке файлов .c, .js и .py.
cmd_comments() {
    local dir=${1:-.} file pattern
    [ -d "$dir" ] || die "каталог не найден: $dir"
    find "$dir" -type f \( -name '*.c' -o -name '*.js' -o -name '*.py' \) |
        sort |
        while IFS= read -r file; do
            case "$file" in
                *.py) pattern='^[[:space:]]*#' ;;
                *) pattern='^[[:space:]]*(//|/\*)' ;;
            esac
            if head -n 1 "$file" | grep -qE "$pattern"; then
                echo "есть комментарий: $file"
            else
                echo "нет комментария:  $file"
            fi
        done
}

# Задача 7. Группы файлов с одинаковым содержимым (через пустую строку).
cmd_duplicates() {
    local dir=${1:-.}
    [ -d "$dir" ] || die "каталог не найден: $dir"
    # sha256sum: "<64 символа хеша>  <путь>"; группируем по хешу
    find "$dir" -type f -exec sha256sum {} + |
        sort |
        uniq -w 64 --all-repeated=separate |
        cut -c 67-
}

# Задача 8. Архив tar из всех файлов каталога с заданным расширением.
cmd_archive() {
    [ $# -ge 1 ] || die "использование: archive <расш> [каталог] [архив]"
    local ext=$1 dir=${2:-.}
    local tarball=${3:-${ext}_files.tar}
    [ -d "$dir" ] || die "каталог не найден: $dir"
    if [ -z "$(find "$dir" -type f -name "*.$ext" | head -n 1)" ]; then
        die "файлы *.$ext в '$dir' не найдены"
    fi
    find "$dir" -type f -name "*.$ext" -print0 |
        tar -cvf "$tarball" --null -T -
    echo "Архив создан: $tarball"
}

# Задача 9. Замена последовательностей из 4 пробелов на табуляцию.
cmd_tabs() {
    [ $# -eq 2 ] && [ -f "$1" ] || die "использование: tabs <вход> <выход>"
    sed 's/    /\t/g' "$1" > "$2"
}

# Задача 10. Имена пустых текстовых (.txt) файлов в каталоге.
cmd_empty() {
    [ -d "${1:-}" ] || die "использование: empty <каталог>"
    find "$1" -maxdepth 1 -type f -name '*.txt' -empty -printf '%f\n' |
        sort
}

main() {
    local cmd=${1:-help}
    [ $# -gt 0 ] && shift
    declare -F "cmd_$cmd" >/dev/null ||
        die "неизвестная команда: $cmd (см. pract1.sh help)"
    "cmd_$cmd" "$@"
}

main "$@"
