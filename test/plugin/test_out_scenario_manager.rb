require "helper"
require "fluent/plugin/out_scenario_manager.rb"

class ScenarioManagerOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
  end

  test "SCCESS" do
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::ScenarioManagerOutput).configure(conf)
  end
end
