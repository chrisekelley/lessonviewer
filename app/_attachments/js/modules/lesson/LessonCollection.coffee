class LessonCollection extends Backbone.Collection

  url : "lessons"
  model : Lesson
  db:
    view: "lessonByDayWeekSubject"

  # By default include the docs
#  fetch: (options) ->
#    options = {} unless options?
#    options.include_docs = true unless options.include_docs?
#    super(options)