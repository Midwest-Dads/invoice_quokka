class Api::V1::InvoiceItemsController < Api::V1::BaseController
  before_action :set_invoice
  before_action :set_invoice_item, only: [:show, :update, :destroy]

  def index
    @invoice_items = @invoice.invoice_items.all
    render json: InvoiceItemBlueprint.render(@invoice_items)
  end

  def show
    render json: InvoiceItemBlueprint.render(@invoice_item)
  end

  def create
    @invoice_item = @invoice.invoice_items.new(invoice_item_params)

    if @invoice_item.save
      render json: InvoiceItemBlueprint.render(@invoice_item), status: :created
    else
      render json: { errors: @invoice_item.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @invoice_item.update(invoice_item_params)
      render json: InvoiceItemBlueprint.render(@invoice_item)
    else
      render json: { errors: @invoice_item.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @invoice_item.destroy
    head :no_content
  end

  private

  def set_invoice
    @invoice = Current.user.invoices.find(params[:invoice_id])
  end

  def set_invoice_item
    @invoice_item = @invoice.invoice_items.find(params[:id])
  end

  def invoice_item_params
    params.expect(invoice_item: [:description, :quantity, :unit_price])
  end
end