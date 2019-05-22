require "helper"
require "fluent/plugin/out_scenario_manager.rb"

class ScenarioManagerOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  def teardown
    # terminate test for plugin (Optional)
  end

  # configuration related test group
  sub_test_case 'configuration' do
    test 'basic configuration' do
      d = create_driver(basic_configuration)
      assert_equal 'somethig', d.instance.parameter_name
    end
  end

  # Another test group goes here
  sub_test_case 'path' do
    test 'normal' do
      d = create_driver('...')
      d.run(default_tag: 'test') do
        d.feed(event_time, record)
      end
      events = d.events
      assert_equal(1, events.size)
    end
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::ScenarioManagerOutput).configure(conf)
  end
end
