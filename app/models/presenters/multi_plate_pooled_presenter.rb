# frozen_string_literal: true

class Presenters::MultiPlatePooledPresenter < Presenters::PooledPresenter
  self.summary_partial = 'labware/plates/multi_pooled_plate'
  self.printing_partial = 'labware/plates/tube_printing'

  include Presenters::ExtendedCsv

  alias transfers transfers_for_csv

  include Presenters::Statemachine
  state_machine :state, initial: :pending do
    Presenters::Statemachine::StateTransitions.inject(self)
    state :pending do
      include Presenters::Statemachine::StateDoesNotAllowChildCreation
    end
    state :started do
      include Presenters::Statemachine::StateDoesNotAllowChildCreation
    end

    state :nx_in_progress do
      include Presenters::Statemachine::StateDoesNotAllowChildCreation
    end

    event :pass do
      transition [:nx_in_progress] => :passed
    end

    state :passed do
      include Presenters::Statemachine::StateAllowsChildCreation
    end

    state :failed do
    end
    state :cancelled do
    end
  end

  def csv_file_links
    links = []
    (labware.creation_transfers.count / 4.0).ceil.times do |i|
      links << [i + 1, "#{Rails.application.routes.url_helpers.limber_plate_path(plate.uuid)}.csv?offset=#{i}"]
    end
    links
  end

  def filename(offset = nil)
    return true if offset.nil?
    "#{plate.stock_plate.barcode.prefix}#{plate.stock_plate.barcode.number}_#{offset.to_i + 1}.csv"
  end

  def target_plate_transfers
    Hash[labware.creation_transfers.map { |tf| tf.transfers.values }.flatten.uniq.map { |v| [v, v] }]
  end
end
