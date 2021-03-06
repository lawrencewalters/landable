require 'spec_helper'

module Landable
  describe PageRevision do
    let(:author) { create(:author) }
    let(:asset)  { create(:asset)  }

    let(:page) do
      create(:page, path: '/test/path', title: 'title', status_code: 200,
             body: 'body', redirect_url: 'http://www.redirect.com/here',
             meta_tags: {'key'=>'value'}, head_content: 'head_content')
    end

    let(:revision) do
      PageRevision.new page_id: page.id, author_id: author.id
    end

    it { should be_a HasAssets }

    it 'defaults to is_published = true' do
      PageRevision.new.is_published.should == true
    end

    describe '#page_id=' do
      it 'should set page revision attributes matching the page' do
        attrs = revision.attributes.except('page_revision_id','ordinal','notes','is_minor','is_published','author_id','created_at','updated_at', 'page_id', 'audit_flags')
        attrs.should include(page.attributes.except(*PageRevision.ignored_page_attributes))
      end
    end

    describe '#snapshot' do
      it 'should build a page based on the cached page attributes' do
        snapshot = revision.snapshot
        snapshot.should be_new_record
        snapshot.should be_an_instance_of Page
        snapshot.title.should        == page.title
        snapshot.path.should         == page.path
        snapshot.head_content.should == page.head_content
        snapshot.meta_tags.should    == page.meta_tags
        snapshot.body.should         == page.body
        snapshot.redirect_url.should == page.redirect_url
        snapshot.category_id.should  == page.category_id
        snapshot.theme_id.should     == page.theme_id
        snapshot.status_code.should  == page.status_code
      end
    end

    describe '#is_published' do
      it 'should set is_published to true and false as requested' do
        revision = PageRevision.new
        revision.page_id = page.id
        revision.author_id = author.id
        revision.unpublish!
        revision.is_published.should == false
        revision.publish!
        revision.is_published.should == true
      end
    end

    describe '#republish!' do
      it 'republishes a page revision with almost exact attrs' do
        template = create :template, name: 'Basic'
        old = PageRevision.create!(page_id: page.id, author_id: author.id, is_published: true)
        new_author = create :author
        old.republish!({author_id: new_author.id, notes: "Great Note", template: template.name })

        new_record = PageRevision.order('created_at ASC').last
        new_record.author_id.should == new_author.id
        new_record.notes.should == "Publishing update for template #{template.name}: Great Note"
        new_record.page_id.should == page.id
        new_record.body.should == page.body
      end
    end

    describe '#preview_path' do
      it 'should return the preview path' do
        revision.should_receive(:public_preview_page_revision_path) { 'foo' }
        revision.preview_path.should == 'foo'
      end
    end

    describe '#preview_url' do
      it 'should return the preview url' do
        Landable.configuration.stub(:public_host) { 'foo' }
        revision.should_receive(:public_preview_page_revision_url).with(revision, host: 'foo') { 'bar' }
        revision.preview_url.should == 'bar'
      end
    end

    describe '#add_screenshot!' do
      let(:screenshots_enabled) { true }

      before(:each) do
        Landable.configuration.stub(:screenshots_enabled) { screenshots_enabled }
      end

      it 'should be fired before create' do
        revision.should_receive :add_screenshot!
        revision.save!
      end

      it 'should add a screenshot' do
        screenshot = double('screenshot')

        revision.stub(:preview_url) { 'http://google.com/foo' }
        ScreenshotService.should_receive(:capture).with(revision.preview_url) { screenshot }

        revision.should_receive(:screenshot=).with(screenshot).ordered
        revision.should_receive(:store_screenshot!).ordered
        revision.should_receive(:write_screenshot_identifier).ordered
        revision.should_receive(:update_column).with(:screenshot, revision[:screenshot]).ordered

        revision.add_screenshot!
      end

      context 'screenshots disabled' do
        let(:screenshots_enabled) { false }

        it 'should skip' do
          revision.should_receive(:add_screenshot!).and_call_original
          ScreenshotService.should_not_receive :capture
          revision.should_not_receive :screenshot=

          revision.save!
        end
      end
    end

    describe '#screenshot_url' do
      context 'with screenshot' do
        it 'should return the screenshot url' do
          screenshot = double('screenshot', url: 'foobar')

          revision.stub(:screenshot) { screenshot }
          revision.screenshot_url.should == screenshot.url
        end
      end

      context 'without screenshot' do
        it 'should return nil' do
          revision.stub(:screenshot) { nil }
          revision.screenshot_url.should be_nil
        end
      end
    end

  end
end
