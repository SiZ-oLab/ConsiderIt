# coding: utf-8
class Point < ApplicationRecord
  
  include Moderatable, Notifier
    
  belongs_to :user
  belongs_to :proposal
  has_many :inclusions, :dependent => :destroy
  has_many :comments, :dependent=>:destroy  
  
  validates :nutshell, :presence => true, :length => { :maximum => 181 }


  before_validation do 
    #self.nutshell = sanitize_helper self.nutshell
    #self.text = sanitize_helper self.text


    if self.nutshell.length > 180 
      self.text = self.text ? "#{self.nutshell[179..-1]} #{self.text}" : self.nutshell[179..-1]
      self.nutshell = self.nutshell[0..179]
    end

    if self.nutshell.length == 0 && !self.text.nil? && self.text.length > 0
      self.text =  self.text[179..self.text.length]
      self.nutshell = self.text[0..179]
    end

  end

  acts_as_tenant :subdomain

  class_attribute :my_public_fields
  self.my_public_fields = [:comment_count, :created_at, :updated_at, :id, :includers, :is_pro, :nutshell, :proposal_id, :published, :score, :text, :user_id, :hide_name, :last_inclusion, :subdomain_id]

  scope :public_fields, -> {select(self.my_public_fields)}

  scope :named, -> {where( :hide_name => false )}
  scope :published, -> {where( :published => true )}
  
  scope :pros, -> {where( :is_pro => true )}
  scope :cons, -> {where( :is_pro => false )}
  

  def as_json(options={})
    options[:only] ||= Point.my_public_fields
    result = super(options)

    # If anonymous, hide user id
    if (result['hide_name'] && (current_user.nil? || current_user.id != result['user_id']))
      result['user_id'] = -1
    end

    result['includers'] = result['includers'] || []
    result['includers'].map! {|u| hide_name && u == user_id ? -1 : u}
    result['includers'].map! {|u| "/user/#{u}"}
        
    make_key(result, 'point')
    stubify_field(result, 'proposal')
    stubify_field(result, 'user')

    result
  end

  def publish
    return if self.published
    self.published = true
    recache
    self.save if changed?

    Notifier.create_notification 'new', self
    notify_moderator

  end

  def category
    is_pro ? 'pro' : 'con'
  end

  def recache
    self.comment_count = comments.count

    # if we just look at self.inclusions, authors of unpublished opinions that
    # included this point will be set as includers
    opinions = Opinion.published \
            .where(:proposal_id => self.proposal_id) \
            .where("user_id IN (?)", self.inclusions.map {|i| i.user_id} ) \
            .select(:stance, :user_id)

    updated_includers = opinions.map {|x| x.user_id}

    ###
    # define cross-spectrum appeal
    if updated_includers.length == 0 # special cases
      self.appeal = 0.001
    elsif updated_includers.length == 1
      self.appeal = 0.001
    else
      # Compute the variance of the distribution of stances of users
      # including this point. 
      includer_stances = opinions.map {|o| o.stance} 

      n = includer_stances.length
      mean = includer_stances.inject(:+) / n

      variance = 1.0 / n * (includer_stances.map {|v| (v - mean) ** 2 }).inject(:+)
      standard_deviation = Math.sqrt(variance)

      self.appeal = standard_deviation
      self.score = updated_includers.length + standard_deviation * updated_includers.length
    end

    self.includers = updated_includers
    self.last_inclusion = updated_includers.length > 0 ? self.inclusions.where("user_id IN (?)", updated_includers).order(:created_at).last.created_at.to_i : -1

    if changed?
      save(:validate => false) 
      dirty_key "/point/#{self.id}"
    end
  end
        
  def self.update_scores
    Point.published.each {|pnt| pnt.recache }
  end

  def title(max_len = 180)

    if nutshell.length > max_len
      "#{nutshell[0..max_len]}..."
    else
      nutshell
    end
    
  end

end
