// Generated by CoffeeScript 1.6.3
(function() {
  'use strict';
  var TicketsController, ticketsapp,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  ticketsapp = angular.module("ticketsapp", ["ngRoute", "ngCookies"]);

  ticketsapp.constant('currencies', {
    '': '',
    'EUR': '€'
  });

  ticketsapp.filter('amount', function(currencies) {
    return function(input) {
      var amount, cur_code, cur_symbol;
      amount = parseFloat(input != null ? input.amount : void 0).toFixed(2);
      if (isNaN(amount)) {
        amount = "0.00";
      }
      cur_symbol = (input != null ? input.amount : void 0) > 0 ? currencies[input != null ? input.currency : void 0] : '';
      cur_code = (input != null ? input.amount : void 0) > 0 ? input != null ? input.currency : void 0 : '';
      if (input != null) {
        return cur_symbol + amount + ' ' + cur_code;
      }
    };
  });

  TicketsController = (function() {
    TicketsController.$inject = ["$scope", "$http", "$window", "$routeParams", "$cookies", "currencies"];

    function TicketsController(scope, http, window, routeParams, cookies, currencies) {
      var _this = this;
      this.scope = scope;
      this.http = http;
      this.window = window;
      this.routeParams = routeParams;
      this.cookies = cookies;
      this.currencies = currencies;
      this.pay = __bind(this.pay, this);
      this.confirm = __bind(this.confirm, this);
      this.toConfirm = __bind(this.toConfirm, this);
      this.completeProfile = __bind(this.completeProfile, this);
      this.thereIsPayment = __bind(this.thereIsPayment, this);
      this.thereIsTotal = __bind(this.thereIsTotal, this);
      this.isPaid = __bind(this.isPaid, this);
      this.scope.data = {};
      this.scope.data.confirming = false;
      this.scope.data.toPay = false;
      this.scope.data.paid = false;
      this.scope.data.currencies = this.currencies;
      this.scope.data.range = [1, 2, 3, 4, 5, 6, 7, 8];
      this.scope.data["static"] = {
        "product": {
          "name": "Regular PyGrunn",
          "price": {
            "amount": "25.00",
            "currency": "EUR"
          }
        },
        "paymentMethods": ["iDeal", "Mastercard", "Visa", "AmericanExpress", "VisaDebit"],
        "countries": ['NL', 'US']
      };
      this.scope.data.dynamic = {
        "quantity": 0,
        "profile": {
          "first_name": "Spyros",
          "last_name": "Ioakeimidis",
          "email": "spyrosikmd@gmail.com",
          "gender": "male",
          "country_code": "NL",
          "date_of_birth": "1986-12-04"
        },
        "paymentMethod": "Mastercard"
      };
      this.scope.data.total = {
        "amount": "0.00",
        "currency": "EUR"
      };
      this.scope.data.totalCosts = {
        "amount": "0.00",
        "currency": "EUR"
      };
      this.scope.$watch("data.dynamic.quantity", function(newValue, oldValue) {
        var total;
        if (newValue !== oldValue) {
          total = 0;
          total += parseFloat(_this.scope.data["static"].product.price.amount) * newValue;
          return _this.scope.data.total.amount = total.toFixed(2);
        }
      });
      this.isPaid();
      angular.extend(this.scope, {
        toConfirm: this.toConfirm,
        confirm: this.confirm,
        pay: this.pay
      });
    }

    TicketsController.prototype.isPaid = function() {
      return this.scope.data.paid = this.routeParams["paid"] === "success" && this.cookies.paymentUrl;
    };

    TicketsController.checkPaymentUrl = function() {
      return true;
    };

    TicketsController.prototype.thereIsTotal = function() {
      return parseFloat(this.scope.data.total.amount) > 0;
    };

    TicketsController.prototype.thereIsPayment = function() {
      return this.scope.data.dynamic.paymentMethod !== "";
    };

    TicketsController.prototype.completeProfile = function() {
      var key, value, _ref;
      _ref = this.scope.data.dynamic.profile;
      for (key in _ref) {
        value = _ref[key];
        if (value === "") {
          return false;
        }
      }
      return true;
    };

    TicketsController.prototype.toConfirm = function() {
      return this.thereIsTotal() && this.completeProfile() && this.thereIsPayment();
    };

    TicketsController.prototype.confirm = function() {
      var _this = this;
      this.scope.data.confirming = true;
      return this.http({
        url: "http://10.0.30.198:5000/confirm",
        dataType: "json",
        method: "POST",
        data: this.scope.data.dynamic,
        headers: {
          "Content-Type": "application/json"
        }
      }).success(function(data, status, headers, config) {
        _this.scope.data.totalCosts = data.payment.amount;
        _this.scope.data["static"].paymentUrl = data.payment.payscreen_url;
        _this.cookies.paymentUrl = data.payment.payscreen_url;
        _this.scope.data.confirming = false;
        return _this.scope.data.toPay = true;
      }).error(function(data, status, headers, config) {
        console.log("error");
        return _this.scope.data.confirming = false;
      });
    };

    TicketsController.prototype.pay = function() {
      return this.window.location.href = this.scope.data["static"].paymentUrl;
    };

    return TicketsController;

  }).call(this);

  ticketsapp.controller("TicketsController", TicketsController);

  ticketsapp.config(function($routeProvider) {
    return $routeProvider.when("/", {
      templateUrl: "tickets.html",
      controller: "TicketsController"
    });
  });

}).call(this);
