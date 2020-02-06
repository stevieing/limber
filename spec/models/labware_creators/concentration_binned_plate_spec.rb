# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

RSpec.describe LabwareCreators::ConcentrationBinnedPlate do
  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has no custom page'

  has_a_working_api

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:plate_size) { 96 }

  let(:well_a1) do
    create(:v2_well,
           position: { 'name' => 'A1' },
           qc_results: create_list(:qc_result_concentration, 1, value: 1.5),
           requests_as_source: [requests[0]],
           outer_request: nil)
  end
  let(:well_b1) do
    create(:v2_well,
           position: { 'name' => 'B1' },
           qc_results: create_list(:qc_result_concentration, 1, value: 56.0),
           requests_as_source: [requests[1]],
           outer_request: nil)
  end
  let(:well_c1) do
    create(:v2_well,
           position: { 'name' => 'C1' },
           qc_results: create_list(:qc_result_concentration, 1, value: 3.5),
           requests_as_source: [requests[2]],
           outer_request: nil)
  end
  let(:well_d1) do
    create(:v2_well,
           position: { 'name' => 'D1' },
           qc_results: create_list(:qc_result_concentration, 1, value: 1.8),
           requests_as_source: [requests[3]],
           outer_request: nil)
  end

  let(:parent_plate) do
    create :v2_plate,
           uuid: parent_uuid,
           barcode_number: '2',
           size: plate_size,
           wells: [well_a1, well_b1, well_c1, well_d1],
           outer_requests: requests
  end

  let(:child_plate) do
    create :v2_plate,
           uuid: 'child-uuid',
           barcode_number: '3',
           size: plate_size,
           outer_requests: requests
  end

  let(:library_type_name) { 'Test Library Type' }

  let(:requests) { Array.new(4) { |i| create :library_request, state: 'pending', uuid: "request-#{i}", library_type: library_type_name } }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  before do
    create :concentration_binning_purpose_config,
           uuid: child_purpose_uuid,
           name: child_purpose_name,
           library_type_name: library_type_name
    stub_v2_plate(child_plate, stub_search: false)
    stub_v2_plate(
      parent_plate,
      stub_search: false,
      custom_includes: 'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,wells.aliquots.request.request_type'
    )
  end

  let(:form_attributes) do
    {
      purpose_uuid: child_purpose_uuid,
      parent_uuid: parent_uuid,
      user_uuid: user_uuid
    }
  end

  subject do
    LabwareCreators::ConcentrationBinnedPlate.new(api, form_attributes)
  end

  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a LabwareCreators::ConcentrationBinnedPlate
    end

    context 'when wells are missing a concentration value' do
      let(:well_e1) do
        create(:v2_well,
               position: { 'name' => 'E1' },
               qc_results: [])
      end

      let(:parent_plate) do
        create :v2_plate,
               uuid: parent_uuid,
               barcode_number: '2',
               size: plate_size,
               wells: [well_a1, well_b1, well_c1, well_d1, well_e1],
               outer_requests: requests
      end

      it 'fails validation' do
        expect(subject).to_not be_valid
      end
    end
  end

  shared_examples 'a concentration binned plate creator' do
    describe '#save!' do
      let!(:plate_creation_request) do
        stub_api_post('plate_creations',
                      payload: { plate_creation: {
                        parent: parent_uuid,
                        child_purpose: child_purpose_uuid,
                        user: user_uuid
                      } },
                      body: json(:plate_creation))
      end

      let!(:transfer_creation_request) do
        stub_api_post('transfer_request_collections',
                      payload: { transfer_request_collection: {
                        user: user_uuid,
                        transfer_requests: transfer_requests
                      } },
                      body: '{}')
      end

      it 'makes the expected requests' do
        # NB. qc assay post is done using v2 Api, whereas plate creation and transfers posts are using v1 Api
        expect(Sequencescape::Api::V2::QcAssay)
          .to receive(:create).with("qc_results": dest_well_qc_attributes).and_return(true)
        expect(subject.save!).to eq true
        expect(plate_creation_request).to have_been_made
        expect(transfer_creation_request).to have_been_made
      end
    end
  end

  context '96 well plate' do
    let(:transfer_requests) do
      [
        {
          'volume' => subject.dilutions_calculator.source_volume.to_s,
          'source_asset' => well_a1.uuid,
          'target_asset' => '3-well-A1',
          'outer_request' => requests[0].uuid
        },
        {
          'volume' => subject.dilutions_calculator.source_volume.to_s,
          'source_asset' => well_b1.uuid,
          'target_asset' => '3-well-A3',
          'outer_request' => requests[1].uuid
        },
        {
          'volume' => subject.dilutions_calculator.source_volume.to_s,
          'source_asset' => well_c1.uuid,
          'target_asset' => '3-well-A2',
          'outer_request' => requests[2].uuid
        },
        {
          'volume' => subject.dilutions_calculator.source_volume.to_s,
          'source_asset' => well_d1.uuid,
          'target_asset' => '3-well-B1',
          'outer_request' => requests[3].uuid
        }
      ]
    end
    let(:dest_well_qc_attributes) do
      [
        { 'well_name' => 'A1', 'conc' => '0.42857142857142855' },
        { 'well_name' => 'B1', 'conc' => '0.5142857142857142' },
        { 'well_name' => 'A2', 'conc' => '1.0' },
        { 'well_name' => 'A3', 'conc' => '16.0' }
      ].each.map do |attribs|
        {
          'uuid' => 'child-uuid',
          'well_location' => attribs['well_name'],
          'key' => 'concentration',
          'value' => attribs['conc'],
          'units' => 'ng/ul',
          'cv' => 0,
          'assay_type' => 'ConcentrationBinningCalculator',
          'assay_version' => 'v1.0'
        }
      end
    end

    it_behaves_like 'a concentration binned plate creator'
  end
end
