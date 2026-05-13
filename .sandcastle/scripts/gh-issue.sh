#!/usr/bin/env bash
set -euo pipefail

repo="sargon17/Yearlit"
command="${1:-}"
shift || true

case "$command" in
  list-sandcastle)
    # Use REST instead of `gh issue list` because the latter uses GraphQL and can
    # fail when the user's GraphQL quota is exhausted. Keep output compatible
    # with the planner prompt.
    gh api "/repos/${repo}/issues?state=open&labels=Sandcastle&per_page=100" \
      --jq '[.[] | select(.pull_request | not) | {number, title, body, labels: [.labels[].name], comments: []}]'
    ;;
  view)
    issue="${1:?issue number required}"
    issue_json="$(gh api "/repos/${repo}/issues/${issue}")"
    comments_json="$(gh api "/repos/${repo}/issues/${issue}/comments?per_page=100")"
    jq -n --argjson issue "$issue_json" --argjson comments "$comments_json" '
      {
        number: $issue.number,
        title: $issue.title,
        state: $issue.state,
        body: $issue.body,
        labels: [$issue.labels[].name],
        comments: [$comments[].body],
        url: $issue.html_url
      }'
    ;;
  close)
    issue="${1:?issue number required}"
    gh issue close "$issue" --repo "$repo" --comment "Completed by Sandcastle"
    ;;
  *)
    echo "Usage: $0 {list-sandcastle|view <issue>|close <issue>}" >&2
    exit 64
    ;;
esac
