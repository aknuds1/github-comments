@Commits = new Meteor.Collection("commits")

if Meteor.isServer
  Meteor.publish("commits", -> Commits.find(user: Configuration.user))
  Commits.allow(insert: -> false)
