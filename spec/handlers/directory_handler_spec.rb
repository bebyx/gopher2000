require File.join(File.dirname(__FILE__), '..', '/spec_helper')

describe Gopher::Handlers::DirectoryHandler do
  before(:each) do
    app = mock(Gopher::Application,
      :host => "host",
      :port => 1234,
      :config => {})

    @h = Gopher::Handlers::DirectoryHandler.new(:path => "/tmp", :mount_point => "/xyz/123")
    @h.application = app
  end

  describe "filtering" do
    before(:each) do
      File.should_receive(:directory?).with("/tmp/bar/baz").and_return(true)
      File.should_receive(:directory?).with("/tmp/bar/baz/a.txt").and_return(false)
      File.should_receive(:directory?).with("/tmp/bar/baz/b.exe").and_return(false)
      File.should_receive(:directory?).with("/tmp/bar/baz/dir2").and_return(true)

      File.should_receive(:file?).with("/tmp/bar/baz/a.txt").and_return(true)
      File.should_receive(:file?).with("/tmp/bar/baz/b.exe").and_return(true)

      File.should_receive(:fnmatch).with("*.txt", "/tmp/bar/baz/a.txt").and_return(true)
      File.should_receive(:fnmatch).with("*.txt", "/tmp/bar/baz/b.exe").and_return(false)

      Dir.should_receive(:glob).with("/tmp/bar/baz/*").and_return([
          "/tmp/bar/baz/a.txt",
          "/tmp/bar/baz/b.exe",
          "/tmp/bar/baz/dir2"])

      @h.filter = "*.txt"
    end

    it "should use right filter" do
      @h.call(:splat => "bar/baz")
    end
  end

  describe "request_path" do
    it "should join existing path with incoming path" do
      @h.request_path(:splat => "bar/baz").should == "/tmp/bar/baz"
    end
  end

  describe "to_selector" do
    it "should work" do
      @h.to_selector("/tmp/foo/bar.html").should == "/xyz/123/foo/bar.html"
      @h.to_selector("/tmp/foo/baz").should == "/xyz/123/foo/baz"
      @h.to_selector("/tmp").should == "/xyz/123"
    end
  end

  describe "contained?" do
    it "should be false if not under base path" do
      @h.contained?("/home/gopher").should == false
    end
    it "should be true if under base path" do
      @h.contained?("/tmp/gopher").should == true
    end
  end

  describe "safety checks" do
    it "should raise exception for invalid directory" do
      lambda {
        @h.call(:splat => "../../../home/foo/bar/baz").to_s.should == "0a\t/tmp/bar/baz/a\thost\t1234"
     }.should raise_error(Gopher::InvalidRequest)
    end
  end

  describe "directories" do
    before(:each) do
      File.should_receive(:directory?).with("/tmp/bar/baz").and_return(true)
      File.should_receive(:directory?).with("/tmp/bar/baz/a").and_return(false)
      File.should_receive(:directory?).with("/tmp/bar/baz/dir2").and_return(true)

      File.should_receive(:file?).with("/tmp/bar/baz/a").and_return(true)
      File.should_receive(:fnmatch).with("*.*", "/tmp/bar/baz/a").and_return(true)

      Dir.should_receive(:glob).with("/tmp/bar/baz/*").and_return([
          "/tmp/bar/baz/a",
          "/tmp/bar/baz/dir2"])
    end

    it "should work" do
      @h.call(:splat => "bar/baz").to_s.should == "iBrowsing: /tmp/bar/baz\tnull\t(FALSE)\t0\r\n9a\t/xyz/123/bar/baz/a\thost\t1234\r\n1dir2\t/xyz/123/bar/baz/dir2\thost\t1234\r\n"
    end
  end

  describe "files" do
    before(:each) do
      @file = mock(File)
      File.should_receive(:directory?).with("/tmp/baz.txt").and_return(false)

      File.should_receive(:file?).with("/tmp/baz.txt").and_return(true)
      File.should_receive(:new).with("/tmp/baz.txt").and_return(@file)
    end

    it "should work" do
      @h.call(:splat => "baz.txt").should == @file
    end
  end

  describe "missing stuff" do
    before(:each) do
      File.should_receive(:directory?).with("/tmp/baz.txt").and_return(false)
      File.should_receive(:file?).with("/tmp/baz.txt").and_return(false)
    end

    it "should return not found" do
      lambda {
        @h.call(:splat => "baz.txt")
      }.should raise_error(Gopher::NotFoundError)
    end
  end
end
