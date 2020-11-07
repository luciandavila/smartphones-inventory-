# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'InventoryUpdates', type: :request do
  describe 'GET /inventory_updates' do
    subject { get '/inventory_updates' }
    it 'returns http success' do
      subject
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /inventory_updates' do
    include Rack::Test::Methods
    include ActionDispatch::TestProcess

    let!(:another_inventory_update) { create :inventory_update }
    let(:params) { { csv_file: Rack::Test::UploadedFile.new('spec/files/input_valid.csv', 'text/csv') } }

    subject { post '/inventory_updates', params }

    it 'redirects to index action' do
      subject

      expect(last_response.status).to eq(302)
      expect(last_response.location).to match '/inventory_updates'
    end

    it 'creates an inventory update' do
      expect { subject }.to change(InventoryUpdate, :count).by(1)

      expect(InventoryUpdate.last.status).to eq 'processing'
      expect(InventoryUpdate.last.csv_file.attached?).to be_truthy
    end

    it 'enqueues job to proccess inventory update' do
      expect(InventoryUpdatesProcessorJob).to receive(:perform_later) do |inventory_update|
        expect(inventory_update.id).to eq(another_inventory_update.id + 1)
      end

      subject
    end
  end
end