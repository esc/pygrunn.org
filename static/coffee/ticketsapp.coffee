'use strict'

ticketsapp = angular.module("ticketsapp", ["ngRoute", "ngCookies"])

ticketsapp.service("spinner", ->
  ###
  Service that encapsulates the functionality of the Spinner plugin.
  ###
  options = {
    lines:11,
    length:2,
    width:2,
    radius:4,
    corner:1,
    rotate:0,
    trail:50,
    speed:1.3,
    top:'15px',
    left:'111px',
    color:'#312A1E'
  }
  @$spinner = new Spinner(options)
  {
    spin: =>
      @$spinner.spin(document.querySelector('.spinner-container'))

    stop: =>
      @$spinner.stop()
  })

ticketsapp.filter("amount", (currencies) ->
  ###
  Format the input price according to the following format €0.00 EUR
  If there is no amount, then return 0.00

  @param input [Object] The object in format {amount: "0.00", currency: "€"}

  @return [String] The formatted string.
  ###
  (input) ->
    amount = parseFloat(input?.amount).toFixed(2)
    if isNaN(amount)
      amount = "0.00"
    cur_symbol = if input?.amount > 0 then currencies[input?.currency] else ""
    cur_code = if input?.amount > 0 then input?.currency else ""
    cur_symbol + amount + " " + cur_code if input?
  )

class TicketsController

  @$inject = ["$scope", "$http", "$window", "$routeParams", "$cookies",
    "$location", "currencies", "settings", "spinner"]

  constructor: (@scope, @http, @window, @routeParams, @cookies, @location,
      @currencies, @settings, @spinner) ->
    @scope.data = {}
    @scope.data.confirming = false
    @scope.data.toPay = false
    # Flag to check if payment is successful.
    @scope.data.paid = false
    @scope.data.currencies = @currencies
    # The maximum quantity of products.
    @scope.data.maxQuantity = [1..8]
    # Get the static settings.
    @scope.data.settings = @settings
    # The data to be sent.
    @scope.data.dynamic = {
      "quantity": 0,
      "profile": {
        "first_name": "",
        "last_name": "",
        "email": "",
        "gender": "",
        "country_code": "NL",
        "date_of_birth": "",
        "address": "",
        "zipcode": "",
        "city": ""
      }
      "paymentMethod": "",
    }
    @scope.data.total = {
      "amount": "0.00",
      "currency": "EUR"
    }
    @scope.data.totalIncludingCosts = {
      "amount": "0.00",
      "currency": "EUR"
    }
    # When the quantity changes, re-calculate the total.
    @scope.$watch "data.dynamic.quantity", (newValue, oldValue) =>
      if newValue isnt oldValue
        total = 0
        total += parseFloat(@scope.data.settings.product.price.amount) * newValue
        @scope.data.total.amount = total.toFixed(2)
    # When pages load, check if payment is successful to show success message.
    @isPaid()
    # Call the API to get hte countries. The response is cached.
    @getCountries()
    # Extend the scope to include methods to be used in template.
    angular.extend @scope,
      toConfirm: @toConfirm
      confirm: @confirm
      pay: @pay
      cancel: @cancel
      orderMore: @orderMore

  cancel: =>
    ###
    Make the static fields dynamic and show the confirm button.
    ###
    @scope.data.toPay = false

  isPaid: =>
    ###
    Determine if the user has paid and the payment was successful.

    @return [Boolean] True if there is a successful payment, false otherwise.
    ###
    if @routeParams["paid"] is "success" and @cookies.paymentUrl and data.isPaid is false
      data.isPaid = True

  thereIsTotal: =>
    ###
    Determine if there is total.

    @return [Boolean] True if there is total, false otherwise.
    ###
    parseFloat(@scope.data.total.amount) > 0

  thereIsPayment: =>
    ###
    Determine if a payment method has been selected.

    @return [Boolean] True if there is a payment method selected, false otherwise.
    ###
    @scope.data.dynamic.paymentMethod isnt ""

  completeProfile: =>
    ###
    Check if the profile is complete so user can confirm.

    @return [Boolean] true if complete, false otherwise.
    ###
    for key, value of @scope.data.dynamic.profile
      if value is ""
        return false
    return true

  toConfirm: =>
    ###
    Confirm only when there is total, the profile is completed and there
    is a payment method selected.

    @return [Boolean] true to confirm, false otherwise.
    ###
    @thereIsTotal() and @completeProfile() and @thereIsPayment()

  confirm: =>
    ###
    Confirm the data with the server to receive the payment url.
    ###
    @scope.data.confirming = true
    @spinner.spin()
    @http({
      url: "",
      dataType: "json",
      method: "POST",
      data: @scope.data.dynamic,
      headers: {
        "Content-Type": "application/json"
      }
    })
    .success (data, status, headers, config) =>
      @scope.data.totalCosts = data.payment.amount
      @scope.data.settings.paymentUrl = data.payment.payscreen_url
      @cookies.paymentUrl = data.payment.payscreen_url
      @scope.data.confirming = false
      # Make the dynamic fields static and show the pay button.
      @scope.data.toPay = true
      @spinner.stop()
    .error (data, status, headers, config) =>
      @scope.data.confirming = false
      @spinner.stop()

  getCountries: =>
    ###
    Get a list of countries from API. Cache the response.
    ###
    @http({
      url: "http://restcountries.eu/rest/v1/all",
      dataType: "json",
      method: "GET",
      headers: {
        "Content-Type": "application/json"
      },
      cache: true
    })
    .success (data, status, headers, config) =>
      @scope.data.countries = data

  pay: =>
    ###
    Redirect to the payment url.
    ###
    @window.location.href = @scope.data.settings.paymentUrl

  orderMore: =>
    ###
    Show again the tickets module to user.
    ###
    @scope.data.paid = false
    delete @cookies.paymentUrl
    @location.url @location.path()

ticketsapp.controller("TicketsController", TicketsController)

ticketsapp.config ($routeProvider) ->
  $routeProvider
    .when("/", {
      templateUrl: "tickets.html",
      controller: "TicketsController"
    })
    .otherwise({
      redirectTo: "/"
    })