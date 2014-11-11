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

## Bugs or regressions

!!! - model's availability
- search by city
- fix v2 import

## TODOs 

ok - on file print, add address, phone (mobile or fix) and email, and medical certificate mention (from Anthony)
ok - add extra civilities, address and contact into a given file, and specify which person is concerned by a registration
ok - print course's list with name/last name, and empty checkboxes for every next course occurence from the printing date
ok - add payment field: payer, prefilled with dancer's name
ok - merge data from two different PCs with rules: 
     * import files is a single dump file containing all data
     * new imported models are always added
     * existing models not in import are not deleted
     * imported models which id match an existing id: check all fields and resolve manually in case of differences
ok - mandatory fields before saving (civilities, firstname, lastname, address, payment's kind, payer, bank, value), no default values, manual bypass
ok - on payement addition, automatically scroll to bottom, and put focus to first field
ok - add age column (from current date) into expanded list
ok - add another "known-by" choice: "old dancers"
ok - stats on known-by dancers 
ok - address printing from expanded list, with previous selection, file address optimization, and duplicate removal (stamp format from Michelle)

## Hours

03/08 - 0,5
04/08 - 0,5
05/08 - 2
08/08 - 1
09/08 - 8
10/08 - 8
11/08 - 1
12/08 - 3
13/08 - 3
14/08 - 1
15/08 - 0,5
16/08 - 10
17/08 - 0,5
18/08 - 3
19/08 - 2,5
20/08 - 2
21/08 - 2
22/08 - 3
23/08 - 10
30/08 - 9
31/08 - 7
01/09 - 10
06/09 - 5
09/09 - 3
11/09 - 2
13/09 - 3
14/09 - 6
16/09 - 1
20/09 - 2

# Performances enhancement track

1 - replace promise by callback
2 - use raw attributes instead of getters
3 - change NeDB for other in memory storage  