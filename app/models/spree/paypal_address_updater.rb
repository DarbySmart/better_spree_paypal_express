module Spree
  class PaypalAddressUpdater
    def initialize(order, provider, token)
      @order = order
      @provider = provider
      @token = token
    end

    def update
      @checkout_details = @provider.get_express_checkout_details(token: @token)
      update_billing_address
      update_shipping_address
      update_email unless @order.email.present?
      @order.save
    end

    private

    def update_billing_address
      @order.billing_address ||= Spree::Address.new
      @order.billing_address.update_attributes(
        firstname: paypal_payer_info.PayerName.FirstName,
        lastname: paypal_payer_info.PayerName.LastName,
        address1: paypal_bill_address.Street1,
        address2: paypal_bill_address.Street2,
        city: paypal_bill_address.CityName,
        state: Spree::State.find_by_abbr(paypal_bill_address.StateOrProvince),
        country: Spree::Country.find_by_iso(paypal_bill_address.Country),
        zipcode: paypal_bill_address.PostalCode,
        phone: 'N/A'
      )
    end

    def update_shipping_address
      @order.shipping_address ||= Spree::Address.new
      @order.shipping_address.update_attributes(
        firstname: paypal_payer_info.PayerName.FirstName,
        lastname: paypal_payer_info.PayerName.LastName,
        address1: paypal_ship_address.Street1,
        address2: paypal_ship_address.Street2,
        city: paypal_ship_address.CityName,
        state: Spree::State.find_by_abbr(paypal_ship_address.StateOrProvince),
        country: Spree::Country.find_by_iso(paypal_ship_address.Country),
        zipcode: paypal_ship_address.PostalCode,
        phone: 'N/A'
      )
    end

    def update_email
      @order.update_attributes(email: paypal_email)
    end

    def paypal_bill_address
      paypal_payer_info.Address
    end

    def paypal_payer_info
      @checkout_details
        .GetExpressCheckoutDetailsResponseDetails
        .PayerInfo
    end

    def paypal_ship_address
      @checkout_details
        .GetExpressCheckoutDetailsResponseDetails
        .PaymentDetails[0]
        .ShipToAddress
    end

    def paypal_email
      @checkout_details.GetExpressCheckoutDetailsResponseDetails.PayerInfo.Payer
    end
  end
end
