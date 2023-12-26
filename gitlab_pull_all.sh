#!/usr/bin/env bash

# Documentation
# https://docs.gitlab.com/ce/api/projects.html#list-projects

NAMESPACE="idp"
BASE_PATH="https://git.gitlab.com/"
PROJECT_SEARCH_PARAM=""
PROJECT_SELECTION="select(.namespace.name == \"idp\")"
PROJECT_PROJECTION="{ "path": .path, "git": .ssh_url_to_repo }"

if [ -z "$GITLAB_PRIVATE_TOKEN" ]; then
    echo "Please set the environment variable GITLAB_PRIVATE_TOKEN"
    echo "See ${BASE_PATH}profile/account"
    exit 1
fi

FILENAME="repos.json"

trap "{ rm -f $FILENAME; }" EXIT

curl -s "${BASE_PATH}api/v3/projects?private_token=$GITLAB_PRIVATE_TOKEN&search=$PROJECT_SEARCH_PARAM&per_page=999" \
    | jq --raw-output --compact-output ".[] | $PROJECT_SELECTION | $PROJECT_PROJECTION" > "$FILENAME"

while read repo; do
    THEPATH=$(echo "$repo" | jq -r ".path")
    GIT=$(echo "$repo" | jq -r ".git")
    
    if [ ! -d "$THEPATH" ]; then
        echo "Cloning $THEPATH ( $GIT )"
        git clone "$GIT" --quiet &
    else
        echo "Pulling $THEPATH"
        (cd "$THEPATH" && git pull --quiet) &
    fi
done < "$FILENAME"

wait