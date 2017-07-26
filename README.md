[![Build Status][ci-badge]][ci-link] [![Coverage Status][coverage-badge]][coverage-link]

![Logo][logo]

DanceRM is a specialized Customer Relationship software built for Dance schools.


## Bugs

- Invoice Ref unicity based on selected teacher
- Migrate old invoice
  - items[].discount: null > 0
  - selectedSchool > selectedTeacher
- Conflicts
  - multiple modifications on payments

## TODO

- splash screen
- hide empty days in planning
- Invoice & Lesson conflicts
- unit test for indexedDB operator support ($and, $lt, $gt, $lte, $gte)
- Mandatory fields that cannot be bypassed

## TODO Electron

- tests with spectron

## TODO MongoDB

- import > callstack when merging with distant mongo (works fine locally)

[logo]: https://github.com/feugy/dancerm/raw/master/app/src/style/img/dancerm.png
[ci-badge]: https://travis-ci.org/feugy/dancerm.svg?branch=master
[ci-link]: https://travis-ci.org/feugy/dancerm
[coverage-badge]: https://coveralls.io/repos/github/feugy/dancerm/badge.svg?branch=master
[coverage-link]: https://coveralls.io/github/feugy/dancerm?branch=master