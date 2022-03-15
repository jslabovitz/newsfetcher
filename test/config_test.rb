$VERBOSE = false
# avoid annoying warning
class Object
  def tainted?; false; end
end

require 'minitest/autorun'
require 'minitest/power_assert'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'newsfetcher'

module NewsFetcher

  class TestConfig < Minitest::Test

    def setup
      @config1 = Config.new(a: 1, b: 2)
      @config2 = @config1.make(b: 22, c: 3)
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

    def test_load_save
      file = Path.new('test/tmp/config.json')
      @config1.save(file)
      assert { file.exist? }
      config = Config.load(file)
      assert { config == @config1 }
    end

    def test_merged
      h = @config1.hash.merge(@config2.hash).merge(@config3.hash)
      assert { @config3.merged == h }
    end

    def test_assign
      @config3.a = 11
      assert { @config1.a == 1 }
      assert { @config2.a == 1 }
      assert { @config3.a == 11 }
    end

  end

end