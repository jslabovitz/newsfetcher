$VERBOSE = false

require 'minitest/autorun'
require 'minitest/power_assert'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'newsfetcher'

module NewsFetcher

  class TestHistory < Minitest::Test

    def setup
      @file = Path.new('test/tmp/history.jsonl')
      @file.unlink if @file.exist?
      @history = History.new(file: @file, index_key: :name)
      @times = [
        Time.now - 2,
        Time.now - 1,
        Time.now - 0,
      ]
      @history << { time: @times[0], name: 'a' }
      @history << { time: @times[1], name: 'b' }
      @history << { time: @times[2], name: 'c' }
    end

    def test_add
      assert { @history.file.exist? }
      assert { @history.size == 3 }
    end

    def test_prune
      @history.prune(before: @times[1])
      assert { @history.size == 2 }
      assert { @history.entries[0].time == @times[1] }
      assert { @history.entries[1].time == @times[2] }
    end

    def test_reset
      @history.reset
      assert { @history.size == 0 }
      assert { !@history.file.exist? }
    end

    def test_last_entry
      last = @history.last_entry
      assert { last != nil }
      assert { last.time == @times[2] }
    end

    def test_index
      entry = @history['a']
      assert { entry != nil }
      assert { entry.time == @times[0] }
      assert { entry.name == 'a' }
    end

  end

end