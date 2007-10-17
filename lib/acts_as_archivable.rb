module Shooter
  module Acts
    module Archivable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
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
        end

        module ClassMethods
          def by_date(by_date, options ={})
            with_scope(:find => {:conditions => initial_conditions(by_date), :order => order}) do
              find :all, options
            end
          end

          def count_by_date(by_date, options = {})
            with_scope(:find => {:conditions => initial_conditions(by_date)}) do
              count(options)
            end
          end

          def oldest(options = {})
            find(:first, options.merge(:order => "#{table_name}.#{archivable_attribute} ASC"))
          end

          def newest(options = {})
            find(:first, options.merge(:order => "#{table_name}.#{archivable_attribute} DESC"))
          end

          def recent(days = 365, options = {})
            with_scope(:find => {:conditions => ["#{table_name}.#{archivable_attribute} >= ?", Time.now.advance(:days => -days)], :order => order}) do
              find :all, options
            end
          end

          def count_recent(days = 365, options = {})
            with_scope(:find => {:conditions => ["#{table_name}.#{archivable_attribute} >= ?", Time.now.advance(:days => -days)]}) do
              count(options)
            end
          end

          def between(start_date, end_date, options = {})
            with_scope(:find => {:conditions => between_conditions(start_date, end_date), :order => order}) do
              find :all, options
            end            
          end

          def count_between(start_date, end_date, options = {})
            with_scope(:find => {:conditions => between_conditions(start_date, end_date)}) do
              count(options)
            end
          end

          private

          def initial_conditions(by_date)
            by_date = Date.parse(by_date) if by_date.is_a?(String)

            year, month, day = (by_date[:year] rescue nil) || (by_date.year rescue nil), (by_date[:month] rescue nil) || (by_date.month rescue nil), (by_date[:day] rescue nil) || (by_date.day rescue nil)
            condition_str = [] << "year(#{table_name}.#{archivable_attribute}) = ?"
            condition_str << "AND month(#{table_name}.#{archivable_attribute}) = ?" if month
            condition_str << "AND day(#{table_name}.#{archivable_attribute}) = ?" if day
            [condition_str * " ", year, month, day].compact
          end

          def between_conditions(start_date, end_date)
            start_date = Date.parse(start_date) if start_date.is_a?(String)
            end_date = Date.parse(end_date) if end_date.is_a?(String)
            ["#{table_name}.#{archivable_attribute} BETWEEN ? AND ?", start_date, end_date]
          end

          def order
            "#{table_name}.#{archivable_attribute} #{sort_order}"
          end
        end
      end
    end
  end
end