$VERBOSE = false

require 'minitest/autorun'
require 'minitest/power_assert'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'newsfetcher'

module NewsFetcher

  class TestConfig < Minitest::Test

    def setup
      @base_config = Config.define(
        a: { default: 1 },
        b: { default: 2, converter: proc { |o| Integer(o) } },
        c: nil,
        d: nil,
      )
      @config1 = @base_config.make
      @config2 = @config1.make(b: '22', c: 3)
      @config3 = @config2.make(d: 4)
    end

    def test_config
      assert { @config1.a == 1 }
      assert { @config1.b == 2 }
      assert { @config1.c == nil }
      assert { @config1.d == nil }

      assert { @config2.a == 1 }
      assert { @config2.b == 22 }
      assert { @config2.c == 3 }
      assert { @config2.d == nil }

      assert { @config3.a == 1 }
      assert { @config3.b == 22 }
      assert { @config3.c == 3 }
      assert { @config3.d == 4 }
    end

    def test_load
      file = Path.new('test/config.json')
      config = @base_config.load(file)
      assert { config.a == 11 }
      assert { config.b == 22 }
    end

  end

end