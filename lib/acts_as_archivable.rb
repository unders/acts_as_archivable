module Shooter #:nodoc:
  module Acts #:nodoc:
    # This is to be used on ActiveRecord models as such (also used in the tests):
    # 
    #   class Entry < ActiveRecord::Base
    #     acts_as_archivable :order => 'DESC'
    #     has_many  :comments, :dependent => :destroy
    #   end
    # 
    #   class Comment < ActiveRecord::Base
    #     acts_as_archivable :on => :replied_on
    #     belongs_to  :entry
    #   end
    # 
    # From here, you have quick access to records related to date.
    # 
    #   Entry.by_date :year => 2007
    #   Entry.by_date Date.today
    #   Entry.by_date '5/1/2007'
    # 
    #   Entry.oldest
    #   Entry.newest
    # 
    #   Entry.recent 2.weeks
    #   Entry.recent 3.months
    #   Entry.recent (3.months - 1.week)
    # 
    #   Entry.between '5/10/2007', Date.today
    
    module Archivable
      def self.included(base) #:nodoc:
        base.extend ClassMethods
      end

      module ClassMethods
        # == Configuration Options
        # 
        # * <tt>on</tt> - attribute on the model that will be referenced for all queries (default: created_at)
        # * <tt>order</tt> - default order that results will be returned (default: ASC)
        
        def acts_as_archivable(options = {})
          unless archivable?
            cattr_accessor :archivable_attribute, :sort_order
            self.archivable_attribute = options[:on] || :created_at
            self.sort_order = options[:order] || "ASC"
          end
          include InstanceMethods
        end

        def archivable?
          self.included_modules.include?(InstanceMethods)
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
          if base.respond_to?(:named_scope)
            base.class_eval do
              named_scope :by_date, lambda {|by_date| { :conditions => initial_conditions(by_date), :order => order }}
              named_scope :recent, lambda {|*length_of_time| length_of_time = length_of_time.blank? ? 1.year: length_of_time; recent_options(length_of_time) }
              named_scope :between, lambda {|start_date, end_date| { :conditions => between_conditions(start_date, end_date), :order => order }}
            end
          else
            base.extend WithScopeMethods
          end
        end
        
        
        module WithScopeMethods
          def by_date(by_date, options ={})
            with_scope(:find => {:conditions => initial_conditions(by_date), :order => order}) do
              block_given? ? yield(options) : find(:all, options)
            end
          end

          def recent(length_of_time = 1.year, options = {})
            with_scope(:find => recent_options(length_of_time)) do
              block_given? ? yield(options) : find(:all, options)
            end
          end

          def between(start_date, end_date, options = {})
            with_scope(:find => {:conditions => between_conditions(start_date, end_date), :order => order}) do
              block_given? ? yield(options) : find(:all, options)
            end
          end
        end
        
        module ClassMethods
          def oldest(options = {})
            find(:first, options.merge(:order => "#{table_name}.#{archivable_attribute} ASC"))
          end

          def newest(options = {})
            find(:first, options.merge(:order => "#{table_name}.#{archivable_attribute} DESC"))
          end
          
          def count_by_date(by_date, options = {})
            with_scope(:find => {:conditions => initial_conditions(by_date)}) do
              count(options)
            end
          end

          def count_recent(length_of_time = 1.year, options = {})
            with_scope(:find => recent_options(length_of_time)) do
              count(options)
            end
          end

          def count_between(start_date, end_date, options = {})
            with_scope(:find => {:conditions => between_conditions(start_date, end_date)}) do
              count(options)
            end
          end

          private

          def initial_conditions(by_date)
            by_date = simple_parse by_date

            year, month, day = (by_date[:year] rescue nil) || (by_date.year rescue nil), (by_date[:month] rescue nil) || (by_date.month rescue nil), (by_date[:day] rescue nil) || (by_date.day rescue nil)
            condition_str = [] << "year(#{table_name}.#{archivable_attribute}) = ?"
            condition_str << "AND month(#{table_name}.#{archivable_attribute}) = ?" if month
            condition_str << "AND day(#{table_name}.#{archivable_attribute}) = ?" if day
            [condition_str * " ", year, month, day].compact
          end

          def between_conditions(start_date, end_date)
            start_date, end_date = simple_parse(start_date), simple_parse(end_date)
            ["#{table_name}.#{archivable_attribute} BETWEEN ? AND ?", start_date, end_date]
          end
          
          def recent_options(length_of_time)
            {:conditions => ["#{table_name}.#{archivable_attribute} >= ?", Time.now.advance(:days => -length_of_time.to_days)], :order => "#{table_name}.#{archivable_attribute} DESC"}
          end
          
          def order
            "#{table_name}.#{archivable_attribute} #{sort_order}"
          end
          
          def simple_parse(date)
            type = date.class.to_s
            case type
            when 'String'
              Date.parse(date)
            when 'Time'
              date.to_date
            else
              date
            end
          end
        end
      end
    end
  end
end

class Numeric
  def to_days
    self.to_i/60/60/24
  end
end
