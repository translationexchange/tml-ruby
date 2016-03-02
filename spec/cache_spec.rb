# encoding: UTF-8

require 'spec_helper'

# mock the Cache Adapters tested below
require 'mock_redis'
class Redis < MockRedis ; end
require 'memcache_mock'
module Dalli
  class Client < MemcacheMock
    def initialize(*args)
      super()
    end
  end
end

describe Tml::Cache do
  describe "#initialize" do
    it "features" do
      expect(Tml.cache.strip_extensions({'a' => '123', 'extensions' => 'abc'})).to eq({'a' => '123'})
      expect(Tml.cache.strip_extensions({'a' => '123', 'extensions' => 'abc'}.to_json)).to eq({'a' => '123'}.to_json)

      Tml.cache.info('Test')
      Tml.cache.warn('Test')
    end
  end

  describe "Cache Adapters" do
    around(:each) do |example|
      # save and restore the original cache
      original_cache = Tml.cache
      Tml.instance_variable_set(:@cache, nil)
      example.run
      Tml.instance_variable_set(:@cache, original_cache)
    end


    it 'returns a file cache' do
      tempfile = Tempfile.new('cache.dat')
      allow(Tml.config).to receive(:cache).and_return({adapter: 'file', path: tempfile.path})
      expect(Tml.cache).to be_kind_of(Tml::CacheAdapters::File)
    end

    it 'returns a memcache cache' do
      allow(Tml.config).to receive(:cache).and_return({adapter: 'memcache'})
      expect(Tml.cache).to be_kind_of(Tml::CacheAdapters::Memcache)
    end

    it 'returns a redis cache' do
      allow(Tml.config).to receive(:cache).and_return({adapter: 'redis'})
      expect(Tml.cache).to be_kind_of(Tml::CacheAdapters::Redis)
    end
  end
end
