# frozen_string_literal: true

module Forms
  class MultiPlatePoolingForm < CreationForm
    include Forms::Form::CustomPage

    self.page = 'multi_plate_pooling'
    self.aliquot_partial = 'custom_pooled_aliquot'
    self.default_transfer_template_uuid = Settings.transfer_templates['Pool wells based on submission']
    self.attributes = [:api, :purpose_uuid, :parent_uuid, :user_uuid, :transfers, :plates]

    def create_objects!(_selected_transfer_template_uuid = default_transfer_template_uuid)
      @plate_creation = api.pooled_plate_creation.create!(
        parents: transfers.keys,
        child_purpose: purpose_uuid,
        user: user_uuid
      )

      api.bulk_transfer.create!(
        source: parent_uuid,
        user: user_uuid,
        well_transfers: well_transfers
      )

      yield(@plate_creation.child) if block_given?
      true
    end
    private :create_objects!

    def well_transfers
      transfers = []
      each_well do |source_uuid, source_well, destination_uuid, destination_well|
        transfers << {
          'source_uuid' => source_uuid,
          'source_location' => source_well,
          'destination_uuid' => destination_uuid,
          'destination_location' => destination_well
        }
      end
      transfers
    end
    private :well_transfers

    def each_well
      transfers.each do |source_uuid, transfers|
        transfers.each do |source_well, destination_well|
          yield(source_uuid, source_well, @plate_creation.child.uuid, destination_well)
        end
      end
    end
    private :each_well
  end
end
