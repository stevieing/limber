# frozen_string_literal: true

class StateChangers::AutoPoolingStateChanger < StateChangers::DefaultStateChanger
  def move_to!(state, reason, customer_accepts_responsibility = false)
    super
    change_tube_states_to_passed! if state == 'passed'
  end

  # Updates the plate so that it pools into the tubes and then updates their state to be passed,
  # as this is effectively what the lab technicians are doing.
  def change_tube_states_to_passed!
    # Reload the plate so that we can use the tubes
    api.plate.find(labware_uuid).coerce.tubes.each do |tube|
      api.state_change.create!(
        target: tube.uuid,
        target_state: 'passed',
        user: user_uuid
      )
    end
  end
  private :change_tube_states_to_passed!
end
