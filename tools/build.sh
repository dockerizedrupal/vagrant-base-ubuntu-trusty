#!/usr/bin/env bash

DIR=$(dirname "${0}")
DIR=$(cd "${DIR}" && pwd)

cd "${DIR}/.."

vagrant up

rm -rf ./package.box

vagrant package
