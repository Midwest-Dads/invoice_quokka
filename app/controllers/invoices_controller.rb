class InvoicesController < ApplicationController
  # Manually require blueprints
  require_relative '../blueprints/invoice_blueprint'
  require_relative '../blueprints/client_blueprint'
  require_relative '../blueprints/invoice_item_blueprint'
  def index
    @invoices = Current.user.invoices.includes(:client).all
  end

  def show
    @invoice = Current.user.invoices.includes(:client, :invoice_items).find(params[:id])
  end

  def new
    @invoice = Current.user.invoices.new
    @invoice.issue_date = Date.current
    @invoice.due_date = Date.current + 30.days
    @invoice.tax_rate = 0.0
    @invoice.status = :draft
    @clients = Current.user.clients.all
  end

  def edit
    @invoice = Current.user.invoices.includes(:client, :invoice_items).find(params[:id])
    @clients = Current.user.clients.all
  end
end