# frozen_string_literal: true

RSpec.describe Peatio::Thought::Blockchain do
  context :features do
    it "defaults" do
      blockchain1 = Peatio::Thought::Blockchain.new
      expect(blockchain1.features).to eq Peatio::Thought::Blockchain::DEFAULT_FEATURES
    end

    it "override defaults" do
      blockchain2 = Peatio::Thought::Blockchain.new(cash_addr_format: true)
      expect(blockchain2.features[:cash_addr_format]).to be_truthy
    end

    it "custom feautures" do
      blockchain3 = Peatio::Thought::Blockchain.new(custom_feature: :custom)
      expect(blockchain3.features.keys).to contain_exactly(*Peatio::Thought::Blockchain::SUPPORTED_FEATURES)
    end
  end

  context :configure do
    let(:blockchain) { Peatio::Thought::Blockchain.new }
    it "default settings" do
      expect(blockchain.settings).to eq({})
    end

    it "currencies and server configuration" do
      currencies = [{id: :thought,
                      base_factor: 100_000_000,
                      options: {}}]
      settings = {server: "http://admin:admin@127.0.0.1:10617",
                   currencies: currencies,
                   something: :custom}
      blockchain.configure(settings)
      expect(blockchain.settings).to eq(settings.slice(*Peatio::Blockchain::Abstract::SUPPORTED_SETTINGS))
    end
  end

  context :latest_block_number do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:server) { "http://admin:admin@127.0.0.1:10617" }
    let(:server_without_authority) { "http://127.0.0.1:10617" }

    let(:response) do
      JSON.parse(File.read(response_file))
    end

    let(:response_file) do
      File.join("spec", "resources", "getblockcount", "response.json")
    end

    let(:blockchain) do
      Peatio::Thought::Blockchain.new.tap {|b| b.configure(server: server) }
    end

    before do
      stub_request(:post, server_without_authority)
        .with(body: {jsonrpc: "1.0",
                      method: :getblockcount,
                      params:  []}.to_json)
        .to_return(body: response.to_json)
    end

    it "returns latest block number" do
      expect(blockchain.latest_block_number).to eq(602_299)
    end

    it "raises error if there is error in response body" do
      stub_request(:post, "http://127.0.0.1:10617")
        .with(body: {jsonrpc: "1.0",
                      method: :getblockcount,
                      params:  []}.to_json)
        .to_return(body: {result: nil,
                           error:  {code: -32_601, message: "Method not found"},
                           id:     nil}.to_json)

      expect { blockchain.latest_block_number }.to raise_error(Peatio::Blockchain::ClientError)
    end
  end

  context :build_transaction do
    let(:raw_transaction) do
      {"txid" => "ab5a181080ad50979933bc59bcb2c5c87b12b67529b250c9812c0d9a056891cf",
       "hash" => "0004927e5dc70f861df8f38be99f8d307e9604dac32e7bda1e5a4e4288756984",
       "version" => 2,
       "size" => 225,
       "locktime" => 602_298,
       "vin" =>
         [{"txid" => "378d395923e2aba16c448575115a7cdc2c8cd21ba167bd83cd5849f6d0cc897c",
           "vout" => 0,
           "scriptSig" =>
             {"asm" => "3044022022f8b9b830a21b61b369fbb650596868cfdb5185d4804e471d8f83245ebcb6d402206739b8e1cc5616c7a"\
                       "9dbcf165b23dee4c6b9b8deae7b4ac56a06e602c552b64b",
              "hex" => "473044022022f8b9b830a21b61b369fbb650596868cfdb5185d4804e471d8f83245ebcb6d402206739b8e1cc5616c"\
                       "7a9dbcf165b23dee4c6b9b8deae7b4ac56a06e602c552b64b0121037aab64a80d7c6fc591da0deb3839b25b50c984"\
                       "1d447ab55f76b8fcd2f419bf42"}}],
       "vout" =>
         [{"value" => 134.22200000,
           "valueSat" => 13_422_200_000,
           "n" => 0,
           "scriptPubKey" =>
             {"asm" => "OP_DUP OP_HASH160 711cddcba317b1cec613c802c9b79645ead976d4 OP_EQUALVERIFY OP_CHECKSIG",
              "hex" => "76a914711cddcba317b1cec613c802c9b79645ead976d488ac",
              "reqSigs" => 1,
              "type" => "pubkeyhash",
              "addresses" => ["3pqX1YkaxHKdD8pX2DR6j6vpXKq9dZWLxp"]}},
          {"value" => 74.54849774,
           "valueSat" => 7_454_849_774,
           "n" => 1,
           "scriptPubKey" =>
             {"asm" => "OP_DUP OP_HASH160 78e0a89f3c685eb79ef802caab84fe7c8e3d3227 OP_EQUALVERIFY OP_CHECKSIG",
              "hex" => "76a91478e0a89f3c685eb79ef802caab84fe7c8e3d322788ac",
              "reqSigs" => 1,
              "type" => "pubkeyhash",
              "addresses" => ["3v1VnMT6in6C1pAe1DaHGWrAByHacXPnCn"]}}],
       "hex" =>
         "0200000000010128b432862b8e4022ec1302086e6eb4b63c88fe09be89ce532859b2c1fa7455fc0000000017160014ab96ef2628ff8"\
         "73662ebd77f522aecf16c224495feffffff03809698000000000017a914869bf1331ba9fe042ba7c06455d8c2bcb0b2a20887002d31"\
         "010000000017a9144c69a52518526c13b234f1e88e163feed08739c887e448b3000000000017a9141d4f141e0ee4f0121bef6e2d14c"\
         "852b679ceceaa8702483045022100af57fa2d9e948fa2c7541dba8a02886aeaf4800a9726d0451dc0eeb1dc79488e022059bbfec78f"\
         "3c0c07918008afde040ee5816cb7c84e3f09e3c5d30832acaca7400121026f7eeba4cbf41edbfab5cba1d476d1942aada8dc3bbedbd"\
         "4db87b0ecfdfc8cfb99ab1400"}
    end

    context "three vout tx" do
      let(:expected_transactions) do
        [{hash: "ab5a181080ad50979933bc59bcb2c5c87b12b67529b250c9812c0d9a056891cf",
          txout: 0,
          to_address: "3pqX1YkaxHKdD8pX2DR6j6vpXKq9dZWLxp",
          amount: 134.22200,
          status: "success",
          currency_id: :thought},
         {hash: "ab5a181080ad50979933bc59bcb2c5c87b12b67529b250c9812c0d9a056891cf",
          txout: 1,
          to_address: "3v1VnMT6in6C1pAe1DaHGWrAByHacXPnCn",
          amount: 74.54849774,
          status: "success",
          currency_id: :thought}]
      end

      let(:currency) do
        {id: :thought,
          base_factor: 100_000_000,
          options: {}}
      end

      let(:blockchain) do
        Peatio::Thought::Blockchain.new.tap {|b| b.configure(currencies: [currency]) }
      end

      it "builds formatted transactions for passed transaction" do
        expect(blockchain.send(:build_transaction, raw_transaction)).to contain_exactly(*expected_transactions)
      end
    end

    context "multiple currencies" do
      let(:currency1) do
        {id: :thought1,
          base_factor: 100_000_000,
          options: {}}
      end

      let(:currency2) do
        {id: :thought2,
          base_factor: 100_000_000,
          options: {}}
      end

      let(:expected_transactions) do
        [{hash: "ab5a181080ad50979933bc59bcb2c5c87b12b67529b250c9812c0d9a056891cf",
          txout: 0,
          to_address: "3pqX1YkaxHKdD8pX2DR6j6vpXKq9dZWLxp",
          amount: 134.22200,
          status: "success",
          currency_id: :thought1},
         {hash: "ab5a181080ad50979933bc59bcb2c5c87b12b67529b250c9812c0d9a056891cf",
          txout: 0,
          to_address: "3pqX1YkaxHKdD8pX2DR6j6vpXKq9dZWLxp",
          amount: 134.22200,
          status: "success",
          currency_id: :thought2},
         {hash: "ab5a181080ad50979933bc59bcb2c5c87b12b67529b250c9812c0d9a056891cf",
          txout: 1,
          to_address: "3v1VnMT6in6C1pAe1DaHGWrAByHacXPnCn",
          amount: 74.54849774,
          status: "success",
          currency_id: :thought1},
         {hash: "ab5a181080ad50979933bc59bcb2c5c87b12b67529b250c9812c0d9a056891cf",
          txout: 1,
          to_address: "3v1VnMT6in6C1pAe1DaHGWrAByHacXPnCn",
          amount: 74.54849774,
          status: "success",
          currency_id: :thought2}]
      end

      let(:blockchain) do
        Peatio::Thought::Blockchain.new.tap do |b|
          b.configure(currencies: [currency1, currency2])
        end
      end

      it "builds formatted transactions for passed transaction per each currency" do
        expect(blockchain.send(:build_transaction, raw_transaction)).to contain_exactly(*expected_transactions)
      end
    end

    context "single vout transaction" do
      let(:currency) do
        {id: :thought,
          base_factor: 100_000_000,
          options: {}}
      end

      let(:blockchain) do
        Peatio::Thought::Blockchain.new.tap {|b| b.configure(currencies: [currency]) }
      end

      let(:raw_transaction) do
        {"txid" => "ab5a181080ad50979933bc59bcb2c5c87b12b67529b250c9812c0d9a056891cf",
          "version" => 2,
          "size" => 225,
         "type" => 0,
         "locktime" => 602_298,
         "vout" =>
          [{"value" => 134.22200000,
            "n" => 0,
            "scriptPubKey" =>
             {"asm" =>
                "OP_DUP OP_HASH160 711cddcba317b1cec613c802c9b79645ead976d4 OP_EQUALVERIFY OP_CHECKSIG",
              "hex" => "76a914711cddcba317b1cec613c802c9b79645ead976d488ac",
              "reqSigs" => 1,
              "type" => "pubkeyhash",
              "addresses" => ["3pqX1YkaxHKdD8pX2DR6j6vpXKq9dZWLxp"]}}],
         "hex" =>
           "02000000017c89ccd0f64958cd83bd67a11bd28c2cdc7c5a117585446ca1abe22359398d37000000006a473044022022f8b9b830a"\
           "21b61b369fbb650596868cfdb5185d4804e471d8f83245ebcb6d402206739b8e1cc5616c7a9dbcf165b23dee4c6b9b8deae7b4ac5"\
           "6a06e602c552b64b0121037aab64a80d7c6fc591da0deb3839b25b50c9841d447ab55f76b8fcd2f419bf42feffffff02c0aff6290"\
           "10000001976a914711cddcba317b1cec613c802c9b79645ead976d488aceefa57bc010000001976a91478e0a89f3c685eb79ef802"\
           "caab84fe7c8e3d322788ac4ecc0100"}
      end

      let(:expected_transactions) do
        [{hash: "ab5a181080ad50979933bc59bcb2c5c87b12b67529b250c9812c0d9a056891cf",
          txout: 0,
          to_address: "3pqX1YkaxHKdD8pX2DR6j6vpXKq9dZWLxp",
          amount: "134.22200000".to_d,
          status: "success",
          currency_id: currency[:id]}]
      end

      it "builds formatted transactions for each vout" do
        expect(blockchain.send(:build_transaction, raw_transaction)).to contain_exactly(*expected_transactions)
      end
    end
  end

  context :fetch_block! do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:server) { "http://admin:admin@127.0.0.1:10617" }
    let(:server_without_authority) { "http://127.0.0.1:10617" }

    let(:getblockhash_response_file) do
      File.join("spec", "resources", "getblockhash", "602299.json")
    end

    let(:getblockhash_response) do
      JSON.parse(File.read(getblockhash_response_file))
    end

    let(:getblock_response_file) do
      File.join("spec", "resources", "getblock", "602299.json")
    end

    let(:getblock_response) do
      JSON.parse(File.read(getblock_response_file))
    end

    let(:blockchain) do
      Peatio::Thought::Blockchain.new.tap {|b| b.configure(server: server) }
    end

    before do
      stub_request(:post, server_without_authority)
        .with(body: {jsonrpc: "1.0",
                      method: :getblockhash,
                      params:  [602_299]}.to_json)
        .to_return(body: getblockhash_response.to_json)

      stub_request(:post, server_without_authority)
        .with(body: {jsonrpc: "1.0",
                      method: :getblock,
                      params:  ["0004927e5dc70f861df8f38be99f8d307e9604dac32e7bda1e5a4e4288756984", 2]}.to_json)
        .to_return(body: getblock_response.to_json)
    end

    let(:currency) do
      {id: :thought,
        base_factor: 100_000_000,
        options: {}}
    end

    let(:server) { "http://admin:admin@127.0.0.1:10617" }
    let(:server_without_authority) { "http://127.0.0.1:10617" }
    let(:blockchain) do
      Peatio::Thought::Blockchain.new.tap {|b| b.configure(server: server, currencies: [currency]) }
    end

    subject { blockchain.fetch_block!(602_299) }

    it "builds expected number of transactions" do
      expect(subject.count).to eq(2)
    end

    it "all transactions are valid" do
      expect(subject.all?(&:valid?)).to be_truthy
    end
  end

  context :load_balance_of_address! do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:server) { "http://admin:admin@127.0.0.1:10617" }
    let(:server_without_authority) { "http://127.0.0.1:10617" }

    let(:response) do
      JSON.parse(File.read(response_file))
    end

    let(:response_file) do
      File.join("spec", "resources", "listaddressgroupings", "response.json")
    end

    let(:blockchain) do
      Peatio::Thought::Blockchain.new.tap {|b| b.configure(server: server) }
    end

    before do
      stub_request(:post, server_without_authority)
        .with(body: {jsonrpc: "1.0",
                      method: :listaddressgroupings,
                      params:  []}.to_json)
        .to_return(body: response.to_json)
    end

    context "address with balance is defined" do
      it "requests rpc listaddressgroupings and finds address balance" do
        address = "3v1VnMT6in6C1pAe1DaHGWrAByHacXPnCn"

        result = blockchain.load_balance_of_address!(address, :thought)
        expect(result).to be_a(BigDecimal)
        expect(result).to eq("74.54849774".to_d)
      end

      it "requests rpc listaddressgroupings and finds address with zero balance" do
        address = "3xGfHJZtZJroGkTPwckFW2mEhTn4EGXk4u"

        result = blockchain.load_balance_of_address!(address, :thought)
        expect(result).to be_a(BigDecimal)
        expect(result).to eq("0".to_d)
      end
    end

    context "address is not defined" do
      it "requests rpc listaddressgroupings and do not find address" do
        address = "3YY5oNb6FVY5qWx7nrfARNVwRyHwLoXcQu"
        expect { blockchain.load_balance_of_address!(address, :thought) }
          .to raise_error(Peatio::Blockchain::UnavailableAddressBalanceError)
      end
    end

    context "client error is raised" do
      before do
        stub_request(:post, "http://127.0.0.1:10617")
          .with(body: {jsonrpc: "1.0",
                        method: :listaddressgroupings,
                        params: []}.to_json)
          .to_return(body: {result: nil,
                             error:  {code: -32_601, message: "Method not found"},
                             id:     nil}.to_json)
      end

      it "raise wrapped client error" do
        expect { blockchain.load_balance_of_address!("anything", :thought) }
          .to raise_error(Peatio::Blockchain::ClientError)
      end
    end
  end
end
