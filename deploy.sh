#!/bin/bash

##########################################################
# gh-pages deployment script for Travis CI               #                         
#                                                        #
# Deploys everything from the provided path to gh-pages  #
# To be called from the project’s root on Travis CI      #
##########################################################

# fail the script if any command fails
set -e
# Don't return a glob pattern if it doesn't match anything
shopt -s nullglob

if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
	echo "We won't deploy because we're on a pull request."
	exit 0
fi

# If GH_TOKEN is not set, we'll exit gracefully
if [ -z ${GH_TOKEN:+1} ]; then
	echo "The GH_TOKEN ENV is not set. Thus, we won't deploy to gh-pages."
	# Don't fail because maybe this fork's owner simply doesn't want to deploy.
	exit 0
fi

ARTIFACTS="$*"
if [ -z ${ARTIFACTS:+1} ]; then
	echo "No path to artifacts to deploy were provided"
	exit 1
fi

PUBLISH="`readlink -m ../publish`"
BASE=$PWD
REPO_NAME=$(echo "$TRAVIS_REPO_SLUG" | cut -f2 -d/)
REPO_OWNER=$(echo "$TRAVIS_REPO_SLUG" | cut -f1 -d/)
mkdir -p $PUBLISH
cd $PUBLISH

REPO="https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}.git"

function set_git_user {
	git config user.name "Travis CI"
	git config user.email "travis@example.org"
}

echo "# Artifacts of $REPO_NAME
Built artifacts of $REPO_NAME$([ $TRAVIS_BRANCH != "master" ] && echo " (from branch $TRAVIS_BRANCH)"), \
published on [GitHub pages](https://$REPO_OWNER.github.io/$REPO_NAME$([ $TRAVIS_BRANCH == "master" ] || echo "/branches/$TRAVIS_BRANCH"))." > README.md

# Check if gh-pages already exists
if [ `git ls-remote --heads $REPO branch gh-pages | wc -l` == 1 ]
then
	git clone $REPO .
	echo "Continuing existing branch gh-pages"
	set_git_user
else
	git init
	set_git_user
				
	echo "Creating new branch gh-pages"
	git add .
	git commit -m "gh-pages created by Travis CI"
	git branch --no-track gh-pages
fi
git checkout gh-pages


# Remove deleted branches' directories
for branchpath in branches/*
do
 	branch=$(basename $branchpath)
	git rev-parse --verify origin/$branch > /dev/null 2>&1 || (echo "Removing obsolete branch folder of $branch"; git rm -rfq branches/$branch)
done


# Deploy the master branch to the top most folder, but all other branches to subfolders
[ $TRAVIS_BRANCH == "master" ] && pubdir="." || pubdir="branches/$TRAVIS_BRANCH"
mkdir -p "$pubdir"
cd "$pubdir"

# Remove all content - except the git files and the branches folder
find . -maxdepth 1 \! \( -name .git -o -name . -o -name branches -o -name README.md \) -exec rm -rf {} \;

# Keep gh-pages from considering some resources as "special" and hiding them
cd $PUBLISH
touch .nojekyll

# Copy in the artifacts
cd $BASE
cp -r $ARTIFACTS "$PUBLISH/$pubdir"
cd $PUBLISH

git add --all .
git commit -m "Travis build of $TRAVIS_BRANCH ($TRAVIS_COMMIT_RANGE)"

# Push from the current repo's gh-pages branch to the remote
# repo's gh-pages branch. We redirect any output to
# /dev/null to hide any sensitive credential data that might otherwise be exposed.
git push --quiet $REPO gh-pages:gh-pages > /dev/null 2>&1

cd $BASE

