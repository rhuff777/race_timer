# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
@paintIt = (element, backgroundColor, textColor) ->
  element.style.backgroundColor = backgroundColor
  if textColor?
    element.style.color = textColor

@fillIt = (msg) ->
  $( "#run_start" ).val(msg)


$ ->
  $("a[data-background-color]").click (e) ->
    e.preventDefault()
 
    backgroundColor = $(this).data("background-color")
    textColor = $(this).data("text-color")
    paintIt(this, backgroundColor, textColor)
    fillIt("bullshit")

$(document).ready ->
  start_interval = $('#start_interval').data('interval')
  unless start_interval
    start_interval = 60
  last_start = ''
  who = ''

  $("#new_run").on("ajax:success", (e, data, status, xhr) ->
    bib = $("#bib_box").val()
    $('#bib_box').val('')
    last_start = $("#run_start").val()
    if bib != ''
      who = $("#run_start").val() + " " + $("#bib_box").val()
      next_racer = nil
    else
      who = $("#run_start").val() + " " + $("#run_bib").val()
      last_bib = $("#run_bib").val()
      myOpts = document.getElementById('run_bib').options
      next_racer = $("#run_bib").find("option:selected").next().val()
    $("#notice").text("Run successfully staged to start")
    $('#new_run').trigger("reset")
    if next_racer
    	$("#run_bib").val(next_racer)


  ).on "ajax:error", (e, xhr, status, error) ->
    $("#notice").text("Run failed to start")

  setInterval () ->
    dt = new Date()
    coeff = 1000 * start_interval * 1;
    r = new Date(Math.round(dt.getTime() / coeff) * coeff)
    rtime = timeString(r)
    time = timeString(dt)
    $( "#clock" ).text(time)
    if last_start
      $( "#last_time" ).text("Last start: " + last_start)
    if rtime != last_start
      if $( "#run_start" ).val() != rtime
        $( "#run_start" ).val(rtime)
    else
      $( "#run_start" ).val(rtime.substring(0, rtime.length - 2))
  , 1000

  timeString = (r) ->
    rtime = toTwoDigits(r.getHours()) + ":" + toTwoDigits(r.getMinutes()) + ":" + toTwoDigits(r.getSeconds())

  toTwoDigits = (num) ->
    dd = ('0' + num).slice(-2)

  $( "#new_run" ).submit (e) ->
    bibBox = $("#bib_box").val()
    bib = $("#run_bib").val()
    start = $("#run_start").val()

    unless start
      alert "Please wait for a start time"
      return false
    else
      if start.length < 8
      	alert "Invalid start time: hh:mm:ss"
      	return false
    if bibBox or bib
    else
      alert "Please enter a bib (eg. hrkm) or a racer"
      return false
    return true

  convert = () ->
    alert('hey')
  window.convert = convert

  return
