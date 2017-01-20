# frozen_string_literal: true
require 'rails_helper'

describe Robots::Robot do

  include FeatureHelpers

  

  let(:api)                         { Sequencescape::Api.new(Limber::Application.config.api_connection_options) }
  let(:settings)                    { YAML::load_file(File.join(Rails.root, "spec", "data", "settings.yml")).with_indifferent_access }
  let(:user_uuid)                   { SecureRandom.uuid }
  let(:plate_uuid)                  { SecureRandom.uuid }
  let(:plate)                       { json :stock_plate, uuid: plate_uuid }
  let(:metadata_uuid)               { SecureRandom.uuid }
  let(:custom_metadatum_collection) { json :custom_metdatum_collection, uuid: metadata_uuid }

  describe '#verify' do

    describe 'plate and bed' do

      let(:robot) { Robots::Robot.find(id: "robot_id", api: api, user_uuid: user_uuid)}

      before(:each) do
        Settings.robots["robot_id"] = settings[:robots][:robot_id]
      end

      has_a_working_api


      it 'returns an error if there is an invalid bed' do
        stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => "dodgy_barcode" } }, nil)
        expect(robot.verify(settings[:robots][:robot_id][:beds].keys.first => ["dodgy_barcode"])[:valid]).to be_falsey
      end

      it 'returns an error if the plate is not on the right bed' do
        stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => "plate_barcode" } }, plate)
        expect(robot.verify(settings[:robots][:robot_id][:beds].keys.first => ["plate_barcode"])[:valid]).to be_falsey
      end
    end

    describe 'robot barcode' do

      has_a_working_api(times: 1)

      let(:robot)                       { Robots::Robot.find(id: "robot_id_2", api: api, user_uuid: user_uuid)}

      before(:each) do
        Settings.purpose_uuids['Limber Cherrypicked'] = 'limber_cherrypicked_uuid'
        Settings.robots["robot_id_2"] = settings[:robots][:robot_id_2]
      end

      it 'returns an error if the robot barcode does not match the plate metadata robot barcode' do
        plate_json = json :stock_plate, uuid: plate_uuid, barcode_number: "123", purpose_uuid: 'limber_cherrypicked_uuid', state: 'passed'
        stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => "123" } }, plate_json)
        
        expect(robot.verify(settings[:robots][:robot_id_2][:beds].keys.first => ["123"])[:valid]).to be_falsey
        
        plate_json = json :stock_plate_with_metadata, uuid: plate_uuid, barcode_number: "123", purpose_uuid: 'limber_cherrypicked_uuid', state: 'passed', custom_metadatum_collection_uuid: 'custom_metadatum_collection-uuid'
        stub_api_get('custom_metadatum_collection-uuid', body: json(:custom_metadatum_collection, uuid: 'custom_metadatum_collection-uuid'))

        stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => "123" } }, plate_json)
        expect(robot.verify({ settings[:robots][:robot_id_2][:beds].keys.first => ["123"] }, "robot_barcode")[:valid]).to be_falsey

        stub_api_get('custom_metadatum_collection-uuid', body: json(:custom_metadatum_collection, metadata: {"created_with_robot" => "robot_barcode"}, uuid: 'custom_metadatum_collection-uuid'))
        expect(robot.verify({ settings[:robots][:robot_id_2][:beds].keys.first => ["123"] }, "robot_barcode")[:valid]).to be_truthy


      end

    end

  end
end