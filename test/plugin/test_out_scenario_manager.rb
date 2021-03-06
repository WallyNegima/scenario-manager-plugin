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
                              'if' => 'record["face_id"] == 1 then execute_scenario singing',
                              'tag' => 'scenario'
                            }, [config_element('scenario1', '',
                                               'label' => 'greeting',
                                               'priority' => 2,
                                               'limit' => 30,
                                               'action' => 'greet')])
      d = create_driver(conf)
      assert_equal 'record["face_id"] == 1 then execute_scenario singing', d.instance.if
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
                              'if' => 'record["face_id"] == 1',
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
                              'if' => 'record["face_id"] == 1 then execute_scenario greeting',
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
      record = events.first[2]
      assert_equal(record['label'], 'greeting')
      assert_equal(record['priority'], 2)
      assert_equal(record['limit'], 30)
      assert_equal(record['action'], 'greet')
    end

    test 'if elsif' do
      conf = config_element('ROOT', '', {
                              'if' => 'record["face_id"] == 1 then execute_scenario singing',
                              'elsif1' => 'record["face_id"] == 3 then execute_scenario greeting',
                              'tag' => 'scenario'
                            }, [config_element('scenario1', '',
                                               'label' => 'greeting',
                                               'priority' => 2,
                                               'limit' => 30,
                                               'action' => 'greet')])
      d = create_driver(conf)
      d.run(default_tag: 'test') do
        d.feed('face_id' => 3)
      end

      events = d.events
      assert_equal(1, events.size)
      record = events.first[2]
      assert_equal(record['label'], 'greeting')
      assert_equal(record['priority'], 2)
      assert_equal(record['limit'], 30)
      assert_equal(record['action'], 'greet')
    end

    # TODO: storageを使ったてすとを作成すること
    # test 'storage' do
    #   conf = config_element('ROOT', 'sensor', {
    #                           'if' => 'record["face_id"] == 1 then execute_scenario singing',
    #                           'elsif1' => 'record["face_id"] == 3 and executing_scenario == "singing" then execute_scenario greeting',
    #                           'tag' => 'scenario'
    #                         }, [config_element('scenario1', '',
    #                                            'label' => 'greeting',
    #                                            'priority' => 2,
    #                                            'limit' => 30,
    #                                            'action' => 'greet')])
    #   d = create_driver(conf)
    #   # executeing_scenario を singingに
    #   # d.run(default_tag: 'scenario') do
    #   #   d.feed('label' => 'singing')
    #   # end

    #   d.run(default_tag: 'sensor') do
    #     d.feed('face_id' => 3)
    #   end

    #   events = d.events
    #   assert_equal(1, events.size)
    #   record = events.first[2]
    #   assert_equal(record['label'], 'greeting')
    #   assert_equal(record['priority'], 2)
    #   assert_equal(record['limit'], 30)
    #   assert_equal(record['action'], 'greet')
    # end
  end

  # Another test group goes here
  sub_test_case 'not scenario manage mode' do
    test 'normal' do
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
