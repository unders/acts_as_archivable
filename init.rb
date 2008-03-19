require 'acts_as_archivable'
ActiveRecord::Base.send(:include, Shooter::Acts::Archivable)