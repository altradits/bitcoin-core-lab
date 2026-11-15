#!/usr/bin/env bash
# Stage 13 outcome checker. Prints PASS/FAIL with a reason. Never prints answers.
# Usage: ./check_13.sh hunt|build|unit|all
# Env: BITCOIN_ROOT (default /Users/mac/bitcoin), BUILD_DIR (default $BITCOIN_ROOT/build)
set -u

LAB_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="13-core-codebase-build-and-unit-tests"
WORK="$LAB_ROOT/my-work/$STAGE"
BITCOIN_ROOT="${BITCOIN_ROOT:-/Users/mac/bitcoin}"
BUILD_DIR="${BUILD_DIR:-$BITCOIN_ROOT/build}"
FAILS=0

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; FAILS=$((FAILS + 1)); }

sha() { printf '%s' "$1" | shasum -a 256 | cut -c1-64; }

check_hunt() {
    local f="$WORK/scavenger.txt"
    if [ ! -f "$f" ]; then fail "hunt: $f not found (see exercises/01_scavenger_hunt.md)"; return; fi
    # Salted hashes "Qnn:<answer>". Answers are the same on 29.x and master.
    local expected="
Q01 4c378e3ef06be949c0d7879ad7db966123088e48e732d81b78c1423037d3e0dc
Q02 8276f6ef708681ad00e5855387591b5ec31aa018df43561282fee76b42976528
Q03 ad3fa772b29627af47f55fbea4c3304328b31bedac3df0016f21bed83d521af5
Q04 691d58056f34ed82fc369c1d23e386982ce76764b9ac9ba0ef6ec7a7d686d29f
Q05 5b563f933bf3468b3200ae6ca016e38470994c2d8f006ad30bfe999d21f42c39
Q06 a5de120addb40185f36094d1abb9f8b78f9eb8c463ca61bc9169f60ccbc861ca
Q07 2a3f7097c94db41fc7ec4c5c247c671f46d572386eafedd5e8ad7c9c86b06aa3
Q08 9fb932440255a16f04486db2fffc3318dc3cd4c7cf40f0e221efd63a06fd86c7
Q09 407554be7c78bc2dcd52f4e1dfcafda69f82acbfb3dcf05dfce93766408a1028
Q10 db5469d8512a38e5c0027f1b79d7de1b78ec131d054de7959bcc1f5a96d9d3ad
Q11 b53b906a279ca2797e7961cbf97347bf38b452702f1bfb7b693d40b6679f1196
Q12 ecc05baf0664ce96058da17bc7a627c827e361d7b306054781930b6b1eb5d2b4
Q13 2016c74318177247dc3a2a33fe1533d2e637ce59df3f64cf1d99e002b8d50ade
Q14 73641e4e3a2ac21dfc0cdd6924f044b4a7360ebad6e890362f6714b932e74d4a
Q15 54ca823c01895131d602057dc0ef852170176a52c3b9235ba1ec1ea8a5fd241e
Q16 de83d95d60938f78d015f7b3074aa7be96f2532412f89e99e338a11d05b17349
Q17 8963295006736abf8cf3595b9cdd2720ff1af0c6f5c592f1579fb2a3ce2cde95"
    local q h line ans
    while read -r q h; do
        [ -z "$q" ] && continue
        line="$(grep -E "^${q}=" "$f" | tail -1)"
        if [ -z "$line" ]; then fail "hunt $q: no answer line"; continue; fi
        ans="${line#*=}"
        ans="$(printf '%s' "$ans" | tr -d '[:space:]')"
        ans="${ans#./}"; ans="${ans#/Users/mac/bitcoin/}"; ans="${ans#\#}"
        if [ "$(sha "$q:$ans")" = "$h" ]; then pass "hunt $q"; else fail "hunt $q: not the expected answer (check definition vs declaration, exact path)"; fi
    done <<< "$expected"
}

check_build() {
    if command -v ccache >/dev/null 2>&1; then pass "build: ccache is installed"; else fail "build: ccache not on PATH (Exercise 2, Part B)"; fi
    local cache="$BUILD_DIR/CMakeCache.txt"
    if [ ! -f "$cache" ]; then fail "build: $cache missing. Configure first"; return; fi
    if grep -q '^CCACHE_EXECUTABLE:FILEPATH=.*NOTFOUND' "$cache"; then
        fail "build: CMake cache says ccache NOTFOUND. Re-run the configure step after installing it"
    elif grep -q '^CCACHE_EXECUTABLE:FILEPATH=' "$cache"; then
        pass "build: CMake found ccache at configure time"
    else
        fail "build: no CCACHE_EXECUTABLE entry in the CMake cache"
    fi
    grep -q '^BUILD_TESTS:BOOL=ON' "$cache" && pass "build: BUILD_TESTS=ON" || fail "build: BUILD_TESTS is not ON"
    local tb="$BUILD_DIR/bin/test_bitcoin"
    if [ -x "$tb" ]; then
        if "$tb" --list_content 2>&1 | grep -q '^serialize_tests'; then pass "build: test_bitcoin runs and lists suites"
        else fail "build: test_bitcoin did not list serialize_tests"; fi
    else
        fail "build: $tb not built yet"
    fi
    local head; head="$(git -C "$BITCOIN_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    if [ "$head" = "HEAD" ] || [ "$head" = "master" ]; then
        fail "build: $BITCOIN_ROOT is on '$head'. Work on a topic branch (Exercise 2, Part 0)"
    else
        pass "build: working on topic branch '$head'"
    fi
}

check_unit() {
    local tf="$BITCOIN_ROOT/src/test/compactsize_boundary_tests.cpp"
    if [ ! -f "$tf" ]; then fail "unit: $tf not found"; return; fi
    pass "unit: test file exists"
    grep -Eq '^BOOST_FIXTURE_TEST_SUITE\(compactsize_boundary_tests, *BasicTestingSetup\)' "$tf" \
        && pass "unit: suite name matches file, smallest fixture" \
        || fail "unit: suite must be compactsize_boundary_tests with the smallest suitable fixture"
    grep -q 'TODO' "$tf" && fail "unit: TODO markers remain" || pass "unit: no TODOs left"
    local n; n="$(grep -c 'BOOST_AUTO_TEST_CASE(' "$tf")"
    [ "$n" -ge 4 ] && pass "unit: $n test cases" || fail "unit: need at least 4 BOOST_AUTO_TEST_CASE, found $n"
    for c in size_boundaries written_length_matches_size round_trip_without_range_check range_check_limits; do
        grep -q "BOOST_AUTO_TEST_CASE($c)" "$tf" && pass "unit: case $c present" || fail "unit: case $c missing"
    done
    grep -q 'compactsize_boundary_tests.cpp' "$BITCOIN_ROOT/src/test/CMakeLists.txt" \
        && pass "unit: registered in src/test/CMakeLists.txt" \
        || fail "unit: not listed in src/test/CMakeLists.txt"
    if git -C "$BITCOIN_ROOT" diff --quiet -- src/serialize.h; then pass "unit: src/serialize.h has no leftover mutation"
    else fail "unit: src/serialize.h is modified. Revert your mutation"; fi
    local tb="$BUILD_DIR/bin/test_bitcoin"
    if [ ! -x "$tb" ]; then fail "unit: $tb missing. Rebuild the test_bitcoin target"; return; fi
    if [ "$tf" -nt "$tb" ]; then fail "unit: test file is newer than test_bitcoin. Rebuild the target first"; return; fi
    if "$tb" --run_test=compactsize_boundary_tests >/tmp/check13_unit.log 2>&1; then
        pass "unit: test_bitcoin --run_test=compactsize_boundary_tests passes"
    else
        fail "unit: suite failed or not compiled in (log: /tmp/check13_unit.log)"
    fi
}

case "${1:-all}" in
    hunt) check_hunt ;;
    build) check_build ;;
    unit) check_unit ;;
    all) check_hunt; check_build; check_unit ;;
    *) echo "usage: $0 hunt|build|unit|all"; exit 2 ;;
esac

echo
if [ "$FAILS" -eq 0 ]; then echo "Stage 13 checks: ALL PASS"; else echo "Stage 13 checks: $FAILS FAIL(s)"; fi
[ "$FAILS" -eq 0 ]
