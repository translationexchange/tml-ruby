# encoding: UTF-8

require 'spec_helper'

describe Tml::Api::Client do

  let(:application) { init_application }
  let(:client) { described_class.new(application: application)}

  describe "#live_api_request?" do
    context "application is missing api token" do
      it "returns false" do
        expect(client.live_api_request?).to be_falsey
      end
    end

    context "application has api token" do
      before do
        allow(application).to receive(:token).and_return('token')
      end

      it "returns false by default" do
        expect(client.live_api_request?).to be_falsey
      end

      context "inline_mode" do
        before do
          allow(Tml.session).to receive(:inline_mode?).and_return(true)
        end

        it "returns true" do
          expect(client.live_api_request?).to be_truthy
        end
      end

      context "has block_option(:live)" do
        before do
          allow(Tml.session).to receive(:block_option).with(:live).and_return(true)
        end

        it "returns true" do
          expect(client.live_api_request?).to be_truthy
        end
      end
    end
  end
end
