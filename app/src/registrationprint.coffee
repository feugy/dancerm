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

  # fill form
  $('.registration').text _.sprintf i18n.ttl.registrationPrint, planning.season
  $('.firstname').find('label').text i18n.lbl.firstname+i18n.lbl.fieldSeparator
  $('.firstname').find('span').text dancer.firstname

  $('.lastname').find('label').text i18n.lbl.lastname+i18n.lbl.fieldSeparator
  $('.lastname').find('span').text dancer.lastname

  $('.danceclass').find('label').text i18n.lbl.danceClasses+i18n.lbl.fieldSeparator
  $('.danceclass').find('span').text (formatClass id for id in registration.danceClassIds).join ', '

  $('.who, .what, .when, .sign').each ->
    $(@).text i18n.print[$(@).attr 'class']

  $('.print').text(i18n.btn.print).on 'click', ->
    $('.print').remove()
    window.print()
    win.close()