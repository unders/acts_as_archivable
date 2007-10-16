require File.join(File.dirname(__FILE__), 'test_helper')

class Entry < ActiveRecord::Base
  acts_as_archivable :order => 'DESC'
  has_many  :comments, :dependent => :destroy
end

class Comment < ActiveRecord::Base
  acts_as_archivable :on => :replied_on
  belongs_to  :entry
end

class ActsAsArchivableTest < Test::Unit::TestCase
  fixtures :entries, :comments
  
  def test_should_count_2007
    assert_equal 6, Entry.count
    assert_equal 4, Comment.count
    assert_equal 3, Entry.count_by_date({:year => 2007})
    assert_equal 1, Comment.count_by_date({:year => 2007})
  end
  
  def test_should_count_with_associated_models
    assert_equal 4, entries(:entry_1).comments.count
    assert_equal 3, entries(:entry_1).comments.count_by_date({:year => 2006})
    assert_equal 2, entries(:entry_1).comments.count_by_date({:year => 2006, :month => 10})
  end

  def test_should_allow_hash_or_string_as_date
    assert_equal 1, Comment.count_by_date({:year => 2007, :month => 10, :day => 2})
    assert_equal 2, Entry.count_by_date('7/4/2007')    
  end
  
  def test_should_accept_string_or_date_for_date_range
    assert_equal 3, entries(:entry_1).comments.count_between(Date.parse('10/3/2006'), '12/1/2007')
    assert_equal 3, Entry.count_between('6/6/2006', Date.parse('6/6/2007'))
  end
  
  def test_should_return_correct_newest_and_oldest_items
    assert_equal 2, Entry.oldest.id
    assert_equal 4, entries(:entry_1).comments.newest.id
  end
end