Meteor.subscribe("commits")

Meteor.startup(->
  Meteor.call("username", (error, result) ->
    Session.set("username", result)
  )
)

Template.commits.username = -> Session.get("username")
Template.commits.commits = ->
  commits = Commits.find().fetch()
  _(commits).sortBy((commit) -> commit.sha)
    .sortBy((commit) -> commit.lastChange).reverse().value()
Template.commits.lastChange = ->
  lastChanges = Commits.find({}, {transform: (doc) -> doc.lastChange}).fetch()
  if _(lastChanges).isEmpty()
    return

  lastChange = lastChanges[0]
  for x in lastChanges[1..]
    if x > lastChange
      lastChange = x
  moment(lastChange).format("MMMM Do YYYY hh:mm:ss")
