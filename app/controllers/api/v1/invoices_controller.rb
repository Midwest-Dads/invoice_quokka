class Api::V1::InvoicesController < Api::V1::BaseController
  before_action :set_invoice, only: [:show, :update, :destroy]

  def index
    @invoices = Current.user.invoices.includes(:client, :invoice_items).all
    render json: InvoiceBlueprint.render(@invoices)
  end

  def show
    render json: InvoiceBlueprint.render(@invoice)
  end

  def create
    @invoice = Current.user.invoices.new(invoice_params)

    if @invoice.save
      render json: InvoiceBlueprint.render(@invoice), status: :created
    else
      render json: { errors: @invoice.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @invoice.update(invoice_params)
      render json: InvoiceBlueprint.render(@invoice)
    else
      render json: { errors: @invoice.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @invoice.destroy
    head :no_content
  end

  private

  def set_invoice
    @invoice = Current.user.invoices.includes(:client, :invoice_items).find(params[:id])
  end

  def invoice_params
    params.expect(invoice: [:client_id, :invoice_number, :issue_date, :due_date, :status, :tax_rate, :notes])
  end
end