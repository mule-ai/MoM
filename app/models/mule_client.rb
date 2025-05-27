class MuleClient < ApplicationRecord
  validates :name, presence: true
  validates :host, presence: true
  validates :port, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :status, inclusion: { in: %w[active inactive unverified] }

  serialize :capabilities, coder: JSON

  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }

  def capabilities=(value)
    case value
    when Array
      super(value)
    when String
      super(value.present? ? [value] : [])
    else
      super([])
    end
  end

  def capabilities
    result = super
    result.is_a?(Array) ? result : []
  end

  def address
    "#{host}:#{port}"
  end

  def last_heartbeat_timestamp
    last_heartbeat&.to_i || 0
  end
end