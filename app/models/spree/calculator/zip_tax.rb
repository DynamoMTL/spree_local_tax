module Spree
  class Calculator::ZipTax < Calculator::LocalTax
    def self.description
      I18n.t(:zip_tax)
    end

    def find_local_tax(address)
      ::ZipTax.rate(address.zipcode[0,5])
    end

    private

    def compute_order(order)
      tax_address = Spree::Config[:tax_using_ship_address] ? order.ship_address :  order.bill_address
      local_tax = find_local_tax(tax_address)
      tax_rate = local_tax.present? ? local_tax : 0

      # TODO the only issue here is that the label text for the adjustment is not calculated
      # based on the rate method here, the TaxRate.amount is used instead
      # need to modify https://github.com/spree/spree/blob/master/core/app/models/spree/tax_rate.rb#L47

      round_to_two_places(taxable_amount(order) * tax_rate)
    end
  end

end
