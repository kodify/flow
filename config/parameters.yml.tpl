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
      related_repos: [ ]
    jenkins:
      url: http://my_url:18181/job/
    scrutinizer:
      url: https://scrutinizer-ci.com/api/repositories/g/
      token: xxxxx
    dummy_notifier:
      class_name: 'DummyNotifier'
    dummy_ci:
      class_name: 'DummyCi'
    dummy_it:
      class_name: 'DummyIt'
    dummy_scm:
      class_name: 'DummyScm'
  projects:
    kodify/repo1:
      continuous_integration:
        dummy_ci:
      issue_tracker:
        dummy_it:
      notifier:
        dummy_notifier:
      source_control:
        github:
          related_repos: []
    kodify/repo2:
      continuous_integration:
        dummy_ci:
      issue_tracker:
        dummy_it:
      notifier:
        dummy_notifier:
      source_control:
        github:
          related_repos: []
