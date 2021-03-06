#!/bin/bash
#
# Deploy doc site manually or from Travis to branch on GitHub.
#
# Travis requires a GitHub token in order to push changes to `gh-pages`.
# This token can be generated from https://github.com/settings/tokens by
# clicking [Generate new token](https://github.com/settings/tokens/new).
# Copy the token to the clipboard.
#
# Next, install the Travis CLI and encrypt the token:
#
#    $ gem install travis
#    $ travis encrypt GH_TOKEN=<paste-token>
#    Please add the following to your .travis.yml file:
#
#      secure: "..."
#
# Copy the line starting with `secure:` and add it to `.travis.yml`
# under `env` / `global`.
#
#    env:
#      global:
#        secure: "..."
#
# See `.travis.yml` for how to configure Travis to call this script as
# part of the `deploy` build stage.
set -eu -o pipefail

# The output directory for the generated docs.
DOC_DIR="$(pwd)/public"
DOC_BRANCH=master

if [ -z "${GH_TOKEN:-}" ]; then
  REPO_SLUG="$(git config remote.origin.url | sed -n 's#.*[:/]\(.*/.*\).git#\1#p')"
  REPO_URL_PREFIX="git@github.com:"
else
  REPO_SLUG="$TRAVIS_REPO_SLUG"
  REPO_URL_PREFIX="https://$GH_TOKEN@github.com/"
fi

COMMIT="${TRAVIS_COMMIT:-$(git rev-parse HEAD)}"
BUILD_ID="${TRAVIS_BUILD_NUMBER:-$(git symbolic-ref --short HEAD)}"
BUILD_INFO="$REPO_SLUG@$COMMIT ($BUILD_ID)"

REPO_ORG="${REPO_SLUG%/*}"
REPO_NAME="${REPO_SLUG#*/}"
REPO_CACHE=".git/$REPO_ORG.github.io"
REPO_URL="$REPO_URL_PREFIX$REPO_ORG/$REPO_ORG.github.io.git"

git init "$REPO_CACHE"

cd "$REPO_CACHE"

git config user.name "${USER}"
git config user.email "${USER}@${COMMIT}"

git fetch --depth=1 "$REPO_URL"
git reset --hard FETCH_HEAD

rm -rf *.html *.xml about/ css/ js/ fonts/ images/ page/ post/ tags/
cp -a "$DOC_DIR"/* .
git add --all .

if ! git diff --cached --exit-code --quiet; then
  git commit -m "Update $REPO_NAME docs from $BUILD_INFO"
  git push --force --quiet "$REPO_URL" "HEAD:$DOC_BRANCH" > /dev/null 2>&1
fi
