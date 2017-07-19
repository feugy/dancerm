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