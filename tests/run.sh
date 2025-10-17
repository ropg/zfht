#!/bin/sh

MODE=$1 # 'write' (re)writes expected.

fail() { echo "TEST FAIL: $*" >&2; exit 1; }
info() { echo "[info] $*" >&2; }

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT INT TERM

# Prepare sandbox with testdir/master
mkdir -p "$WORKDIR"
cp -R "tests/testdir" "$WORKDIR/"
ZONESDIR="$WORKDIR/testdir"
ZONESSUBDIR=master

OUTDIR="$WORKDIR/out"
mkdir -p "$OUTDIR"
EXPECTED_DIR="tests/expected"
[ "$MODE" = "write" ] && rm -rf "$EXPECTED_DIR" && mkdir -p "$EXPECTED_DIR"

# Export vars for test commands
export ZONESDIR ZONESSUBDIR WORKDIR

# Add current directory to front of PATH so we run our own commands from it.
export PATH="$(pwd):$PATH"

# Override today's date so test output is deterministic.
# This is used by zfht-update-serial to generate the next serial number.
# Just needs to be after any date in test files.
export ZFHT_TODAY=20260303

# shorthand
M=$ZONESDIR/$ZONESSUBDIR

TOTAL=0
PASSED=0
FAILED=0

while read -r cmd; do
    [ -z "$cmd" ] && continue
    TOTAL=$((TOTAL+1))
    printf "Test #$TOTAL: $cmd ... "
    FILENUM=$(printf "%02d" $TOTAL)
    outfile="$OUTDIR/test_$FILENUM"
    expected="$EXPECTED_DIR/test_$FILENUM"
    IFS=';'; for cmdpart in $cmd; do
        # Run command capturing both stdout and stderr
        echo "\$ ${cmdpart# }" >>"$outfile"
        eval "$cmdpart" >>"$outfile" 2>&1
        # Append non-zero return code to output file so it is matched too.
        e=$?; [ "$e" -ne 0 ] && echo "Returned: $e" >>"$outfile"
        echo "" >>"$outfile"
    done

    if [ "$MODE" = "write" ]; then
        cp "$outfile" "$expected"
        echo "wrote $expected"
        continue
    fi

    if [ ! -f "$expected" ]; then
        echo "missing expected file $expected"
        FAILED=$((FAILED+1))
        continue
    fi

    if diff -u "$expected" "$outfile" >/dev/null 2>&1; then
        echo "passed"
        PASSED=$((PASSED+1))
    else
        echo "mismatch"
        diff -u "$expected" "$outfile"
        FAILED=$((FAILED+1))
    fi
done < tests/commands.txt

if [ "$MODE" = "write" ]; then
    echo "Wrote expected outputs to $EXPECTED_DIR"
    exit 0
fi

# Summarize
echo "Passed: $PASSED / $TOTAL"
[ "$FAILED" -eq 0 ] || fail "$FAILED out of $TOTAL tests failed"
echo "All tests passed"
exit 0
