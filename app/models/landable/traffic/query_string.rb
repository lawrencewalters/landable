module Landable
  module Traffic
    class QueryString < ActiveRecord::Base
      include Landable::TableName

      lookup_by :query_string, cache: 50, find_or_create: true, allow_blank: true

      has_many :page_views
      has_many :referers
    end
  end
end
