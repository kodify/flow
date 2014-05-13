require File.join(File.dirname(__FILE__), '..', '..', 'config')

module Flow
  module Workflow
    class Repo
      attr_accessor :scm, :name

      def initialize(repo_name)
        @name = repo_name
      end

      def pull_requests
        pulls
      end

      def pull_request_by_name(name)
        pulls.find { |pull| pull.issue_tracker_id.to_s == name }
      end
      
      def issue_exists(issue_name)
        issues.any? { |issue| issue.title.include? issue_name }
      end

      def issue!(title, body = '', options = {})
        return if issue_exists(title)
        scm.create_issue(@name, title, body, options)
      end

      def related_repos
        scm.related_repos
      end

      def dependent_repos
        scm.dependent_repos
      end

      def update_dependent(where,submodule_path, branch)
        scm.clean_repo("#{where}/#{project_name}")
        scm.put_branch_on_path('master', "#{where}/#{project_name}")
        scm.create_branch_on_path(branch, "#{where}/#{project_name}")
        scm.clean_repo("#{where}/#{project_name}/#{submodule_path}")
        scm.put_branch_on_path(branch, "#{where}/#{project_name}/#{submodule_path}")
      end

      def create_pull_request(where, submodule_path, branch, comment)
        scm.create_pull_request(where,submodule_path,branch,comment, project_name)
      end

      def repo_url
        'git@github.com:'+name+'.git'
      end

      def project_name
        name.split('/').last
      end

      def clone_into(path)
          scm.clone_project_into(repo_url, path, project_name)
      end

      protected

      def pulls
        @__pull_requests__ ||= scm.pull_requests self
      end

      def issues
        @__issues__ ||= scm.issues @name
      end

      def scm
        @__client__ ||= Flow::Workflow::Factory.instance(@name, :source_control)
      end
    end
  end
end
