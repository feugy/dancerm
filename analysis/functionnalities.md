# Version 2

## TODOs

- stats (by creation date, by teachers, by year...)
- pre-registration status
- registration free text
- fully test import error cases

## Functionnal requirements

ok - Have a list of dancers.
ok - Distinguish dancers by teachers (legal requirement) (2'45)
ok - Send new year schedule
ok - alert unpaid classes (by classes)
ok - alert on missing medical certificate
ok - select email list for external mailing (export as list)
ok - print invoice

Enroll dancers:
ok - manually (multiple) and enter afterwise
- internet enroll (print and write, or write and print) with manual check
ok - live enroll

List dancers:
ok - by N last year
ok - by teachers
ok - by class
ok - by unpaid

Dancer information (4'00) 
ok - registration date
ok - title
ok - firstname
ok - lastname
ok - street
ok - zipcode
ok - city
ok - phone
ok - email
ok - first and last enroll year
ok - birth year
ok - medical certifical 
- classes (and by class)
  ok - enroll duration (year, quarter)
  ok - account balance 
  ok - payment type (if bank check, name)

## Hours

08/08 3h
09/08 2h
10/08 3h
11/08 4h
12/08 2h
13/08 6h
14/08 2h
- 22h
15/08 6h
16/08 5h
17/08 3h
19/08 4h
20/08 4h
21/08 5h
22/08 4h
- 31h
23/08 2h
24/08 6h
25/08 3h
26/08 2h
27/08 2h
28/08 1h
29/08 2h
- 18h
30/08 0
31/08 8h
01/09 12h
02/09 2h
- 22h
04/09 5h
05/09 2h
06/09 2h
07/09 4h
09/09 1h
14h

15/09 3h

Paid: 110h 10€/h

# Version 3

## Bugs

- disable back support

## TODOs 

! - migrate old storage to nedb
! - leverage export with compacted nedb (with new knownBy status)
- incorporate/separate existing dancer to another card
- incorporate an existing dancer on an existing address of the same card address
- fix import
- fix export
- list sort

ok - on file print, add address, phone (mobile or fix) and email, and medical certificate mention (from Anthony)
ok - add extra civilities, address and contact into a given file, and specify which person is concerned by a registration
 3 - print course's list with name/last name, and empty checkboxes for every next course occurence from the printing date
ok - add payment field: payer, prefilled with dancer's name
11 - merge data from two different PCs
ok - mandatory fields before saving (civilities, firstname, lastname, address, payment's kind, payer, bank, value), no default values, manual bypass
ok - on payement addition, automatically scroll to bottom, and put focus to first field
ok - add age column (from current date) into expanded list
ok - add another "known-by" choice: "old dancers"
 6 - stats on known-by dancers 
 8 - address printing from expanded list, with previous selection, file address optimization, and duplicate removal (stamp format from Michelle)


## Functionnal requirements

- Manage mupltiple dancers in one file
- Synchronize data from multiple PCs
- Print stamps for mailing
- Stats on dancers origin (known-by)
- Have a free field in payments
- Have mandatory fields before saving

## Hours

03/08 - 0,5
04/05 - 0,5
05/05 - 2
08/05 - 1
09/05 - 8
10/05 - 8
11/05 - 1
12/05 - 3
13/05 - 3
14/05 - 1
15/05 - 0,5
16/05 - 10
17/05 - 0,5
18/05 - 3
19/06 - 2,5
20/06 - 2
21/06 - 2
22/06 - 3
23/06 - 7h-11h