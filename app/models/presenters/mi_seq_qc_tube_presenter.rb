# frozen_string_literal: true

module Presenters
  class MiSeqQCTubePresenter < TubePresenter
    include RobotControlled

    state_machine :state, initial: :pending do
      event :start do
        transition pending: :started
      end

      event :take_default_path do
        transition pending: :passed
        transition passed: :qc_complete
      end

      event :pass do
        transition [:pending, :started] => :passed
      end

      event :fail do
        transition [:passed] => :failed
      end

      event :cancel do
        transition [:pending, :started] => :cancelled
      end

      state :pending do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :started do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :passed do
        include Statemachine::StateDoesNotAllowChildCreation
      end
    end
  end
end
