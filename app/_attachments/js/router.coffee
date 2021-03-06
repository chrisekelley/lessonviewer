class Router extends Backbone.Router
  routes:
    'lesson/:subject/:week/:day'    : 'lesson'
    'login'    : 'login'
    'register' : 'register'
    'logout'   : 'logout'
    'account'  : 'account'

    'transfer' : 'transfer'

    'settings' : 'settings'
    'update' : 'update'

    '' : 'landing'

    'logs' : 'logs'

    # Tutor

    'workflow/edit/:id' : 'workflowEdit'
    'workflow/run/:id'  : 'workflowRun'

    'feedback/edit/:id' : 'feedbackEdit'

    # Class
    'class'          : 'klass'
    'class/edit/:id' : 'klassEdit'
    'class/student/:studentId'        : 'studentEdit'
    'class/student/report/:studentId' : 'studentReport'
    'class/subtest/:id' : 'editKlassSubtest'
    'class/question/:id' : "editKlassQuestion"

    'class/:id/:part' : 'klassPartly'
    'class/:id'       : 'klassPartly'

    'class/run/:studentId/:subtestId' : 'runSubtest'

    'class/result/student/subtest/:studentId/:subtestId' : 'studentSubtest'

    'curricula'         : 'curricula'
    'curriculum/:id'    : 'curriculum'
    'curriculumImport'  : 'curriculumImport'

    'report/klassGrouping/:klassId/:part' : 'klassGrouping'
    'report/masteryCheck/:studentId'      : 'masteryCheck'
    'report/progress/:studentId/:klassId' : 'progressReport'

    'teachers' : 'teachers'


    # server / mobile
    'groups' : 'groups'

    'assessments'        : 'lesson'

    'run/:id'       : 'run'
    'print/:id/:format'       : 'print'
    'dataEntry/:id' : 'dataEntry'

    'resume/:assessmentId/:resultId'    : 'resume'
    
    'restart/:id'   : 'restart'
    'edit/:id'      : 'edit'
    'results/:id'   : 'results'
    'import'        : 'import'
    
    'subtest/:id'       : 'editSubtest'

    'question/:id' : 'editQuestion'
    'dashboard' : 'dashboard'
    'dashboard/*options' : 'dashboard'
    'admin' : 'admin'

    'sync/:id'      : 'sync'

    
  admin: (options) ->
    Tangerine.user.verify
      isAdmin: ->
        $.couch.allDbs
          success: (databases) =>
            groups = databases.filter (database) -> database.indexOf("group-") == 0
            view = new AdminView
              groups : groups
            vm.show view
    
  dashboard: (options) ->
    options = options?.split(/\//)
    #default view options
    reportViewOptions =
      assessment: "All"
      groupBy: "enumerator"

    # Allows us to get name/value pairs from URL
    _.each options, (option,index) ->
      unless index % 2
        reportViewOptions[option] = options[index+1]

    view = new DashboardView()
    view.options = reportViewOptions
    vm.show view

  workflowEdit: ( workflowId ) ->
    workflow = new Workflow "_id" : workflowId
    workflow.fetch
      success: ->
        view = new WorkflowEditView workflow : workflow
        vm.show view

  feedbackEdit: ( feedbackId ) ->
    feedback = new Feedback "_id" : feedbackId
    feedback.fetch
      success: ->
        view = new FeedbackEditView feedback : feedback
        vm.show view

  workflowRun: ( workflowId ) ->
    workflow = new Workflow "_id" : workflowId
    workflow.fetch
      success: ->
        workflow.updateCollection()
        view = new WorkflowRunView
          workflow: workflow
        vm.show view



  landing: ->

    Tangerine.settings.contextualize
      server: ->
        if ~String(window.location.href).indexOf("tangerine/_design") # in main group?
          Tangerine.router.navigate "groups", true
        else
          Tangerine.router.navigate "assessments", true
      satellite: ->
        Tangerine.router.navigate "assessments", true
      mobile: ->
        Tangerine.router.navigate "assessments", true
      klass: ->
        Tangerine.router.navigate "class", true

  groups: ->
    Tangerine.user.verify
      isAuthenticated: ->
        view = new GroupsView
        vm.show view

  #
  # Class
  #
  curricula: ->
    Tangerine.user.verify
      isAuthenticated: ->
        curricula = new Curricula
        curricula.fetch
          success: (collection) ->
            view = new CurriculaView
              "curricula" : collection
            vm.show view

  curriculum: (curriculumId) ->
    Tangerine.user.verify
      isAuthenticated: ->
        curriculum = new Curriculum "_id" : curriculumId
        curriculum.fetch
          success: ->
            allSubtests = new Subtests
            allSubtests.fetch
              success: ->
                subtests = new Subtests allSubtests.where "curriculumId" : curriculumId
                allQuestions = new Questions
                allQuestions.fetch
                  success: ->
                    questions = []
                    subtests.each (subtest) -> questions = questions.concat(allQuestions.where "subtestId" : subtest.id )
                    questions = new Questions questions
                    view = new CurriculumView
                      "curriculum" : curriculum
                      "subtests"   : subtests
                      "questions"  : questions

                    vm.show view


  curriculumEdit: (curriculumId) ->
    Tangerine.user.verify
      isAuthenticated: ->
        curriculum = new Curriculum "_id" : curriculumId
        curriculum.fetch
          success: ->
            allSubtests = new Subtests
            allSubtests.fetch
              success: ->
                subtests = allSubtests.where "curriculumId" : curriculumId
                allParts = (subtest.get("part") for subtest in subtests)
                partCount = Math.max.apply Math, allParts 
                view = new CurriculumView
                  "curriculum" : curriculum
                  "subtests" : subtests
                  "parts" : partCount
                vm.show view


  curriculumImport: ->
    Tangerine.user.verify
      isAuthenticated: ->
        view = new AssessmentImportView
          noun : "curriculum"
        vm.show view

  klass: ->
    Tangerine.user.verify
      isAuthenticated: ->
        allKlasses = new Klasses
        allKlasses.fetch
          success: ( klassCollection ) ->
            teachers = new Teachers
            teachers.fetch
              success: ->
                allCurricula = new Curricula
                allCurricula.fetch
                  success: ( curriculaCollection ) ->
                    if not Tangerine.user.isAdmin()
                      klassCollection = new Klasses klassCollection.where("teacherId" : Tangerine.user.get("teacherId"))
                    view = new KlassesView
                      klasses   : klassCollection
                      curricula : curriculaCollection
                      teachers  : teachers
                    vm.show view

  klassEdit: (id) ->
    Tangerine.user.verify
      isAuthenticated: ->
        klass = new Klass _id : id
        klass.fetch
          success: ( model ) ->
            teachers = new Teachers
            teachers.fetch
              success: ->
                allStudents = new Students
                allStudents.fetch
                  success: (allStudents) ->
                    klassStudents = new Students allStudents.where {klassId : id}
                    view = new KlassEditView
                      klass       : model
                      students    : klassStudents
                      allStudents : allStudents
                      teachers    : teachers
                    vm.show view

  klassPartly: (klassId, part=null) ->
    Tangerine.user.verify
      isAuthenticated: ->
        klass = new Klass "_id" : klassId
        klass.fetch
          success: ->
            curriculum = new Curriculum "_id" : klass.get("curriculumId")
            curriculum.fetch
              success: ->
                allStudents = new Students
                allStudents.fetch
                  success: (collection) ->
                    students = new Students ( collection.where( "klassId" : klassId ) )

                    allResults = new KlassResults
                    allResults.fetch
                      success: (collection) ->
                        results = new KlassResults ( collection.where( "klassId" : klassId ) )

                        allSubtests = new Subtests
                        allSubtests.fetch
                          success: (collection ) ->
                            subtests = new Subtests ( collection.where( "curriculumId" : klass.get("curriculumId") ) )
                            view = new KlassPartlyView
                              "part"       : part
                              "subtests"   : subtests
                              "results"    : results
                              "students"   : students
                              "curriculum" : curriculum
                              "klass"      : klass
                            vm.show view


  studentSubtest: (studentId, subtestId) ->
    Tangerine.user.verify
      isAuthenticated: ->
        student = new Student "_id" : studentId
        student.fetch
          success: ->
            subtest = new Subtest "_id" : subtestId
            subtest.fetch
              success: ->
                Tangerine.$db.view "#{Tangerine.design_doc}/resultsByStudentSubtest",
                  key : [studentId,subtestId]
                  success: (response) =>
                    allResults = new KlassResults 
                    allResults.fetch
                      success: (collection) ->
                        results = collection.where
                          "subtestId" : subtestId
                          "studentId" : studentId
                          "klassId"   : student.get("klassId")
                        view = new KlassSubtestResultView
                          "allResults" : allResults
                          "results"  : results
                          "subtest"  : subtest
                          "student"  : student
                          "previous" : response.rows.length
                        vm.show view

  runSubtest: (studentId, subtestId) ->
    Tangerine.user.verify
      isAuthenticated: ->
        subtest = new Subtest "_id" : subtestId
        subtest.fetch
          success: ->
            student = new Student "_id" : studentId

            # this function for later, real code below
            onStudentReady = (student, subtest) ->
              student.fetch
                success: ->

                  # this function for later, real code below
                  onSuccess = (student, subtest, question=null, linkedResult={}) ->
                    view = new KlassSubtestRunView
                      "student"      : student
                      "subtest"      : subtest
                      "questions"    : questions
                      "linkedResult" : linkedResult
                    vm.show view

                  questions = null
                  if subtest.get("prototype") == "survey"
                    Tangerine.$db.view "#{Tangerine.design_doc}/resultsByStudentSubtest",
                      key : [studentId,subtest.get("gridLinkId")]
                      success: (response) =>
                        if response.rows != 0
                          linkedResult = new KlassResult _.last(response.rows)?.value
                        questions = new Questions
                        questions.fetch
                          key: subtest.get("curriculumId")
                          success: ->
                            questions = new Questions(questions.where {subtestId : subtestId })
                            onSuccess(student, subtest, questions, linkedResult)
                  else
                    onSuccess(student, subtest)
              # end of onStudentReady

            if studentId == "test"
              student.fetch
                success: -> onStudentReady( student, subtest)
                error: ->
                  student.save null,
                    success: -> onStudentReady( student, subtest)
            else
              student.fetch
                success: ->
                  onStudentReady(student, subtest)

  register: ->
    Tangerine.user.verify
      isUnregistered: ->
        view = new RegisterTeacherView
          user : new User
        vm.show view
      isAuthenticated: ->
        Tangerine.router.navigate "", true

  studentEdit: ( studentId ) ->
    Tangerine.user.verify
      isAuthenticated: ->
        student = new Student _id : studentId
        student.fetch
          success: (model) ->
            allKlasses = new Klasses
            allKlasses.fetch
              success: ( klassCollection )->
                view = new StudentEditView
                  student : model
                  klasses : klassCollection
                vm.show view


  #
  # Assessment
  #


  dataEntry: ( assessmentId ) ->
    Tangerine.user.verify
      isAdmin: ->    
        assessment = new Assessment "_id" : assessmentId
        assessment.fetch
          success: ->
            questions = new Questions
            questions.fetch
              key: assessmentId
              success: ->
                questionsBySubtestId = questions.indexBy("subtestId")
                for subtestId, questions of questionsBySubtestId
                  assessment.subtests.get(subtestId).questions = new Questions questions
                vm.show new AssessmentDataEntryView assessment: assessment



  sync: ( assessmentId ) ->
    Tangerine.user.verify
      isAdmin: ->    
        assessment = new Assessment "_id" : assessmentId
        assessment.fetch
          success: ->
            vm.show new AssessmentSyncView "assessment": assessment

  import: ->
    Tangerine.user.verify
      isAuthenticated: ->
        view = new AssessmentImportView
          noun :"assessment"
        vm.show view

  assessments: ->
    Tangerine.user.verify
      isAuthenticated: ->
        collections = [
          "Klasses"
          "Teachers"
          "Curricula"
          "Assessments"
          "Workflows"
        ]

        collections.push if "server" == Tangerine.settings.get("context") then "Users" else "TabletUsers"

        Utils.loadCollections
          collections: collections
          complete: (options) ->
            options.users = options.tabletUsers || options.users
            vm.show new AssessmentsMenuView options

  lesson: (subject, week, day) ->
    lesson = new LessonCollection
#      "_id" : id
    lesson.db['keys'] = [[subject, week, day]]
#    lesson.db.key = [subject, week, day]
    lesson.fetch
      success : ( model ) ->
        console.log "model: " + JSON.stringify model
        return if model.length == 0
        view = new LessonView model: model.models[0]
        vm.show view

  editId: (id) ->
    id = Utils.cleanURL id
    Tangerine.user.verify
      isAdmin: ->
        assessment = new Assessment
          _id: id
        assessment.superFetch
          success : ( model ) ->
            view = new AssessmentEditView model: model
            vm.show view
      isUser: ->
        Tangerine.router.navigate "", true


  edit: (id) ->
    Tangerine.user.verify
      isAdmin: ->    
        assessment = new Assessment
          "_id" : id
        assessment.fetch
          success : ( model ) ->
            view = new AssessmentEditView model: model
            vm.show view
      isUser: ->
        Tangerine.router.navigate "", true

  restart: (name) ->
    Tangerine.router.navigate "run/#{name}", true

  run: (id) ->
    Tangerine.user.verify
      isAuthenticated: ->
        assessment = new Assessment
          "_id" : id
        assessment.fetch
          success : ( model ) ->
            view = new AssessmentRunView model: model
            vm.show view

  print: ( assessmentId, format ) ->
    Tangerine.user.verify
      isAuthenticated: ->
        assessment = new Assessment
          "_id" : assessmentId
        assessment.fetch
          success : ( model ) ->
            view = new AssessmentPrintView
              model  : model
              format : format
            vm.show view

  resume: (assessmentId, resultId) ->
    Tangerine.user.verify
      isAuthenticated: ->
        assessment = new Assessment
          "_id" : assessmentId
        assessment.fetch
          success : ( assessment ) ->
            result = new Result
              "_id" : resultId
            result.fetch
              success: (result) ->
                view = new AssessmentRunView 
                  model: assessment

                if result.has("order_map")
                  # save the order map of previous randomization
                  orderMap = result.get("order_map").slice() # clone array
                  # restore the previous ordermap
                  view.orderMap = orderMap

                for subtest in result.get("subtestData")
                  if subtest.data? && subtest.data.participant_id?
                    Tangerine.nav.setStudent subtest.data.participant_id

                # replace the view's result with our old one
                view.result = result

                # Hijack the normal Result and ResultView, use one from the db 
                view.subtestViews.pop()
                view.subtestViews.push new ResultView
                  model          : result
                  assessment     : assessment
                  assessmentView : view
                view.index = result.get("subtestData").length
                vm.show view



  results: (assessmentId) ->
    Tangerine.user.verify
      isAuthenticated: ->
        afterFetch = (assessment = new Assessment("_id":assessmentId), assessmentId) ->
          allResults = new Results
          allResults.fetch
            include_docs: false
            key: assessmentId
            success: (results) =>
              view = new ResultsView
                "assessment" : assessment
                "results"    : results.models
              vm.show view

        assessment = new Assessment
          "_id" : assessmentId
        assessment.fetch
          success :  ->
            console.log "success"
            afterFetch(assessment, assessmentId)
          error :  ->
            console.log "eerror"
            afterFetch(assessment, assessmentId)

  csv: (id) ->
    Tangerine.user.verify
      isAdmin: ->
        view = new CSVView
          assessmentId : id
        vm.show view

  csv_alpha: (id) ->
    Tangerine.user.verify
      isAdmin: ->
        assessment = new Assessment
          "_id" : id
        assessment.fetch
          success :  ->
            filename = assessment.get("name") + "-" + moment().format("YYYY-MMM-DD HH:mm")
            document.location = "/" + Tangerine.db_name + "/_design/" + Tangerine.designDoc + "/_list/csv/csvRowByResult?key=\"#{id}\"&filename=#{filename}"
        
      isUser: ->
        errView = new ErrorView
          message : "You're not an admin user"
          details : "How did you get here?"
        vm.show errView

  #
  # Reports
  #
  klassGrouping: (klassId, part) ->
    part = parseInt(part)
    Tangerine.user.verify
      isAuthenticated: ->
          allSubtests = new Subtests
          allSubtests.fetch
            success: ( collection ) ->
              subtests = new Subtests collection.where "part" : part
              allResults = new KlassResults
              allResults.fetch
                success: ( results ) ->
                  results = new KlassResults results.where "klassId" : klassId
                  students = new Students
                  students.fetch
                    success: ->

                      # filter `Results` by `Klass`'s current `Students`
                      students = new Students students.where "klassId" : klassId
                      studentIds = students.pluck("_id")
                      resultsFromCurrentStudents = []
                      for result in results.models
                        resultsFromCurrentStudents.push(result) if result.get("studentId") in studentIds
                      filteredResults = new KlassResults resultsFromCurrentStudents

                      view = new KlassGroupingView
                        "students" : students
                        "subtests" : subtests
                        "results"  : filteredResults
                      vm.show view

  masteryCheck: (studentId) ->
    Tangerine.user.verify
      isAuthenticated: ->
        student = new Student "_id" : studentId
        student.fetch
          success: (student) ->
            klassId = student.get "klassId"
            klass = new Klass "_id" : student.get "klassId"
            klass.fetch
              success: (klass) ->
                allResults = new KlassResults
                allResults.fetch
                  success: ( collection ) ->
                    results = new KlassResults collection.where "studentId" : studentId, "reportType" : "mastery", "klassId" : klassId
                    # get a list of subtests involved
                    subtestIdList = {}
                    subtestIdList[result.get("subtestId")] = true for result in results.models
                    subtestIdList = _.keys(subtestIdList)

                    # make a collection and fetch
                    subtestCollection = new Subtests
                    subtestCollection.add new Subtest("_id" : subtestId) for subtestId in subtestIdList
                    subtestCollection.fetch
                      success: ->
                        view = new MasteryCheckView
                          "student"  : student
                          "results"  : results
                          "klass"    : klass
                          "subtests" : subtestCollection
                        vm.show view

  progressReport: (studentId, klassId) ->
    Tangerine.user.verify
      isAuthenticated: ->
        # save this crazy function for later
        # studentId can have the value "all", in which case student should == null
        afterFetch = ( student, students ) ->
          klass = new Klass "_id" : klassId
          klass.fetch
            success: (klass) ->
              allSubtests = new Subtests
              allSubtests.fetch
                success: ( allSubtests ) ->
                  subtests = new Subtests allSubtests.where 
                    "curriculumId" : klass.get("curriculumId")
                    "reportType"   : "progress"
                  allResults = new KlassResults
                  allResults.fetch
                    success: ( collection ) ->
                      results = new KlassResults collection.where "klassId" : klassId, "reportType" : "progress"

                      console.log students
                      if students?
                        # filter `Results` by `Klass`'s current `Students`
                        studentIds = students.pluck("_id")
                        resultsFromCurrentStudents = []
                        for result in results.models
                          resultsFromCurrentStudents.push(result) if result.get("studentId") in studentIds
                        results = new KlassResults resultsFromCurrentStudents

                      view = new ProgressView
                        "subtests" : subtests
                        "student"  : student
                        "results"  : results
                        "klass"    : klass
                      vm.show view

        if studentId != "all"
          student = new Student "_id" : studentId
          student.fetch
            success: -> afterFetch student
        else
          students = new Students
          students.fetch
            success: -> afterFetch null, students

  #
  # Subtests
  #
  editSubtest: (id) ->
    Tangerine.user.verify
      isAdmin: ->
        id = Utils.cleanURL id
        subtest = new Subtest _id : id
        subtest.fetch
          success: (model, response) ->
            assessment = new Assessment
              "_id" : subtest.get("assessmentId")
            assessment.fetch
              success: ->
                view = new SubtestEditView
                  model      : model
                  assessment : assessment
                vm.show view
      isUser: ->
        Tangerine.router.navigate "", true

  editKlassSubtest: (id) ->

    onSuccess = (subtest, curriculum, questions=null) ->
      view = new KlassSubtestEditView
        model      : subtest
        curriculum : curriculum
        questions  : questions
      vm.show view

    Tangerine.user.verify
      isAdmin: ->
        id = Utils.cleanURL id
        subtest = new Subtest _id : id
        subtest.fetch
          success: ->
            curriculum = new Curriculum
              "_id" : subtest.get("curriculumId")
            curriculum.fetch
              success: ->
                if subtest.get("prototype") == "survey"
                  questions = new Questions
                  questions.fetch
                    key : curriculum.id
                    success: ->
                      questions = new Questions questions.where("subtestId":subtest.id)
                      onSuccess subtest, curriculum, questions
                else
                  onSuccess subtest, curriculum
      isUser: ->
        Tangerine.router.navigate "", true


  #
  # Question
  #
  editQuestion: (id) ->
    Tangerine.user.verify
      isAdmin: ->
        id = Utils.cleanURL id
        question = new Question _id : id
        question.fetch
          success: (question, response) ->
            assessment = new Assessment
              "_id" : question.get("assessmentId")
            assessment.fetch
              success: ->
                subtest = new Subtest
                  "_id" : question.get("subtestId")
                subtest.fetch
                  success: ->
                    view = new QuestionEditView
                      "question"   : question
                      "subtest"    : subtest
                      "assessment" : assessment
                    vm.show view
      isUser: ->
        Tangerine.router.navigate "", true


  editKlassQuestion: (id) ->
    Tangerine.user.verify
      isAdmin: ->
        id = Utils.cleanURL id
        question = new Question "_id" : id
        question.fetch
          success: (question, response) ->
            curriculum = new Curriculum
              "_id" : question.get("curriculumId")
            curriculum.fetch
              success: ->
                subtest = new Subtest
                  "_id" : question.get("subtestId")
                subtest.fetch
                  success: ->
                    view = new QuestionEditView
                      "question"   : question
                      "subtest"    : subtest
                      "assessment" : curriculum
                    vm.show view


  #
  # User
  #
  login: ->
    Tangerine.user.verify
      isAuthenticated: ->
        Tangerine.router.navigate "", true
      isUnregistered: ->

        showView = (users = []) ->
          view = new LoginView
            users: users
          vm.show view

        if Tangerine.settings.get("context") is "server"
          showView()
        else
          users = new TabletUsers
          users.fetch
            success: ->
              showView(users)



  logout: ->
    Tangerine.user.logout()

  account: ->
    # change the location to the trunk, unless we're already in the trunk
    if Tangerine.settings.get("context") == "server" and Tangerine.db_name != "tangerine"
      window.location = Tangerine.settings.urlIndex("trunk", "account")
    else
      Tangerine.user.verify
        isAuthenticated: ->
          showView = (teacher) ->
            view = new AccountView 
              user : Tangerine.user
              teacher: teacher
            vm.show view

          if "class" is Tangerine.settings.get("context")
            if Tangerine.user.has("teacherId")
              teacher = new Teacher "_id": Tangerine.user.get("teacherId")
              teacher.fetch
                success: ->
                  showView(teacher)
            else
              teacher = new Teacher "_id": Utils.humanGUID()
              teacher.save null,
                success: ->
                  showView(teacher)

          else
            showView()

  settings: ->
    Tangerine.user.verify
      isAuthenticated: ->
        view = new SettingsView
        vm.show view


  logs: ->
    Tangerine.user.verify
      isAuthenticated: ->
        logs = new Logs
        logs.fetch
          success: =>
            view = new LogView
              logs: logs
            vm.show view


  teachers: ->
    Tangerine.user.verify
      isAuthenticated: ->
        users = new TabletUsers
        users.fetch
          success: -> 
            teachers = new Teachers
            teachers.fetch
              success: =>
                view = new TeachersView
                  teachers: teachers
                  users: users
                vm.show view


  # Transfer a new user from tangerine-central into tangerine
  transfer: ->
    getVars = Utils.$_GET()
    name = getVars.name
    $.couch.logout
      success: =>
        $.cookie "AuthSession", null
        $.couch.login
          "name"     : name
          "password" : name
          success: ->
            Tangerine.router.navigate ""
            window.location.reload()
          error: ->
            $.couch.signup
              "name" :  name
              "roles" : ["_admin"]
            , name,
            success: ->
              user = new User
              user.save 
                "name"  : name
                "id"    : "tangerine.user:"+name
                "roles" : []
                "from"  : "tc"
              ,
                wait: true
                success: ->
                  $.couch.login
                    "name"     : name
                    "password" : name
                    success : ->
                      Tangerine.router.navigate ""
                      window.location.reload()
                    error: ->
                      Utils.sticky "Error transfering user."
