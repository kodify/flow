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
        clean_repo("#{where}/#{project_name}")
        puts "Moving #{where}/#{project_name} to Master branch"
        `cd #{where}/#{project_name}
        git checkout .
        git checkout master
        git fetch origin
        git rebase origin/master`
        puts "Creating branch #{branch}"
        `cd #{where}/#{project_name}
        git checkout -b #{branch}`
        clean_repo("#{where}/#{project_name}/#{submodule_path}")
        puts "Moving to branch #{branch} on submodule #{submodule_path}"
        `cd #{where}/#{project_name}/#{submodule_path}
        git checkout .
        git checkout #{branch}
        git rebase origin/#{branch}; true`
      end

      def clean_repo(path)
        puts "cleaning #{path}"
        `cd #{path}
          git fetch origin
          git checkout .`
      end

      def create_pull_request(where, submodule_path, branch, comment)
        puts "Creating commit"
        `cd #{where}/#{project_name}/
        git add #{submodule_path}
        git commit -m 'update submodule for #{comment} on #{submodule_path}'`
        puts "Push to origin"
        `cd #{where}/#{project_name}/
        git push origin #{branch}`
        puts "Creating pull request"
        `cd #{where}/#{project_name}/
        hub pull-request -m 'update submodule for #{comment}'`
      end

      def repo_url
        'git@github.com:'+name+'.git'
      end

      def project_name
        'parent'
      end

      def clone_into(path)
          repo = repo_url
          `rm -rf #{path}/#{project_name}/
          mkdir -p #{path}
          cd #{path}
          git clone #{repo}; true`
          `cd #{path}/#{project_name}/
          git pull origin master
          git submodule init
          git submodule update; true`
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
