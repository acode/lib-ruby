require 'minitest/autorun'
require 'lib'

class LibTest < Minitest::Test

  def check_result(result)
    assert_instance_of Hash, result
    assert_includes result, 'kwargs'
    assert_includes result['kwargs'], 'key'
    assert_equal result['kwargs']['key'], 'Test'
  end

  def test_calls_default_function?
    check_result Lib.stdlib.reflect.exec! key: 'Test'
  end

  def test_calls_main_function?
    check_result Lib.stdlib.reflect.main.exec! key: 'Test'
  end

  def test_calls_dev_default_function?
    check_result Lib.stdlib.reflect['@dev'].exec! key: 'Test'
  end

  def test_calls_dev_main_function?
    check_result Lib.stdlib.reflect['@dev'].main.exec! key: 'Test'
  end

  def test_calls_string_default_function?
    check_result Lib['stdlib.reflect'].exec! key: 'Test'
  end

  def test_calls_string_main_function?
    check_result Lib['stdlib.reflect.main'].exec! key: 'Test'
  end

  def test_calls_string_dev_default_function?
    check_result Lib['stdlib.reflect[@dev]'].exec! key: 'Test'
  end

  def test_calls_string_dev_main_function?
    check_result Lib['stdlib.reflect[@dev].main'].exec! key: 'Test'
  end

  def test_block?
    Lib.stdlib.reflect.exec! key: 'Test' do |result|
      check_result result
    end
  end

  def test_errors_with_array?
    begin
      Lib.stdlib.reflect.exec! []
    rescue Exception => err
      assert_instance_of ArgumentError, err
    end
  end

  def test_errors_with_not_found?
    begin
      Lib.stdlib.x.exec!
    rescue Exception => err
      assert_instance_of StandardError, err
    end
  end

  def test_errors_with_local?
    begin
      Lib['.local'].exec!
    rescue Exception => err
      assert_instance_of StandardError, err
    end
  end
end
