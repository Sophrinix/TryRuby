require 'test/test_helper'

class FakeFSTest < Test::Unit::TestCase
  def setup
    FakeFS.activate!
    FakeFS::FileSystem.clear
  end

  def teardown
    FakeFS.deactivate!
  end

  def test_file_system_current_dir
    assert_equal({}, FakeFS::FileSystem.current_dir)
    Dir.mkdir "Home"
    assert_equal({"Home"=>{}}, FakeFS::FileSystem.current_dir)
    FakeFS::FileSystem.chdir "Home" do
      Dir.mkdir "Sub"
      assert_equal({"Sub" => {}}, FakeFS::FileSystem.current_dir)
    end
    assert_equal({"Home" => {"Sub" => {}}}, FakeFS::FileSystem.current_dir)
  end

  def test_dir_entries_for_current_dir
    assert_equal [".", ".."], Dir.entries(".")
  end

  def test_dir_entries_for_root
    assert_equal [".", ".."], Dir.entries("/")
  end

  def test_dir_entries2
    Dir.mkdir "Home"
    assert_equal [".", "..", "Home"], Dir.entries(".")
  end

  def test_dir_entries3
    ["Home", "Libraries", "MouseHole", "Programs", "Tutorials"].each {|dir| Dir.mkdir dir }
    assert_equal [".", "..", "Home", "Libraries", "MouseHole", "Programs", "Tutorials"], Dir.entries("/")
  end
  
  def test_fake_dir_to_s_for_root_dir
    assert_equal("/", FakeFS::FileSystem.current_dir.to_s)
  end

  def test_fake_dir_to_s_for_sub_dir
    Dir.mkdir "Home"
    FakeFS::FileSystem.chdir "Home" do
      assert_equal("/Home", FakeFS::FileSystem.current_dir.to_s)
    end
  end

  def test_fake_dir_to_s_for_sub_sub_dir
    Dir.mkdir "Home"
    FakeFS::FileSystem.chdir "Home" do
      Dir.mkdir "Sub"
      FakeFS::FileSystem.chdir "Sub" do
        assert_equal("/Home/Sub", FakeFS::FileSystem.current_dir.to_s)
      end
    end
  end

  def test_file_inspect
    assert_equal("#<File:/comics.txt>", File.open("/comics.txt", "a") { |f| f << "a"}.inspect)
  end

  def test_file_foreach
    File.open("/comics.txt", "a") { |f| f << "a"}
    lines = []
      File.foreach("/comics.txt") do |l| lines << l
    end
    assert_equal(["a"], lines)
  end

  def test_file_expand_path_for_current_dir
    assert_equal "/", File.expand_path(".")
    Dir.mkdir "Home"
    FakeFS::FileSystem.chdir "Home" do
      assert_equal "/Home", File.expand_path(".")
    end
  end

  def test_file_expand_path_for_root_dir
    assert_equal RealFile.expand_path("/"), File.expand_path("/")
  end

  def test_file_expand_path_for_user_dir
    assert_equal "/~", File.expand_path("~")
  end

  def test_file_expand_path_for_user_dir_with_sub_dir
    assert_equal "/~/test", File.expand_path("~/test")
  end
end