module Flow
  module Workflow
    class IssueTracker
      attr_accessor :min_unassigned_uats

      def initialize(config, options = {})
        @url                  = config['url']
        @user                 = config['user']
        @pass                 = config['pass']
        @min_unassigned_uats  = config['min_unassigned_uats']
        @status               = { ready_uat:  config['transitions']['ready_uat'],
                                  uat_nok:    config['transitions']['uat_nok'],
                                  done:       config['transitions']['done'] }
      end

      def do_move(status_id, issue)
        raise 'Method #is_green? not implemented'
      end

      def issues_by_status(status_name)
        raise 'Method #is_green? not implemented'
      end
    end
  end
end