# frozen_string_literal: true

RSpec.describe Peatio::Thought::Wallet do
  let(:wallet) { Peatio::Thought::Wallet.new }

  let(:uri) { "http://admin:admin@127.0.0.1:10617" }
  let(:uri_without_authority) { "http://127.0.0.1:10617" }

  let(:settings) do
    {
      wallet: {address: "something",
                uri:     uri},
      currency: {id: :thought,
                  base_factor: 100_000_000,
                  options: {}}
    }
  end

  before { wallet.configure(settings) }

  context :configure do
    let(:unconfigured_wallet) { Peatio::Thought::Wallet.new }

    it "requires wallet" do
      expect { unconfigured_wallet.configure(settings.except(:wallet)) }
        .to raise_error(Peatio::Wallet::MissingSettingError)

      expect { unconfigured_wallet.configure(settings) }.to_not raise_error
    end

    it "requires currency" do
      expect { unconfigured_wallet.configure(settings.except(:currency)) }
        .to raise_error(Peatio::Wallet::MissingSettingError)

      expect { unconfigured_wallet.configure(settings) }.to_not raise_error
    end

    it "sets settings attribute" do
      unconfigured_wallet.configure(settings)
      expect(unconfigured_wallet.settings)
        .to eq(settings.slice(*Peatio::Thought::Wallet::SUPPORTED_SETTINGS))
    end
  end

  context :create_address! do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:response) do
      response_file
        .yield_self {|file_path| File.open(file_path) }
        .yield_self {|file| JSON.parse(file.read) }
    end

    let(:response_file) do
      File.join("spec", "resources", "getnewaddress", "response.json")
    end

    before do
      stub_request(:post, uri_without_authority)
        .with(body: {jsonrpc: "1.0",
                      method: :getnewaddress,
                      params:  []}.to_json)
        .to_return(body: response.to_json)
    end

    it "request rpc and creates new address" do
      result = wallet.create_address!(uid: "UID123")
      expect(result.symbolize_keys).to eq(address: "3r67tQGzrtiWMgXt3X5xm4wSFh2gwGStvz")
    end
  end

  context :create_transaction! do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:response) do
      response_file
        .yield_self {|file_path| File.open(file_path) }
        .yield_self {|file| JSON.parse(file.read) }
    end

    let(:response_file) do
      File.join("spec", "resources", "sendtoaddress", "response.json")
    end

    before do
      stub_request(:post, uri_without_authority)
        .with(body: {jsonrpc: "1.0",
                      method: :sendtoaddress,
                      params:  [transaction.to_address,
                                transaction.amount,
                                "",
                                "",
                                false]}.to_json)
        .to_return(body: response.to_json)
    end

    let(:transaction) do
      Peatio::Transaction.new(amount: 134.22200000, to_address: "3pqX1YkaxHKdD8pX2DR6j6vpXKq9dZWLxp")
    end

    it "requests rpc and sends transaction without subtract fees" do
      result = wallet.create_transaction!(transaction)
      expect(result.amount).to eq(134.22200000)
      expect(result.to_address).to eq("3pqX1YkaxHKdD8pX2DR6j6vpXKq9dZWLxp")
      expect(result.hash).to eq("ab5a181080ad50979933bc59bcb2c5c87b12b67529b250c9812c0d9a056891cf")
    end
  end

  context :load_balance! do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:response) do
      response_file
        .yield_self {|file_path| File.open(file_path) }
        .yield_self {|file| JSON.parse(file.read) }
    end

    let(:response_file) do
      File.join("spec", "resources", "getbalance", "response.json")
    end

    before do
      stub_request(:post, uri_without_authority)
        .with(body: {jsonrpc: "1.0",
                      method: :getbalance,
                      params:  []}.to_json)
        .to_return(body: response.to_json)
    end

    it "requests rpc with getbalance call" do
      result = wallet.load_balance!
      expect(result).to be_a(BigDecimal)
      expect(result).to eq("391.37340000".to_d)
    end
  end
end
