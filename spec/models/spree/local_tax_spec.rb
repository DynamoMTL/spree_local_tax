require 'spec_helper'

describe Spree::LocalTax do
  before do
    # this has to be done first so the @order items are created with proper default associations
    tax_category = FactoryGirl.create :tax_category_with_local_tax, :is_default => true
    tax_category.is_default = true
    tax_category.save!


    @tax_calculator = tax_category.tax_rates.first.calculator
    @address = FactoryGirl.create :address

    # the totals are not automatically calculated
    # for line items to be picked up you have to reload
    @order = FactoryGirl.create :order_with_totals, :bill_address => @address, :ship_address => @address
    @order.reload
    @order.update!
    @order.save!
    @tax_address = Spree::Config[:tax_using_ship_address] ? @order.ship_address :  @order.bill_address
    
  end

  let(:order) { @order }
  let(:address) { @address }
  let(:tax_calculator) { @tax_calculator }
  let(:tax_address) { @tax_address }

  context "zip tax backend" do
    before do
      ZipTax.key = '123456' #real key is required in production. VCR response was saved with a proper key
      @zip_tax_category = FactoryGirl.create :tax_category_with_zip_tax
      @calculator = @zip_tax_category.tax_rates.first.calculator
    end
    it "should return rates from ZipTax API" do
      VCR.use_cassette('zip_tax_response') do
        tax_amount = @calculator.find_local_tax(order.ship_address)
        tax_amount.should_not == 0.0
      end
    end
  end

  context "sql backend" do
    it "should use zones default tax rate if not overridden" do

      # 0.05 is default tax rate
      tax_amount = tax_calculator.compute(order)
      order.item_total.to_f.should_not == 0.0
      tax_amount.should == order.item_total * 0.05
    end

    it "should use default tax rate if no override" do

      # 0.05 is default tax rate
      tax_amount = tax_calculator.compute(order)
      order.item_total.to_f.should_not == 0.0
      tax_amount.should == order.item_total * 0.05
    end
    it "should not override when has only local state (w/o city or zip)" do
      
      # without state match only
      local_tax = FactoryGirl.create :local_tax, :state => tax_address.state
      local_tax.update_column :local, 0.07
      tax_calculator.compute(order).to_f.should == 0.5 #tax_amount.to_f  #0.5
    end
    it "should override when has valid state/city" do
      local_tax = FactoryGirl.create :local_tax, :state => tax_address.state, :local => 0.07
      #local_tax.update_column :local, 0.07

      # state and city match, use local_tax
      local_tax.update_column :city, "TEST"
      pending "not currently used. Needs validation."
      tax_calculator.compute(order).to_f.should == 0.5 # should be 0.7      
    end

    it "should use tax info in local_tax if zip match" do
      local_tax = FactoryGirl.create :local_tax,  :zip => tax_address.zipcode
      order.item_total.to_f.should == 10.0
      tax_calculator.compute(order).to_f.should == 0.66 #tax_amount.to_f #0.66

      local_tax = FactoryGirl.create :local_tax, :state => tax_address.state, :zip => tax_address.zipcode
      order.item_total.to_f.should == 10.0
      tax_calculator.compute(order).to_f.should == 0.66 #tax_amount.to_f #0.66
    end

    it "should calculate the taxable amount only on item total" do
      calculator = tax_calculator
      order.item_total.to_f.should_not == 0.0

      # without promotion or shipping
      calculator.taxable_amount(order).should == order.item_total.to_f

      # shipping
      order.shipping_method = FactoryGirl.create :shipping_method
      order.create_shipment!
      sa=order.adjustments.shipping.first
      sa.amount=BigDecimal("25.99")
      sa.save
      order.adjustments.shipping.count.should == 1
      order.adjustments.count.should == 1
      calculator.taxable_amount(order).to_f.should == order.item_total

      # added cost.
      order.adjustments.create!({ :label => I18n.t(:promotion), :amount => 20.0 })
      order.adjustments.count.should == 2
      order.save!
      amt = order.item_total #not 30.
      calculator.taxable_amount(order).to_f.should == order.item_total  # not 30

      # credit
      order.adjustments.create!({ :label => 'another adjustment', :amount => -10.0 })
      order.save!
      order.adjustments.count.should == 3 # shipping + promotion + other
      calculator.taxable_amount(order).to_f.should == order.item_total # still 10. 
    end
  end

  context "tax cloud backend" do
    
  end
end
