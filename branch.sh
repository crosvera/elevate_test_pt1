#!/usr/bin/bash

NEXTVER=$1
git config user.name "GitHub Actions"
git config user.email noreply@github.com
git checkout -b release/$NEXTVER
git push origin release/$NEXTVER
