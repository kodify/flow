parameters:
  github:
    login: github_login
    password: github_password
  flow:
    pending_pr_to_notify: 3
    pending_pr_interval_in_sec: 1800
  jenkins:
    url: http://my_url:18181/job/
  scrutinizer:
    url: https://scrutinizer-ci.com/api/repositories/g/
    token: xxxxx
  dictionary:
    blocked: [ ':-1:', '[B]', '[b]' ]
    reviewed: [ ':+1:', '+1' ]
    uat_ok: [ ':shipit:', '[UAT-OK]' ]
    uat_ko: [ ':boom:', '[UAT-KO]' ]
    ignore: [ '[IGNORE]' ]

  projects:
    kodify/repo1:
      ci:
        class_name: 'Jenkins'
      it:
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
      not:
        class_name: Hipchat
        token: my_hipchat_token
        room: my_hipchat_room
        uat_room: my_hipchat_room
        default_user: Mr Deploy
        days: 12345
        hours: 9-18
    kodify/repo2:
      ci:
        class_name: 'Scrutinizer'
      metrics:
        xxxx: 'threshold'
        yyyy: 'threshold'
      it:
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
      not:
        class_name: Hipchat
        token: my_hipchat_token
        room: my_hipchat_room
        uat_room: my_hipchat_room
        default_user: Mr Deploy
        days: 12345
        hours: 9-18
    kodify/repo3:
      ci:
        class_name: 'Jenkins'
      it:
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
      not:
        class_name: Hipchat
        token: my_hipchat_token
        room: my_hipchat_room
        uat_room: my_hipchat_room
        default_user: Mr Deploy
        days: 12345
        hours: 9-18
