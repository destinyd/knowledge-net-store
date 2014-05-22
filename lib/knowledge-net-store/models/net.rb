require 'json'

module KnowledgeNetStore
  class Net
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name, :type => String
    field :desc, :type => String

    validates :name, :presence => true, :uniqueness => true

    has_many :points, :class_name => 'KnowledgeNetStore::Point'

    def to_json
      points_hash = []
      edges_hash  = []

      self.points.each do |point|
        point_hash = {:id => point.id.to_s, :name => point.name, :desc => point.desc}
        points_hash << point_hash
        point.parents.each do |parent|
          edge_hash = {:parent => parent.id.to_s, :child => point.id.to_s}
          edges_hash << edge_hash
        end
      end

      {
        "points" => points_hash,
        "edges"  => edges_hash
      }.to_json
    end

    def self.from_json(name, desc, json)
      net = self.create!(:name => name, :desc => desc)
      hash = JSON.parse(json)
      id_point_hash = {}
      hash["points"].each do |point_hash|
        point = net.points.create!(:name => point_hash["name"], :desc => point_hash["desc"])
        id_point_hash[point_hash["id"]] = point
      end
      hash["edges"].each do |edge_hash|
        parent = id_point_hash[edge_hash["parent"]]
        child  = id_point_hash[edge_hash["child"]]
        child.parents << parent
      end
      net
    end
  end
end