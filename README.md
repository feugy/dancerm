[![Build Status][ci-badge]][ci-link] [![Coverage Status][coverage-badge]][coverage-link]

![Logo][logo]

DanceRM is a specialized Customer Relationship software built for Dance schools.

## Crafting new release

DanceRM is now using [electron-builder][builder] to publish new release.
To publish a new one:

1. change version in `package.json`
2. push to github all changes, using PRs
3. Create a github release, tag must be `package.json` version prefixed with `v`. Set title and description, then _save it as draft_.
4. set GH_TOKEN has environment variable
5. run `npm run release`
6. go back to github, and publish your release

## Bugs

- Migrate old invoice
  - items[].discount: null > 0
  - selectedSchool > selectedTeacher
- Conflicts
  - multiple modifications on payments

## TODO

- Invoice & Lesson conflicts
- unit test for indexedDB operator support ($and, $lt, $gt, $lte, $gte)
- Mandatory fields that cannot be bypassed

## TODO Electron

- use afterprint to close print previews
- tests with spectron

## TODO MongoDB

- import > callstack when merging with distant mongo (works fine locally)

[logo]: https://github.com/feugy/dancerm/raw/master/app/style/img/dancerm.png
[ci-badge]: https://travis-ci.org/feugy/dancerm.svg?branch=master
[ci-link]: https://travis-ci.org/feugy/dancerm
[coverage-badge]: https://coveralls.io/repos/github/feugy/dancerm/badge.svg?branch=master
[coverage-link]: https://coveralls.io/github/feugy/dancerm?branch=master
[builder]: https://github.com/electron-userland/electron-builder
[github-releases]: https://help.github.com/articles/creating-releases/