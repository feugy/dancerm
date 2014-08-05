'use strict'

gui = require 'nw.gui'
i18n = require '../script/labels/common'
# merge underscore and underscore string functions
_ = require 'underscore'
_str = require 'underscore.string'
_.mixin _str.exports()

# make some variable globals for other scripts
global.gui = gui
global.$ = $

# on DOM loaded
win = gui.Window.get()

# size to A4 format, 3/4 height
win.resizeTo 790, 825

win.once 'loaded', ->
  # get data from mother window
  dancer = window.dancer
  registration = window.registration
  planning = window.planning

  formatClass = (id) ->
    danceClass = _.findWhere planning.danceClasses, id: id
    "#{danceClass.kind} #{danceClass.level}"

  # set application title
  window.document?.title = _.sprintf i18n.ttl.print, dancer.firstname, dancer.lastname

  $('.registration').text _.sprintf i18n.ttl.registrationPrint, planning.season

  # fill form
  for {selector, label, value} in [
    {selector: '.firstname', label: i18n.lbl.firstname, value: dancer.firstname}
    {selector: '.lastname', label: i18n.lbl.lastname, value: dancer.lastname}
    {selector: '.address', label: i18n.lbl.address, value: "#{dancer.address?.street} #{dancer.address?.zipcode} #{dancer.address?.city}"}
    {selector: '.phone', label: i18n.lbl.phone, value: dancer.phone or dancer.cellphone}
    {selector: '.email', label: i18n.lbl.email, value: dancer.email}
    {
      selector: '.danceclass'
      label: if dancer.title in i18n.civilityTitles[1..] then i18n.lbl.registeredFemale else i18n.lbl.registeredMale
      value: (formatClass id for id in registration.danceClassIds).join ', '
    }
  ]
    $(selector).find('label').text label+i18n.lbl.fieldSeparator
    $(selector).find('span').text value

  for selector in ['who', 'what', 'when', 'certificate', 'sign']
    if i18n.print["#{selector}Male"]
      text = i18n.print[if dancer.title in i18n.civilityTitles[1..] then "#{selector}Female" else "#{selector}Male"]
    else
      text = i18n.print[selector]
    $(".#{selector}").text text

  $('.print').text(i18n.btn.print).on 'click', ->
    $('.print').remove()
    window.print()
    win.close()