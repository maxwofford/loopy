ENV["RAILS_ENV"] ||= "test"
ENV["LOOPS_API_KEY"] ||= "test_loops_api_key"
require_relative "../config/environment"
require "rails/test_help"
require_relative "support/vcr_setup"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
