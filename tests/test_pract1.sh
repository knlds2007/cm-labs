#!/bin/bash
# Тесты для src/pract1.sh. Запуск: ./run.sh test

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SCRIPT="$ROOT/src/pract1.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

passed=0
failed=0

# Сравнить фактический вывод с ожидаемым.
check() {
    local name=$1 expected=$2 actual=$3
    if [ "$expected" = "$actual" ]; then
        echo "ok   $name"
        passed=$((passed + 1))
    else
        echo "FAIL $name"
        echo "  ожидалось: $(printf '%q' "$expected")"
        echo "  получено:  $(printf '%q' "$actual")"
        failed=$((failed + 1))
    fi
}

run() {
    bash "$SCRIPT" "$@" 2>&1
}

cd "$TMP" || exit 1

# 1. users
printf '# comment\nroot:x:0:0::/root:/bin/bash\nbob:x:1000:1000::/:/bin/sh\n' \
    > passwd
check "users" "$(printf 'bob\nroot')" "$(run users passwd)"

# 2. protocols
cat > protocols <<'DATA'
# Internet protocols
hip      139  HIP
manet    138  manet
rohc     142  ROHC
wesp     141  WESP
shim6    140  Shim6
icmp     1    ICMP

DATA
check "protocols" \
    "$(printf '142 rohc\n141 wesp\n140 shim6\n139 hip\n138 manet')" \
    "$(run protocols protocols)"

# 3. banner
check "banner" \
    "$(printf '+--------+\n| Hello! |\n+--------+')" \
    "$(run banner 'Hello!')"
check "banner без аргументов" "pract1: использование: banner <текст>" \
    "$(run banner)"

# 4. identifiers
printf '#include <stdio.h>\n\nint main(void) {\n' > hello.c
printf '    printf("hello world\\n");\n    return 0;\n}\n' >> hello.c
check "identifiers" \
    "h hello include int main n printf return stdio void world " \
    "$(run identifiers hello.c)"

# 5. reg (в тестовый каталог вместо /usr/local/bin)
mkdir bin
REG_DIR="$TMP/bin" bash "$SCRIPT" reg "$SCRIPT" mycmd >/dev/null
check "reg: права 755" "755" "$(stat -c '%a' bin/mycmd)"

# 6. comments
mkdir src
echo '// c' > src/a.c
echo 'int x;' > src/b.c
echo '# py' > src/c.py
check "comments" \
    "$(printf 'есть комментарий: src/a.c\nнет комментария:  src/b.c\n')
есть комментарий: src/c.py" \
    "$(run comments src)"

# 7. duplicates
mkdir -p dup/sub
echo same > dup/a.txt
echo same > dup/sub/b.txt
echo other > dup/c.txt
check "duplicates" "$(printf 'dup/a.txt\ndup/sub/b.txt')" \
    "$(run duplicates dup)"

# 8. archive
run archive txt dup out.tar >/dev/null
check "archive" "$(printf 'dup/a.txt\ndup/c.txt\ndup/sub/b.txt')" \
    "$(tar -tf out.tar | sort)"
check "archive: нет файлов" "pract1: файлы *.md в 'dup' не найдены" \
    "$(run archive md dup)"

# 9. tabs
printf 'a\n    b\n        c\n' > in.txt
run tabs in.txt out.txt
check "tabs" "$(printf 'a\n\tb\n\t\tc')" "$(cat out.txt)"

# 10. empty
mkdir files
: > files/empty.txt
: > files/empty.c
echo text > files/full.txt
check "empty" "empty.txt" "$(run empty files)"

check "неизвестная команда" \
    "pract1: неизвестная команда: foo (см. pract1.sh help)" "$(run foo)"

echo
echo "Пройдено: $passed, провалено: $failed"
[ "$failed" -eq 0 ]
