Meteor.subscribe("commits")

date2Str = (date) ->
  moment(date).format("MMMM Do YYYY hh:mm:ss")

Meteor.startup(->
  Meteor.call("username", (error, result) ->
    Session.set("username", result)
  )
)

Template.commits.username = -> Session.get("username")
Template.commits.commits = ->
  commits = Commits.find({}, transform: (doc)->
    sha: doc.sha
    message: doc.message
    date: moment(doc.date).format("MM.DD.YYYY hh:mm:ss")
    url: doc.url
    comments: doc.comments
  ).fetch()
  lodash(commits).sortBy((commit) -> commit.sha)
    .sortBy((commit) -> commit.date)
    .sortBy((commit) -> commit.lastChange).reverse().value()
Template.commits.lastChange = ->
  lastChanges = Commits.find({}, {transform: (doc) -> doc.lastChange}).fetch()
  if lodash(lastChanges).isEmpty()
    return

  lastChange = lastChanges[0]
  for x in lastChanges[1..]
    if x > lastChange
      lastChange = x
  date2Str(lastChange)
