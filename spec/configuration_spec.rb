require "spec_helper"

RSpec.describe BunnyCdn::Configuration do
    it "has configuration class" do
    end

    describe "#configure" do
        it "has default values of nil" do
            config = BunnyCdn::Configuration.new
            expect(config.storageZone).to eq(nil)
            expect(config.region).to eql(nil)
            expect(config.accessKey).to eq(nil)
        end
    end

    describe "#configure=" do
        it "is able to accept values" do
            config = BunnyCdn::Configuration.new
            config.storageZone = 'test'
            config.region = 'eu'
            config.accessKey = 'test'
            expect(config.storageZone).to eq('test')
            expect(config.region).to eq('eu')
            expect(config.accessKey).to eq('test')
        end
    end

    describe "#configuration" do
        before do
            BunnyCdn.configure do |config|
                config.storageZone = 'test'
                config.region = 'eu'
                config.accessKey = 'test'
            end
        end
        it "can read configuration values" do
            expect(BunnyCdn.configuration.storageZone).to eq('test')
            expect(BunnyCdn.configuration.region).to eq('eu')
            expect(BunnyCdn.configuration.accessKey).to eq('test')
        end
    end

end