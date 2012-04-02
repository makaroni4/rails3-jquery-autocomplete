require "cgi"
module Rails3JQueryAutocomplete
  module Orm
    module ActiveRecord
      def get_autocomplete_order(method, options, model=nil)
        order = options[:order]
          
        if options[:globalized]
          table_prefix = "#{model.name.downcase}_translations." 
        else
          table_prefix = model ? "#{model.table_name}." : ""
        end
        
        order || "#{table_prefix}#{method} ASC"
      end

      def get_autocomplete_items(parameters)
        model   = parameters[:model]
        term    = parameters[:term]
        method  = parameters[:method]
        options = parameters[:options]
        scopes  = Array(options[:scopes])
        limit   = get_autocomplete_limit(options)
        order   = get_autocomplete_order(method, options, model)
        
        items = model.scoped
        scopes.each { |scope| items = items.send(scope) } unless scopes.empty?

        items = items.select(get_autocomplete_select_clause(model, method, options)) unless options[:full_model]
        items = items.where(get_autocomplete_where_clause(model, term, method, options)).limit(limit).order(order)
      end

      def get_autocomplete_select_clause(model, method, options)
        table_name = model.table_name
        primary_key = model.primary_key
        translations_table = "#{model.name.underscore.pluralize}_translations"
        
        (["#{table_name}.#{primary_key}", "#{options[:globalized] ? translations_table : table_name}.#{method}"] + (options[:extra_data].blank? ? [] : options[:extra_data]))
      end

      def get_autocomplete_where_clause(model, term, method, options)
        table_name = model.table_name
        is_full_search = options[:full]
        like_clause = (postgres? ? 'ILIKE' : 'LIKE')
        search_field = options[:globalized] ? "#{model.name.underscore.pluralize}_translations.#{method}" : method
        ["LOWER(#{search_field}) #{like_clause} ?", "#{(is_full_search ? '%' : '')}#{term.downcase}%"]
      end

      def postgres?
        defined?(PGconn)
      end
    end
  end
end
