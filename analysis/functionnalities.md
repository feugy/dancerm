# Version 2

## TODOs

- stats (by creation date, by teachers, by year...)
- pre-registration status
- registration free text
- fully test import error cases

## Functionnal requirements

- Have a list of dancers.
- Distinguish dancers by teachers (legal requirement) (2'45)
- Send new year schedule
- alert unpaid classes (by classes)
- alert on missing medical certificate
- select email list for external mailing (export as list)
- print invoice

Enroll dancers:
- manually (multiple) and enter afterwise
- internet enroll (print and write, or write and print) with manual check
- live enroll

List dancers:
- by N last year
- by teachers
- by class
- by unpaid

Dancer information (4'00)
- registration date
- title
- firstname
- lastname
- street
- zipcode
- city
- phone
- email
- first and last enroll year
- birth year
- medical certifical
- classes (and by class)
  - enroll duration (year, quarter)
  - account balance
  - payment type (if bank check, name)

## Hours

- 08/08/13 3h
- 09/08/13 2h
- 10/08/13 3h
- 11/08/13 4h
- 12/08/13 2h
- 13/08/13 6h
- 14/08/13 2h
- 15/08/13 6h
- 16/08/13 5h
- 17/08/13 3h
- 19/08/13 4h
- 20/08/13 4h
- 21/08/13 5h
- 22/08/13 4h
- 23/08/13 2h
- 24/08/13 6h
- 25/08/13 3h
- 26/08/13 2h
- 27/08/13 2h
- 28/08/13 1h
- 29/08/13 2h
- 30/08/13 0
- 31/08/13 8h
- 01/09/13 12h
- 02/09/13 2h
- 04/09/13 5h
- 05/09/13 2h
- 06/09/13 2h
- 07/09/13 4h
- 09/09/13 1h
- 15/09/13 3h

Paid: 110h 10€/h

# Version 3

## Bugs or regressions

- search by city
- fix v2 import

## Features

- on file print, add address, phone (mobile or fix) and email, and medical certificate mention (from Anthony)
- add extra civilities, address and contact into a given file, and specify which person is concerned by a registration
- print course's list with name/last name, and empty checkboxes for every next course occurence from the printing date
- add payment field: payer, prefilled with dancer's name
- merge data from two different PCs with rules:
     - import files is a single dump file containing all data
     - new imported models are always added
     - existing models not in import are not deleted
     - imported models which id match an existing id: check all fields and resolve manually in case of differences
- mandatory fields before saving (civilities, firstname, lastname, address, payment's kind, payer, bank, value), no default values, manual bypass
- on payement addition, automatically scroll to bottom, and put focus to first field
- add age column (from current date) into expanded list
- add another "known-by" choice: "old dancers"
- stats on known-by dancers
- address printing from expanded list, with previous selection, file address optimization, and duplicate removal (stamp format from Michelle)
- performances enhancement
- UI theming
- external libraries updates

## Hours

- 03/08/14 - 0,5
- 04/08/14 - 0,5
- 05/08/14 - 2
- 08/08/14 - 1
- 09/08/14 - 8
- 10/08/14 - 8
- 11/08/14 - 1
- 12/08/14 - 3
- 13/08/14 - 3
- 14/08/14 - 1
- 15/08/14 - 0,5
- 16/08/14 - 10
- 17/08/14 - 0,5
- 18/08/14 - 3
- 19/08/14 - 2,5
- 20/08/14 - 2
- 21/08/14 - 2
- 22/08/14 - 3
- 23/08/14 - 10
- 30/08/14 - 9
- 31/08/14 - 7
- 01/09/14 - 10
- 06/09/14 - 5
- 09/09/14 - 3
- 11/09/14 - 2
- 13/09/14 - 3
- 14/09/14 - 6
- 16/09/14 - 1
- 20/09/14 - 2

Paid: 108h 10€/h

- 27/09/14 - 5
- 05/10/14 - 2
- 11/11/14 - 10
- 21/11/14 - 8
- 24/11/14 - 8
- 26/11/14 - 8
- 27/11/14 - 1
- 06/12/14 - 6
- 27/12/14 - 4
- 28/12/14 - 1
- 29/12/14 - 6
- 31/12/14 - 4
- 01/01/15 - 2
- 02/01/15 - 1
- 04/01/15 - 2
- 07/01/15 - 1
- 29/01/15 - 2
- 31/01/15 - 3
- 22/08/15 - 2
- 23/08/15 - 10
- 25/08/15 - 1
- 26/08/15 - 1
- 27/08/15 - 2

Paid: 55 10€/h