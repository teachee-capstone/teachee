## Development

```sh
# setup rust toolchain (see https://rustup.rs/)
$ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# run app
$ cargo run
# run app with mock usb
$ cargo run -- -m <mock-csv-path>
# run tests
$ cargo test
# format code
$ cargo fmt
# run ci checks
$ cargo xtask
```

## Pre-Commit Checks

A git hook can automatically run CI checks on staged changes for every commit.
Simply copy the following script into `$TEACHEE/.git/hooks/pre-commit` and set
it as executable.

```sh
#!/bin/sh

set -e

git stash push --include-untracked --keep-index --quiet --message='Backed up state for the pre-commit hook (if you can see it, something went wrong)'

(cd software/teachee-desktop/ && cargo xtask ci)
status=$?

git reset --hard --quiet
git clean -d --force --quiet
git stash pop --index --quiet

exit $status
```
