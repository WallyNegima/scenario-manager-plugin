# frozen_string_literal: true

require 'helper'
require 'fluent/plugin/out_scenario_manager.rb'
# Load the module that defines helper methods for testing (Required)
require 'fluent/test/helpers'
# Load the test driver (Required)
require 'fluent/test/driver/output'
class ScenarioManagerOutputTest < Test::Unit::TestCase
  PATTERN_MAX_NUM = 20
  setup do
    Fluent::Test.setup
  end

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::ScenarioManagerOutput).configure(conf)
  end

  # configuration related test group
  sub_test_case 'configuration' do
    test 'empty configuration' do
      conf = config_element('ROOT', '', {
                              'if' => 'record[face_id] == 1 then executeScenario singing',
                              'tag' => 'scenario'
                            }, [config_element('scenario1', '',
                                               'label' => 'greeting',
                                               'priority' => 2,
                                               'limit' => 30,
                                               'action' => 'greet')])
      d = create_driver(conf)
      assert_equal 'record[face_id] == 1 then executeScenario singing', d.instance.if
      assert_equal 'scenario', d.instance.tag
      assert_equal nil, d.instance.elsif1
      assert_equal nil, d.instance.elsif2
      assert_equal true, d.instance.scenario_manage_mode
    end

    test 'not scenario manage mode configuration' do
      conf = config_element('ROOT', '',
                            'scenario_manage_mode' => false)
      d = create_driver(conf)
      assert_equal false, d.instance.scenario_manage_mode
    end

    test 'error configuration' do
      conf = config_element('ROOT', '', {
                              'if' => 'record[face_id] == 1',
                              'tag' => 'scenario'
                            }, [config_element('scenario1', '',
                                               'label' => 'greeting',
                                               'priority' => 2,
                                               'limit' => 30,
                                               'action' => 'greet')])

      assert_raise(Fluent::ConfigError) do
        create_driver(conf)
      end
    end
  end

  # Another test group goes here
  sub_test_case 'scenario manage' do
    test 'normal' do
      conf = config_element('ROOT', '', {
                              'if' => 'record[face_id] == 1 then executeScenario greeting',
                              'tag' => 'scenario'
                            }, [config_element('scenario1', '',
                                               'label' => 'greeting',
                                               'priority' => 2,
                                               'limit' => 30,
                                               'action' => 'greet')])
      d = create_driver(conf)
      d.run(default_tag: 'test') do
        d.feed('face_id' => 1)
      end

      events = d.events
      assert_equal(1, events.size)
    end

    test 'not scenario manage mode' do
      conf = config_element('ROOT', '',
                            'scenario_manage_mode' => false)
      d = create_driver(conf)
      d.run(default_tag: 'test') do
        d.feed('face_id' => 1, 'scenario_id' => 1)
      end

      events = d.events
      assert_equal(1, events.size)
    end
  end
end
