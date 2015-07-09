class App < Sinatra::Base
  register Sinatra::CrossOrigin
  Stripe.api_key = ENV['STRIPE_SECRET_KEY']

  post '/charge' do
    content_type :json
    cross_origin
    begin
        @from = params[:from]
        @email = params[:email]
        @price = params[:price].to_i
        @item = params[:item]
        @stripe_token = params[:stripeToken]

        @charge = Stripe::Charge.create(
          amount: @price,
          currency: 'gbp',
          source: @stripe_token,
          description: "#{@from} brought #{@item} - £#{@price/100.round(2)}",
          metadata: {
            from: @from,
            email: @email,
            item: @item
          }
        )

        @charge.to_json

    rescue Stripe::CardError => e
      # Since it's a decline, Stripe::CardError will be caught
      body = e.json_body
      err  = body[:error]

      {http_status: e.http_status, error: err}.to_json
    rescue Stripe::InvalidRequestError => e
      # Invalid parameters were supplied to Stripe's API
      body = e.json_body
      err  = body[:error]
      {http_status: e.http_status, error: err}.to_json
    rescue Stripe::AuthenticationError => e
      # Authentication with Stripe's API failed
      # (maybe you changed API keys recently)
      body = e.json_body
      err  = body[:error]
      {http_status: e.http_status, error: err}.to_json
    rescue Stripe::APIConnectionError => e
      # Network communication with Stripe failed
      body = e.json_body
      err  = body[:error]
      {http_status: e.http_status, error: err}.to_json
    rescue Stripe::StripeError => e
      # Display a very generic error to the user, and maybe send
      # yourself an email
      body = e.json_body
      err  = body[:error]
      {http_status: e.http_status, error: err}.to_json
    rescue => e
      # Something else happened, completely unrelated to Stripe
      e.to_json
    end
  end
end