# frozen_string_literal: true

#
# Copyright 2019- TODO: Write your name
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fluent/plugin/output'

module Fluent
  # plugin
  module Plugin
    # fluentd output plugin
    class ScenarioManagerOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output('scenario_manager', self)
      helpers :event_emitter
      DEFAULT_STORAGE_TYPE = 'local'
      PATTERN_MAX_NUM = 20
      @@executing_scenario = ''

      config_param(
        :scenario_manage_mode,
        :bool,
        default: true,
        desc: 'false: update storage and emit record only.'
      )

      config_param(
        :tag,
        :string,
        default: nil
      )
      config_param(
        :if, :string, default: nil, desc: 'first scenario manage rule.'
      )
      (1..PATTERN_MAX_NUM).each do |i|
        config_param(
          ('elsif' + i.to_s).to_sym,
          :string,
          default: nil,
          desc: 'Specify tag(not necessary)'
        )
      end

      (1..PATTERN_MAX_NUM).each do |i|
        config_param(
          "scenario#{i}".to_sym,
          :string,
          default: nil,
          desc: 'Scenario defines'
        )
      end

      def configure(conf)
        super
        # シナリオパラメーターを取得
        @scenarios = []
        conf.elements.select { |element| element.name.match(/^scenario\d\d?$/) }
            .each do |param|
          scenario = {}
          param.each_pair do |key, value|
            scenario.merge!(key => convert_value(value))
          end
          @scenarios.push(scenario)
        end

        # えらーならraiseする
        valid_conf?(conf)

        return unless @scenario_manage_mode

        # シナリオルールの取得
        @rules = []
        @executes = []
        rule, execute = separate_rule_and_exec(conf['if'])
        @rules.push(rule)
        @executes.push(execute)
        (1..PATTERN_MAX_NUM).each do |i|
          next unless conf["elsif#{i}"]

          rule, execute = separate_rule_and_exec(conf["elsif#{i}"])
          @rules.push(rule)
          @executes.push(execute)
        end
      end

      def start
        super
      end

      def process(tag, es)
        es.each do |time, record|
          # output events to ...
          unless @scenario_manage_mode
            @@executing_scenario = record['label']
            # TODO: actionタグを自由に命名できるようにする
            router.emit("serialized_action", time, record)
            break
          end

          # scenario check
          execute_idx = scenario_detector(record)

          next if execute_idx.nil?

          # execute scenario
          # マッチしたシナリオを実行する（emitする）
          router.emit(@tag || 'detected_scenario', time, get_scenario(@executes[execute_idx]))
        end
      end

      private

      BUILTIN_CONFIGURATIONS = %w[@id @type @label scenario_manage_mode tag if].freeze
      def valid_conf?(conf)
        # manage_modeじゃなかったら何もチェックしない
        return true unless @scenario_manage_mode

        # ここで、BUILTIN_CONFIGURATIONS に入っていないものがあった場合はerrorをraise
        elsif_cnt = 0
        conf.each_pair do |k, v|
          elsif_cnt += 1 if k.match(/^elsif\d\d?$/)
          next if BUILTIN_CONFIGURATIONS.include?(k) || k.match(/^elsif\d\d?$/)

          raise(Fluent::ConfigError, 'out_scenario_manager: some weird config is set {' + k.to_s + ':' + v.to_s + '}')
        end

        raise Fluent::ConfigError, 'out_scenario_manager: "if" directive is required' if @if.nil?
        raise Fluent::ConfigError, 'out_scenario_manager: "scenario" define is ruquired at least 1' if @scenarios.size <= 0
      end

      # ruleを調べて、マッチしたらそのindexを返す。
      # すべてマッチしなかったらnilを返す
      def scenario_detector(record) # rubocop:disable all
        @rules.each_with_index do |rule, idx|
          return idx if instance_eval(rule)
        end
        nil
      end

      def executing_scenario
        @@executing_scenario
      end

      def separate_rule_and_exec(rule)
        separated_str = /(.+*)( then )(.+*)/.match(rule)
        [separated_str[1], separated_str[3]]
      rescue StandardError
        raise Fluent::ConfigError, 'out_scenario_manager: scenario rule should contain ~ then ~ .'
      end

      def get_scenario(execute)
        execute_scenario_label = /(execute_scenario )(.+*)/.match(execute)[2]
        @scenarios.each_with_index do |scenario, _idx|
          return scenario if scenario['label'] == execute_scenario_label
        end
        return nil
      end

      def convert_value(value)
        # Booleanがチェック
        return true if value == 'true'

        return false if value == 'false'

        # 数値データなら数値で返す
        return value.to_i if value.to_i.to_s == value.to_s

        value
      end
    end
  end
end
