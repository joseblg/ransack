require 'mongoid'

Mongoid.load!(File.expand_path("../mongoid.yml", __FILE__), :test)

class Person
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :email, type: String
  field :only_search, type: String
  field :only_sort, type: String
  field :only_admin, type: String
  field :salary, type: Integer
  field :awesome, type: Boolean, default: false

  belongs_to :parent, :class_name => 'Person', inverse_of: :children
  has_many   :children, :class_name => 'Person', inverse_of: :parent

  has_many   :articles
  has_many   :comments

  # has_many   :authored_article_comments, :through => :articles,
             # :source => :comments, :foreign_key => :person_id

  has_many   :notes, :as => :notable

  default_scope -> { order(id: :desc) }

  scope :restricted,  lambda { where("restricted = 1") }
  scope :active,      lambda { where("active = 1") }
  scope :over_age,    lambda { |y| where(["age > ?", y]) }

  ransacker :reversed_name, :formatter => proc { |v| v.reverse } do |parent|
    parent.table[:name]
  end

  # ransacker :doubled_name do |parent|
  #   Arel::Nodes::InfixOperation.new(
  #     '||', parent.table[:name], parent.table[:name]
  #     )
  # end

  def self.ransackable_attributes(auth_object = nil)
    if auth_object == :admin
      column_names + _ransackers.keys - ['only_sort']
    else
      column_names + _ransackers.keys - ['only_sort', 'only_admin']
    end
  end

  def self.ransortable_attributes(auth_object = nil)
    if auth_object == :admin
      column_names + _ransackers.keys - ['only_search']
    else
      column_names + _ransackers.keys - ['only_search', 'only_admin']
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    if auth_object == :admin
      column_names + _ransackers.keys - ['only_sort']
    else
      column_names + _ransackers.keys - ['only_sort', 'only_admin']
    end
  end

  def self.ransortable_attributes(auth_object = nil)
    if auth_object == :admin
      column_names + _ransackers.keys - ['only_search']
    else
      column_names + _ransackers.keys - ['only_search', 'only_admin']
    end
  end
end

class Article
  include Mongoid::Document

  field :person_id, type: Integer
  field :title, type: String
  field :body, type: String

  belongs_to :person
  has_many :comments
  # has_and_belongs_to_many :tags
  has_many :notes, :as => :notable
end

module Namespace
  class Article < ::Article

  end
end

class Comment
  include Mongoid::Document

  field :article_id, type: Integer
  field :person_id, type: Integer
  field :body, type: String


  belongs_to :article
  belongs_to :person
end

class Tag
  include Mongoid::Document

  field :name, type: String

  # has_and_belongs_to_many :articles
end

class Note
  include Mongoid::Document

  field :notable_id, type: Integer
  field :notable_type, type: String
  field :note, type: String

  belongs_to :notable, :polymorphic => true
end

module Schema
  def self.create
    10.times do
      person = Person.create!
      Note.create!(:notable => person)
      3.times do
        article = Article.create!(:person => person)
        3.times do
          # article.tags = [Tag.create!, Tag.create!, Tag.create!]
        end
        Note.create!(:notable => article)
        10.times do
          Comment.create!(:article => article, :person => person)
        end
      end
    end

    Comment.create!(
      :body => 'First post!',
      :article => Article.create!(:title => 'Hello, world!')
      )
  end
end
