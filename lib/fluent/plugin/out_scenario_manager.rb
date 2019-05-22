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
  module Plugin
    # fluentd output plugin
    class ScenarioManagerOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output('scenario_manager', self)
      helpers :storage, :event_emitter
      DEFAULT_STORAGE_TYPE = 'local'
      PATTERN_MAX_NUM = 20

      config_param :scenario_manage_mode, :bool, default: true,
                                                 desc: 'false: update storage and emit record only.'
      config_param :if, :string, default: nil,
                                 desc: 'first scenario manage rule.'
      (1..PATTERN_MAX_NUM).each do |i|
        config_param ('elsif' + i.to_s).to_sym, :string, default: nil,
                                                         desc: 'Specify tag(not necessary)'
      end

      def configure(conf)
        super
        config = conf.elements.select { |e| e.name == 'storage' }.first
        @storage = storage_create(usage: 'test', conf: config, default_type: DEFAULT_STORAGE_TYPE)
      end

      def start
        super
        @storage.put(:scenario, 0) unless @storage.get(:scenario)
        pp @storage.get(:scenario)
      end

      def process(_tag, es)
        pp @storage.get(:scenario)
        es.each do |time, record|
          # output events to ...
          pp time
          pp record
          @storage.put(:scenario, record['id'])
          # ただオウムがえし
          router.emit('scenaroi', time, record)
        end
      end
    end
  end
end
