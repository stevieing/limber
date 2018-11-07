# frozen_string_literal: true

#
# A WellFilter is created with filter options, and in turn
# yields and validates appropriate transfers
#
# @author [grl]
#
class LabwareCreators::WellFilter
  include ActiveModel::Model

  # Indicates that the filter is unable to detect which request to use
  FilterError = Class.new(LabwareCreators::ResourceInvalid)

  attr_accessor :transfer_failed, :request_type_keys, :creator

  validate :well_transfers

  def filtered
    raise FilterError, self unless valid?

    well_transfers
  end

  private

  def filter_requests(requests, well)
    return extract_submission(well) if well.requests_as_source.empty?

    filtered_requests = filter_by_request_type(requests)
    if filtered_requests.count == 1
      { 'outer_request' => filtered_requests.first.uuid }
    else
      errors.add(:base, "found #{filtered_requests.count} eligible requests for #{well.location}")
    end
  end

  def extract_submission(well)
    submission_ids = well.aliquots.map { |aliquot| aliquot.request.submission_id }.uniq
    submission_ids.one? ? { 'submission_id' => submission_ids.first } : {}
  end

  def filter_by_request_type(requests)
    requests.select { |r| @request_type_keys.blank? || @request_type_keys.include?(r.request_type.key) }
  end

  def wells
    creator.labware_wells
  end

  def well_transfers
    @well_transfers ||= wells.each_with_object([]) do |well, transfers|
      next if well.empty? || (@transfer_failed && well.failed?)

      transfers << [well, filter_requests(well.active_requests, well)]
    end
  end
end