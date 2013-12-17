parameters:
  hipchat:
    token: my_hipchat_token
    room: my_hipchat_room
    uat_room: my_hipchat_room
    default_user: Mr Deploy
    days: 12345
    hours: 9-18
  github:
    login: github_login
    password: github_password
    valid_repos: [ 'kodify/repo1', 'kodify/repo2', 'kodify/repo3' ]
  flow:
    pending_pr_to_notify: 3
    pending_pr_interval_in_sec: 1800
  jenkins:
    url: http://my_url:18181/job/
  jira:
    url: https://you.atlassian.net
    issue_path: /browse/
    user: api
    pass: my_jira_password
    min_unassigned_uats: 3
    transitions:
      ready_uat: id_ready_uat
      uat_nok: id_uat_ko
      done: id_to_done
  dictionary:
    blocked: [ ':-1:', '[B]', '[b]' ]
    reviewed: [ ':+1:', '+1' ]
    uat_ok: [ ':shipit:', '[UAT-OK]' ]
    uat_ko: [ ':boom:', '[UAT-KO]' ]
