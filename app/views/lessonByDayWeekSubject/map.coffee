(doc) ->

  emit [doc.subject, doc.week, doc.day], doc if doc.subject and doc.week and doc.day
