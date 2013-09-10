class Assessable::Assessment < ActiveRecord::Base
  belongs_to :user

  belongs_to :assessable, :polymorphic => true

  #These would have to be revised if more than just Points could be assessed
  belongs_to :point, :foreign_key => 'assessable_id'
  has_one :proposal, :through => :point
  ###
  
  has_many :claims, :class_name => 'Assessable::Claim'
  has_many :requests, :class_name => 'Assessable::Request'
  
  acts_as_tenant :account

  scope :public_fields, select([:id, :overall_verdict, :created_at, :updated_at, :assessable_id, :assessable_type])

  #TODO: sanitize before_validation
  #self.text = Sanitize.clean(self.text, Sanitize::Config::RELAXED)

  def self.build_from(obj, user_id, status)
    c = self.new
    c.assessable_id = obj.id 
    c.assessable_type = obj.class.name 
    c.user_id = user_id
    c
  end

  def root_object
    assessable_type.constantize.find(assessable_id)
  end

  def update_overall_verdict
    if self.claims.count == 0
      self.overall_verdict = -1
    else
      self.overall_verdict = self.claims.map{|x| x.verdict}.compact.min
    end

  end

  def public_fields
    {
      :id => self.id,
      :overall_verdict => self.overall_verdict,
      :created_at => self.created_at,
      :updated_at => self.updated_at,
      :assessable_type => self.assessable_type,
      :assessable_id => self.assessable_id
    }
  end

end