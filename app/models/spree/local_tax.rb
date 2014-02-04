class Spree::LocalTax < ActiveRecord::Base
  belongs_to :state, :class_name => "Spree::State"

  def rate
    state.tax + local + other
  end
end
