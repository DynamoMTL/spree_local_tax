require 'avalara'

module Spree
  class Calculator::AvalaraTax < Calculator::LocalTax
    def self.description
      I18n.t(:avalara_tax)
    end

    def compute_line_item(line_item)

      invoice = avalara.generate(line_item, rate.tax_category)
      amount  = avalara.compute(invoice)

      round_to_two_places(amount)
    rescue
      0
    end

  private
    def avalara
      SpreeLocalTax::Avalara
    end
  end
end

