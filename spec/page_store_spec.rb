require File.dirname(__FILE__) + '/spec_helper'
%w[pstore tokyo_cabinet].each { |file| require "anemone/storage/#{file}.rb" }

module Anemone
  describe PageStore do

    before(:all) do
      FakeWeb.clean_registry
    end

    shared_examples_for "page storage" do
      it "should be able to computer single-source shortest paths in-place" do
        pages = []
        pages << FakePage.new('0', :links => ['1', '3'])
        pages << FakePage.new('1', :redirect => '2')
        pages << FakePage.new('2', :links => ['4'])
        pages << FakePage.new('3')
        pages << FakePage.new('4')

        # crawl, then set depths to nil
        page_store = Anemone.crawl(pages.first.url, @opts) do |a|
          a.after_crawl do |ps|
            ps.each { |url, page| page.depth = nil; ps[url] = page }
          end
        end.pages

        page_store.should respond_to(:shortest_paths!)

        page_store.shortest_paths!(pages[0].url)
        page_store[pages[0].url].depth.should == 0
        page_store[pages[1].url].depth.should == 1
        page_store[pages[2].url].depth.should == 1
        page_store[pages[3].url].depth.should == 1
        page_store[pages[4].url].depth.should == 2
      end

      it "should be able to remove all redirects in-place" do
        pages = []
        pages << FakePage.new('0', :links => ['1'])
        pages << FakePage.new('1', :redirect => '2')
        pages << FakePage.new('2')

        page_store = Anemone.crawl(pages[0].url, @opts).pages

        page_store.should respond_to(:uniq!)

        page_store.uniq!
        page_store.has_key?(pages[1].url).should == false
        page_store.has_key?(pages[0].url).should == true
        page_store.has_key?(pages[2].url).should == true
      end

      it "should be able to find urls linking to a page"

      it "should be able to find urls linking to a url"
    end

    describe Hash do
      it_should_behave_like "page storage"

      before(:all) do
        @opts = {}
      end
    end

    describe Storage::PStore do
      it_should_behave_like "page storage"

      before(:each) do
        @test_file = 'test.pstore'
        File.delete(@test_file) if File.exists?(@test_file)
        @opts = {:storage => Storage.PStore(@test_file)}
      end

      after(:all) do
        File.delete(@test_file) if File.exists?(@test_file)
      end
    end

    describe Storage::TokyoCabinet do
      it_should_behave_like "page storage"

      before(:each) do
        @test_file = 'test.tch'
        File.delete(@test_file) if File.exists?(@test_file)
        @opts = {:storage => @store = Storage.TokyoCabinet(@test_file)}
      end

      after(:each) do
        @store.close
      end

      after(:all) do
        File.delete(@test_file) if File.exists?(@test_file)
      end
    end

  end
end
