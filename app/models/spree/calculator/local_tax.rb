require_dependency 'spree/calculator'

module Spree
  class Calculator::LocalTax < Calculator::DefaultTax
    def self.description
      I18n.t(:local_tax)
    end

    # When it comes to computing shipments or line items: same same.
    def compute_line_item(item)
      address = case item
      when Spree::LineItem
        item.order.ship_address
      when Spree::Shipment
        item.address
      end
      tax_rate = find_local_tax_rate(address)
      round_to_two_places(item.discounted_amount * tax_rate)
    end

    def find_local_tax_rate(address)
      return rate.amount if address.blank?
      local_tax = Spree::LocalTax.where(city: address.city.upcase, state_id: address.state.id).first ||
      Spree::LocalTax.where(zip: address.zipcode[0,5]).first
      local_tax.present? ? local_tax.rate : rate.amount
    end
  end
end

