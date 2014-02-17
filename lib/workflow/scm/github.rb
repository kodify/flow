module Flow
  module Workflow
    class Github
      def initialize(config, options = {})
        @config = config
      end

      protected

      def client
        @__octokit_client__ ||= begin
          Octokit::Client.new(
              :login    => config['login'],
              :password => config['password']
          )
        end
      end
    end
  end
end