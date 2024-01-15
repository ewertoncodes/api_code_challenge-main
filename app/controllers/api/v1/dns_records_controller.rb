module Api
  module V1
    class DnsRecordsController < ApplicationController
      include Pagy::Backend

      def index
        page = params[:page].to_i
    
        if page <= 0
          render json: { error: 'Invalid page parameter' }, status: :unprocessable_entity
          return
        end
    
        pagy, records = pagy(DnsRecord.includes(:hostnames))
    
        if records.empty?
          render json: { total_records: pagy.count, records: [], related_hostnames: [] }
          return
        end
    
        formatted_records = records.map do |record|
          {
            id: record.id,
            ip_address: record.ip
          }
        end
    
        related_hostnames = Hostname.joins(:dns_record_hostnames)
                                     .group(:name)
                                     .order(count: :desc)
                                     .limit(5)
                                     .count
    
        formatted_related_hostnames = related_hostnames.map do |hostname, count|
          { hostname: hostname, count: count }
        end
    
        render json: {
          total_records: pagy.count,
          records: formatted_records,
          related_hostnames: formatted_related_hostnames
        }
      end
          
      # POST /dns_records
      def create
        dns_record = DnsRecord.new(dns_record_params)
        
        if dns_record.save!
          render json: dns_record.id, status: :created
        else
          render json: dns_record.errors, status: :unprocessable_entity
        end
      end

      private
  
      def dns_record_params
        params.require(:dns_records).permit(:ip, hostnames_attributes: [:name, :ip_address])
      end
    end
  end
end
