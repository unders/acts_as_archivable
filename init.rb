require 'acts_as_archivable'

class Integer
  def to_days
    self/60/60/24
  end
end

ActiveRecord::Base.send(:include, Shooter::Acts::Archivable)

