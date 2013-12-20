# Displays a lesson with audio and image(s)
#
class LessonView extends Backbone.View

  el: $("#content")

  initialize: ( options ) ->
    @lesson = options.model

  onClickDiv: ( event ) ->
    # I use this idiom a lot, of course, feel free to use whatever you like.
    $target = $(event.target)
    data = $target.attr("data-some-data")

  render : ->

    day        = @lesson.get("day")
    week        = @lesson.get("week")
    grade      = @lesson.get("grade")
    lessonText = @lesson.get("lessonText")

    imageUrls  = @lesson.get("image")
    audioUrls  = @lesson.get("audio")

    imageHtml = ("<img src=/lessonviewer/_design/lessonplanner/#{url}>" for url in imageUrls).join('')
    audioHtml = ("<audio controls=’’ preload=’non’><source src=/lessonviewer/_design/lessonplanner/#{url}></audio>" for url in audioUrls).join('')

    @$el.html "
    <h1>Lesson week #{week}, day #{day}</h1>
    <div class=’image-container’>#{imageHtml}</div>
    <div class=’audio-container’>#{audioHtml}</div>
    <div class=’lesson-text’>#{lessonText}</div>
    "

