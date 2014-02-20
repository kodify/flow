parameters:
  flow:
    pending_pr_to_notify: 3
    pending_pr_interval_in_sec: 1800
  dictionary:
    blocked: [ ':-1:', '[B]', '[b]' ]
    reviewed: [ ':+1:', '+1' ]
    uat_ok: [ ':shipit:', '[UAT-OK]' ]
    uat_ko: [ ':boom:', '[UAT-KO]' ]
    ignore: [ '[IGNORE]' ]
  adapters:
    jira:
      class_name: 'Jira'
      url: https://you.atlassian.net
      issue_path: /browse/
      user: api
      pass: my_jira_password
      min_unassigned_uats: 3
      transitions:
        ready_uat: id_ready_uat
        uat_nok: id_uat_ko
        done: id_to_done
    hipchat:
      class_name: 'Hipchat'
      token: my_hipchat_token
      room: my_hipchat_room
      uat_room: my_hipchat_room
      default_user: Mr Deploy
      days: 12345
      hours: 9-18
    github:
      class_name: Github
      login: github_login
      password: github_password
      valid_repos: [ 'kodify/rule34', 'kodify/kumm', 'kodify/katt', 'kodify/CPP' ]
    jenkins:
      class_name: Jenkins
  projects:
    kodify/repo1:
      continuous_integration:
        jenkins:
      issue_tracker:
        jira:
      notifier:
        hipchat:
      source_control:
        github:
    kodify/repo2:
      continuous_integration:
        scrutinizer:
          metrics:
            xxxx: 'threshold'
            yyyy: 'threshold'
      issue_tracker:
        jira:
      notifier:
        hipchat:
      source_control:
        github:
    kodify/repo3:
      continuous_integration:
        jenkins:
      issue_tracker:
        jira:
      notifier:
        hipchat:
      source_control:
        github:
