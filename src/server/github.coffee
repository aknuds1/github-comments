log = new Logger("github")

pollGitHub = ->
  log.info("Polling GitHub for data")
  options =
    auth: "token:#{Configuration.token}"
    headers:
      "User-Agent": "GitHub Comments"

  if Commits.findOne(user: Configuration.user)?
    log.debug("Skipping user #{Configuration.user}, since already stored")
    return

  start = moment()

  userUrl = "https://api.github.com/users/#{Configuration.user}"
  HTTP.call("get", userUrl, options, (error, result) ->
    if error?
      throw new Error("Couldn't get data for user #{Configuration.user}")

    user = result.data
    if !user.email
      throw new Error("Need to be able to identify user by email")
    HTTP.call("get", "#{userUrl}/events", options, (error, result) ->
      if error?
        throw new Error("Couldn't get events for user #{Configuration.user}")

      events = (event for event in result.data when event.type == "PushEvent" && event.payload.commits.length > 0)
      #log.debug(events)
      commits = []
      for event in events
        for commit in event.payload.commits when commit.author.email == user.email
          commits.push(
            sha: commit.sha
            url: commit.url
          )

      log.debug("Found #{commits.length} commits attributable to user #{user.email}")
      log.debug("Removing all previous commits belonging to #{Configuration.user}")
      Commits.remove(user: Configuration.user)
      numCommits = 0
      for commit in commits
        log.debug("Getting details for commit #{commit.sha}", commit.url)
        commitDetails = HTTP.call("get", "#{commit.url}", options).data
        if commitDetails.commit.comment_count == 0
          continue

        log.debug("Getting comments for commit #{commit.sha}")
        comments = HTTP.call("get", commitDetails.comments_url, options).data
        log.debug("Got comments", comments)

        commit =
          sha: commit.sha
          url: commitDetails.html_url
          comments: comments
          user: Configuration.user
          lastChange: start.toISOString()
        Commits.insert(commit)
        log.debug("Inserted commit", commit)
        ++numCommits

      taken = moment().diff(start, "seconds")
      log.info("Inserted #{numCommits} commits for user #{Configuration.user} in #{taken} seconds")
    )
  )

Meteor.startup(->
  pollGitHub()
)
