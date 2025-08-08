class ClientsController < ApplicationController
  # Manually require blueprints
  require_relative '../blueprints/client_blueprint'
  def index
    @clients = Current.user.clients.all
  end

  def show
    @client = Current.user.clients.find(params[:id])
  end

  def new
    @client = Current.user.clients.new
  end

  def edit
    @client = Current.user.clients.find(params[:id])
  end
end