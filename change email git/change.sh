#!/bin/bash

set -e

repo="https://github.com/MyUserName/RandomStuff"
name="${repo##*/}"

rm -rf "$name.git"
git clone --mirror "$repo"

cd "$name.git"

echo "Emails before:"
git log --all --format='%ae' | sort -u

git filter-repo --email-callback '
    old = {
        b"oldEmail1@example.com",
        b"oldEmail2@example.com",
        b"oldEmail3@example.com",
    }
    return b"newEmail@example.com" if email in old else email
'

echo
echo "Emails after:"
git log --all --format='%ae' | sort -u

git remote add origin "$repo"

git push --force --mirror origin

cd ..
