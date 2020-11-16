# frozen_string_literal: true

RSpec.describe Peatio::Thought::Client do
  let(:uri) { "http://admin:admin@127.0.0.1:10617" }
  let(:uri_without_authority) { "http://127.0.0.1:10617" }

  before(:all) { WebMock.disable_net_connect! }
  after(:all) { WebMock.allow_net_connect! }

  subject { Peatio::Thought::Client.new(uri) }

  context :initialize do
    it { expect { subject }.not_to raise_error }
  end

  context :json_rpc do
    let(:response) do
      JSON.parse(File.read(response_file))
    end

    context :getblockcount do
      let(:response_file) do
        File.join("spec", "resources", "getblockcount", "response.json")
      end

      before do
        stub_request(:post, uri_without_authority)
          .with(body: {jsonrpc: "1.0",
                        method: :getblockcount,
                        params:  []}.to_json)
          .to_return(body: response.to_json)
      end

      it { expect { subject.json_rpc(:getblockcount) }.not_to raise_error }
      it { expect(subject.json_rpc(:getblockcount)).to eq(602_299) }
    end

    context :methodnotfound do
      let(:response_file) do
        File.join("spec", "resources", "methodnotfound", "error.json")
      end

      before do
        stub_request(:post, uri_without_authority)
          .with(body: {jsonrpc: "1.0",
                        method: :methodnotfound,
                        params:  []}.to_json)
          .to_return(body: response.to_json)
      end

      it do
        expect { subject.json_rpc(:methodnotfound) }.to \
          raise_error(Peatio::Thought::Client::ResponseError, "Method not found (-32601)")
      end
    end

    context :notfound do
      let(:response_file) do
        File.join("spec", "resources", "methodnotfound", "error.json")
      end

      before do
        stub_request(:post, uri_without_authority)
          .with(body: {jsonrpc: "1.0",
                        method: :notfound,
                        params:  []}.to_json)
          .to_return(body: response.to_json, status: 404)
      end

      it do
        expect { subject.json_rpc(:notfound) }.to \
          raise_error(Peatio::Thought::Client::Error)
      end
    end

    context :connectionerror do
      before do
        Faraday::Connection.any_instance.expects(:post).raises(Faraday::Error.new("Something went wrong")).once
      end

      it do
        expect { subject.json_rpc(:connectionerror) }.to \
          raise_error(Peatio::Thought::Client::ConnectionError)
      end
    end
  end
end
