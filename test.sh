#!/bin/sh

docker-compose build simple-repo-test-s || exit

docker-compose up -d --build simple-repo-postgres-test-s

docker-compose run simple-repo-test-s

docker-compose down
