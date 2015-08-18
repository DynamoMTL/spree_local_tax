module SpreeLocalTax::Avalara
  extend self

  def generate(line_item, tax_category)
    order = line_item.order
    address = Spree::Config.tax_using_ship_address ? order.ship_address : order.bill_address
    builder = InvoiceBuilder.new

    builder.customer = order.email if order.email.present?

    builder.add_destination(address.address1, address.address2, address.city, address.state.try(:abbr) || address.state_name, address.country.iso, address.zipcode)
    builder.add_origin(config.origin_address1, config.origin_address2, config.origin_city, config.origin_state, config.origin_country, config.origin_zipcode)

    variant = line_item.variant
    product = variant.product

    line_item_amount = line_item.discounted_amount
    line_item_amount += promo_amount_per_item(line_item) if SpreeLocalTax::Config.include_order_promo_in_tax_calculation

    builder.add_line(variant.sku, product.name, line_item.quantity, line_item_amount) if product.tax_category == tax_category

    builder.invoice
  end

  def compute(invoice)
    ::Avalara.username = SpreeLocalTax::Config.avalara_username
    ::Avalara.password = SpreeLocalTax::Config.avalara_password
    ::Avalara.endpoint = SpreeLocalTax::Config.avalara_endpoint

    response = ::Avalara.get_tax(invoice)

    response.tax_lines.inject(0) {|sum, line| sum + line.tax.to_f }
  end

  def promo_amount_per_item(line_item)
    promotions_total = line_item.order.all_adjustments.promotion.eligible.sum(:amount)
    line_item_count = line_item.order.line_items.count

    ((line_item_count > 0) ? (promotions_total / line_item_count) : 0)
  end

private
  def config
    SpreeLocalTax::Config
  end
end

