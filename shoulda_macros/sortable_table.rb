module SortableTable
  module Shoulda

    def should_sort_by(attribute, options = {}, &block)
      collection       = get_collection_name_from_test_name
      model_under_test = get_model_under_test_from_test_name

      unless block
        block = handle_boolean_attribute(model_under_test, attribute)
        block ||= attribute
      end

      action = options[:action] || lambda do |sort, direction|
        get :index, :sort => sort, :order => direction
      end

      %w(ascending descending).each do |direction|
        should "sort by #{attribute.to_s} #{direction}" do
          assert_not_nil model_under_test.find(:all).any?,
            "#{model_under_test}.find(:all) is nil"

          action.bind(self).call(attribute.to_s, direction)

          assert_not_nil assigns(collection), 
            "assigns(:#{collection}) is nil"
          assert assigns(collection).size >= 2, 
            "cannot test sorting without at least 2 sortable objects"

          expected = assigns(collection).sort_by(&block)
          expected = expected.reverse if direction == 'descending'

          assert expected.map(&block) == assigns(collection).map(&block), 
            "expected - #{expected.map(&block).inspect}," <<
            " but was - #{assigns(collection).map(&block).inspect}"
        end
      end
    end

    def should_sort_by_attributes(*attributes, &block)
      attributes.each do |attr|
        should_sort_by attr, :action => block
      end
    end

    def should_display_sortable_table_header_for(*valid_sorts)
      valid_sorts.each do |attr|
        should "have a link to sort by #{attr}" do
          assert_select 'a[href*=?]', "sort=#{attr}", true,  
            "link not found to sort by #{attr}. Try adding this to the view: " <<
            "<%= sortable_table_header :name => '#{attr}', :sort => '#{attr}' %>"
        end
      end

      should "not link to any invalid sorting options" do
        assert_select 'a[href*=?]', 'sort=' do |elements|
          sortings = elements.collect {|element|
            element.attributes['href'].match(/sort=([^&]*)/)[1]
          }
          sortings.each {|sorting|
            assert !valid_sorts.include?(sorting), 
              "link found for sortion option which is not in valid list: #{sorting}."
          }
        end
      end
    end
    
    protected
    
    def get_collection_name_from_test_name
      collection = self.name.underscore.gsub(/_controller_test/, '')
      collection = remove_namespacing(collection)
      collection.to_sym
    end
    
    def get_model_under_test_from_test_name
      self.name.gsub(/ControllerTest/, '').singularize.constantize
    end
    
    def remove_namespacing(string)
      string.slice!(0..string.rindex('/')) if string.include?('/')
      string
    end
    
    def attribute_is_boolean?(model_under_test, attribute)
      model_under_test.columns.select { |each| each.name == attribute.to_s }.first.type == :boolean
    end
    
    def handle_boolean_attribute(model_under_test, attribute)
      if attribute_is_boolean?(model_under_test, attribute)
        lambda { |model_instance| model_instance.send(attribute).to_s } 
      end
    end

  end
end
 
Test::Unit::TestCase.extend(SortableTable::Shoulda)

