# frozen_string_literal: true

module LabwareCreators
  # Creates a new tube per submission, and transfers all the wells matching that submission
  # into each tube.
  class PooledTubesBySubmission < Base
    attr_reader :tube_transfer

    self.default_transfer_template_uuid = Settings.transfer_templates['Transfer wells to specific tubes defined by submission']

    def create_labware!
      child_stock_tubes = api.specific_tube_creation.create!(
        user: user_uuid,
        parent: parent_uuid,
        child_purposes: [purpose_uuid] * pool_uuids.length,
        tube_attributes: tube_attributes
      ).children


      api.transfer_template.find(default_transfer_template_uuid).create!(
        user: user_uuid,
        source: parent_uuid,
        targets: Hash[pool_uuids.zip(child_stock_tubes.map(&:uuid))]
      )
      true
    rescue
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace)
      false
    end

    def parent
      @parent ||= api.plate.find(parent_uuid)
    end

    def pool_uuids
      parent.pools.keys
    end

    # We may create multiple tubes, so cant redirect onto any particular
    # one. Redirecting back to the parent is a little grim, so we'll need
    # to come up with a better solution.
    # 1) Redirect to the transfer/creation and list the tubes that way
    # 2) Once tube racks are implemented, we can redirect there.
    def child
      parent
    end

    private

    def tube_attributes
      pools.values.map do |pool_details|
        { name: name_for(pool_details) }
      end
    end

    def name_for(pool_details)
      wells = pool_details['wells']
      # Wells SHOULD already be sorted
      "#{stock_plate_barcode} #{wells.first}:#{wells.last}"
    end

    def stock_plate_barcode
      "#{parent.stock_plate.barcode.prefix}#{parent.stock_plate.barcode.number}"
    end

    delegate :pools, to: :parent

    #
    # Maps well locations to the corresponding uuid
    #
    # @return [Hash] Hash with well locations (eg. 'A1') as keys, and uuids as values
    #
    def well_locations
      @well_locations ||= parent.wells.each_with_object({}) do |w, hash|
        hash[w.location] = w.uuid
      end
    end
  end
end
