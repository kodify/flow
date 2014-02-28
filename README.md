#Flow
[![Build Status](https://travis-ci.org/kodify/flow.png?branch=master)](https://travis-ci.org/kodify/flow)
[![Code Climate](https://codeclimate.com/github/kodify/flow.png)](https://codeclimate.com/github/kodify/flow)
 
Agile environment workflow assistant

##Philosophy

Bored of giving visibility to your work?

Flow automates all workflow related tasks and it integrates with:

Issue trackers
    - [x] Jira
Source Managers
    - [x] Github
- Notifiers
    - [x] Hipchat
- Continuous integrations
    - [x] Scrutinizer
    - [x] Travis CI
    - [x] Jenkins CI

It is also flexible and adaptable to all your needs.

##Quick start

Install flow
```sh
git clone git@github.com:kodify/flow.git
```

... and also its gems
```sh
cd flow
bundle install
```

###Configure

You need to rename the config/parameters.yml.tpl to config/parameters.yml, and fill it with your data

###Run it

You will probably want this on a cronjob
```sh
./bin/kod flow 'my/repo'
```

###Configure Jira webhooks

[Here][] you have a good explanation of what are Jira webhooks, BTW you should configure them as follows:

[Here]: https://developer.atlassian.com/display/JIRADEV/JIRA+Webhooks+Overview


```code
# For uat to in progress transition
http://your_address/pr/${issue.key}/ko

# For uat to done transition
http://your_address/pr/${issue.key}/ok
```

##Supported git workflow

Actually Flow is working over a simple continuous delivering git workflow.

Its based on a master branch where each user story is represented by a branch with the jira issue id.

When a user story is completed (AKA green CI, code reviewed an uat ok) Flow automatically merges this PR and runs a build over master branch.

##What it does

Flow will do all those actions for you:

###Avoid infinite PRs

In order to don't have infinite pull requests without code review, Flow will post on your predefined chat room an alert whenever the max pull requests limit is reached.
Please take a look at confg/parameters.yml to configure parameters.

###Deploy remember

It will post a comment on your default chat room remembering that build is green and you can deploy. Just configure a new cron to call:
```sh
./bin/kod can_deploy 'my/repo'
```

###Move reviewed issues on jira

Whenever a pull request is green and has marked as reviewed (+1, :+1:) flow will move your Jira issue to uat column.

###Merge and move uat ok pull requests

Pull requests with code review (:+1:) and uat ok (:shipit:) will be automatically merged and origin branch removed

###Move uat ko issues on jira

Whenever you mark a pull request as ko (:boom:) Flow will move it on J  ira to in progress column

###Uat OK (Jira integration)

With Jira webhooks you can link the transition between uat to done to automatically post a (:shipit:) message on the Pull Request

###Uat KO (Jira integration)

With Jira webhooks you can link the transition between uat to in progress to automatically post a (:boom:) message on the Pull Request

##Flow language

In order to comunicate with Flow you need to know its language, just a few icons:

- :+1: : Pull request is code reviewed
- :-1: : Pull request is code reviewed and is blocked because of some problems
- :shipit: : Pull request is uat ok
- :boom: : Pull request is uat ko

... otherwise you can customize the way you talk to Flow on your config/parameters.yml

## Supported Ruby Versions

This library aims to support and is [tested against][travis] the following Ruby
implementations:

* Ruby 1.9.3
* Ruby 2.0.0

If something doesn't work on one of these Ruby versions, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby
implementations, however support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be responsible for providing patches in a timely
fashion. If critical issues for a particular implementation exist at the time
of a major release, support for that Ruby version may be dropped.


## License

{include:file:LICENSE.md}
