class Api::V1::ClientsController < Api::V1::BaseController
  before_action :set_client, only: [:show, :update, :destroy]

  def index
    @clients = Current.user.clients.all
    render json: ClientBlueprint.render(@clients)
  end

  def show
    render json: ClientBlueprint.render(@client)
  end

  def create
    @client = Current.user.clients.new(client_params)

    if @client.save
      render json: ClientBlueprint.render(@client), status: :created
    else
      render json: { errors: @client.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @client.update(client_params)
      render json: ClientBlueprint.render(@client)
    else
      render json: { errors: @client.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    head :no_content
  end

  private

  def set_client
    @client = Current.user.clients.find(params[:id])
  end

  def client_params
    params.expect(client: [:name, :email, :address, :phone])
  end
end