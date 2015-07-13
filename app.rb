class App < Sinatra::Base
  register Sinatra::CrossOrigin
  Stripe.api_key = ENV['STRIPE_SECRET_KEY']

  before do
   content_type :json
  end

  post '/charge' do
    cross_origin

    begin
        @id = params[:id]
        @from = params[:from]
        @email = params[:email]
        @message = params[:message]
        @price = params[:price].to_i
        @item = params[:item]
        @stripe_token = params[:stripeToken]

        @charge = Stripe::Charge.create(
          amount: @price,
          currency: 'gbp',
          source: @stripe_token,
          description: "#{@from} paid for #{@item}",
          receipt_email: @email,
          metadata: {
            From: @from,
            Email: @email,
            Message: @message,
            Item: @item
          }
        )

        if @charge
          @gifts = Redis::HashKey.new('gifts')
          @gifts.incr(@id)
        end

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

  get '/gifts' do
    cross_origin

    @gifts = Redis::HashKey.new('gifts')

    # if @gifts.empty?
    #   9.times do |i|
    #     @gifts[i+1] = 0
    #   end
    # end
    @gifts.all.to_json
  end
end