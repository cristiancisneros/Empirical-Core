class PG.Views.ChapterAssessment extends Backbone.View
  template: JST['backbone/templates/chapter_assessment']
  resultsTemplate: JST['backbone/templates/chapter_assessment_results']

  events:
    'focus .edit-word'             : 'wordFocused'
    'blur  .edit-word'             : 'wordChanged'
    'click .show-results'          : 'showResults'
    # 'click .show-lessons'          : 'showLessons'
    # 'click .rule-lesson-set .next' : 'showNextLessonSet'

  initialize: (options) ->
    @assessment = options.assessment
    @chunks = @assessment.chunks
    @questions = @chunks.select (c) -> c.get('answer')
    @rules = options.rules
    @lessons = options.lessons
    @render()
    #@updateProgress()

  render: ->
    @showStory()

  showPracticeQuestions: ->
    @assessment.get('rule_position')

  showStory: ->
    @$('.text').html @template(chunks: @assessment.chunks)
    @$('.edit-word').attr 'contentEditable', true
    this

  wordFocused: (e) ->
    # @currentWord = @chunks.get($(e.target).data('id'))
    # console.log @currentWord

  wordChanged: (e) ->
    $word = $(e.target)
    chunk = @chunks.get($word.data('id'))
    chunk.input = $word.text().trim()
    # @updateProgress()
    if chunk.input == chunk.word
      $word.removeClass 'edited'
    else
      $word.addClass 'edited'


  updateProgress: ->
    @$('.progress').html ''

    _.each @questions, (chunk) ->
      if chunk.grade()
        @$('.progress').append $('<div class="unit">').html('&nbsp;').addClass('correct')
      else
        @$('.progress').append $('<div class="unit">').html('&nbsp;')

  showResults: ->
    _this = this;
    missedRules = []
    total = @chunks.select( (c) -> c.attributes.answer ).length

    @$('.edit-word')
      .removeClass('edit-word')
      .addClass('graded-word')
      .each (word) ->
        $word = $(this)
        $word.attr 'contentEditable', false
        chunk = _this.chunks.get($word.data('id'))

        if chunk.grade() && chunk.inputPresent()
          $word.addClass('correct')
        else if not chunk.grade()
          $word.addClass('error')
          if chunk.grammar then missedRules.push chunk.rule()

    missed = missedRules.length

    mixpanel.track "story test submitted",
      chapter_id: @assessment.get('chapter_id')
      score: parseInt( ((total - missed) / total) * 100 )
      body: this.assessment.attributes.body.substring(0,50)

    missedRules = _.uniq(missedRules)
    @missedRules = new PG.Collections.ChapterRules
    @missedRules.reset missedRules
    @orderedRules = []

    for id in @assessment.get 'rule_position'
      @orderedRules.push _.first @missedRules.where(id: parseInt(id))

    @$('.grammar-test-results form').show().append @resultsTemplate(@assessment)
    @percentMissed = 100 - (@missedRules.length / chapterRules.length * 100)

  showLessons: ->
    $('.grammar-test').children().hide()

    $lessons = $('.lessons')
      .show()
      .html JST['backbone/templates/chapter_lessons'](orderedRules: @orderedRules)

    @$currentLessonSet = $lessons.find('.rule-lesson-set:first').show()
    @lessonsView = new PG.Views.ChapterLessons(el: $lessons, percentMissed: @percentMissed)


class PG.Views.PracticeLessonSet extends Backbone.View
  events:
    'click .next' : 'showNextLessonSet'

  initialize: ->

  showNextLessonSet: (e, $set = @$('.rule-lesson-set')) ->
    nextIndex = $set.index(@$currentLessonSet) + 1
    if nextIndex >= $set.length then nextIndex = 0
    @$currentLessonSet = $set.eq(nextIndex).siblings().hide().end().show()

