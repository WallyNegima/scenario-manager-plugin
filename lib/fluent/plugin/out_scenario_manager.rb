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
      helpers :storage, :event_emitter
      DEFAULT_STORAGE_TYPE = 'local'
      PATTERN_MAX_NUM = 20

      config_param(
        :scenario_manage_mode,
        :bool,
        default: true,
        desc: 'false: update storage and emit record only.'
      )

      config_param(
        :tag,
        :string,
        default: 'scenario'
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
        config = conf.elements.select { |e| e.name == 'storage' }.first
        @storage = storage_create(usage: 'test', conf: config, default_type: DEFAULT_STORAGE_TYPE)

        # シナリオパラメーターを取得
        @scenarios = []
        conf.elements.select { |element| element.name.match(/^scenario\d\d?$/) }
            .each do |param|
          scenario = {}
          param.each_pair do |key, value|
            scenario.merge!(key => value)
          end
          @scenarios.push(scenario)
        end

        # えらーならraiseする
        valid_conf?(conf)
      end

      def start
        super
        @storage.put(:scenario, 0) unless @storage.get(:scenario)
        pp @storage.get(:scenario)
        pp @scenarios
      end

      def process(tag, es)
        pp @storage.get(:scenario)
        es.each do |time, record|
          # output events to ...
          unless @scenario_manage_mode
            @storage.put(:scenario, record['scenario_id'])
            router.emit(tag, time, record)
          end

          # ただオウムがえし
          router.emit('scenario', time, record)
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

        raise Fluent::ConfigError, 'out_scenario_manager: "if" directive is ruquired' if @if.nil?
        raise Fluent::ConfigError, 'out_scenario_manager: "scenario" define is ruquired at least 1' if @scenarios.size <= 0
      end
    end

    def convert_num(value)
      # Booleanがチェック
      if value == 'true'
        return true
      elsif value == 'false'
        return false
      end

      # 数値データなら数値で返す
      if value.to_i.to_s == value.to_s
        return value.to_i
      else
        return value
      end
    end
  end
end
