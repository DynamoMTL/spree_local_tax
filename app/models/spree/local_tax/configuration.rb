module SpreeLocalTax
  class Configuration < Spree::Preferences::Configuration
    preference :avalara_username, :string
    preference :avalara_password, :string
    preference :avalara_endpoint, :string, default: 'https://rest.avalara.net'
    preference :origin_address1, :string
    preference :origin_address2, :string
    preference :origin_city, :string
    preference :origin_state, :string
    preference :origin_country, :string
    preference :origin_zipcode, :string
    preference :include_order_promo_in_tax_calculation, default: false
  end
end
