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
        allow(Tml.session).to receive(:inline_mode?).and_return(false)
      end

      it "returns false by default" do
        expect(client.live_api_request?).to be_falsey
      end

      context "inline_mode" do
        before do
          allow(Tml.session).to receive(:inline_mode?).and_return(true)
          allow(Tml.session).to receive(:block_option).with(:live).and_return(true)
        end

        it "returns true" do
          expect(client.live_api_request?).to be_truthy
        end
      end

      context "has block_option(:live)" do
        before do
          allow(Tml.session).to receive(:inline_mode?).and_return(false)
          allow(Tml.session).to receive(:block_option).with(:live).and_return(true)
        end

        it "returns true" do
          expect(client.live_api_request?).to be_truthy
        end
      end
    end
  end

  describe 'get_cdn_path' do
    before { allow(application).to receive(:key).and_return('abc_123') }

    context 'no slash in url' do
      before { allow(application).to receive(:cdn_host).and_return('www.example.com') }
      it { expect(client.get_cdn_path('version')).to eq 'www.example.com/abc_123/version.json' }
    end

    context 'slash in base path' do
      before { allow(application).to receive(:cdn_host).and_return('www.example.com/') }
      it { expect(client.get_cdn_path('version')).to eq 'www.example.com/abc_123/version.json' }
    end

    context 'no base_path' do
      it { expect(client.get_cdn_path('version')).to eq '/abc_123/version.json' }
    end
  end
end
