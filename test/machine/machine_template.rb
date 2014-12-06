class MachineTestSubject
  include Transitions

  state_machine :initial => :open do
    state :open
    state :closed

    event :shutdown do
      transitions :from => :open, :to => :closed
    end

    event :timeout do
      transitions :from => :open, :to => :closed
    end

    event :restart do
      transitions :from => :closed, to: :open, guard: :restart_allowed?
    end
  end

  def restart_allowed?(allowed = true)
    allowed
  end

  def event_failed(*)
  end
end
