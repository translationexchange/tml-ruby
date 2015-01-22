# encoding: UTF-8

require 'spec_helper'

describe Tml::Logger do
  it "must provide correct data" do
    Tml.logger.trace_api_call("/test", {}) do
      # do nothing
    end

    Tml.logger.trace("Testing code") do
      # do nothing
    end
  end
end
