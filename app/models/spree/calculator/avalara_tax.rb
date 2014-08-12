require 'avalara'

module Spree
  class Calculator::AvalaraTax < Calculator::LocalTax
    def self.description
      I18n.t(:avalara_tax)
    end

    def compute(line_item)
      order = line_item.order
      invoice = avalara.generate(order, rate.tax_category)
      amount  = avalara.compute(invoice)

      round_to_two_places(amount)
    rescue
      compute_order(order)
    end

  private
    def avalara
      SpreeLocalTax::Avalara
    end
  end
end
