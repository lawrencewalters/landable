require 'spec_helper'

module Landable
  describe PageRevision do
    let(:author) { create(:author) }
    let(:asset)  { create(:asset)  }

    let(:page) do
      create(:page, path: '/test/path', title: 'title',
             body: 'body', redirect_url: '/redirect/here',
             meta_tags: {'key'=>'value'})
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
        attrs = revision.attributes.except('page_revision_id','ordinal','notes','is_minor','is_published','author_id','created_at','updated_at', 'head_tags_attributes', 'page_id')
        attrs.should include(page.attributes.except(*PageRevision.ignored_page_attributes))
      end

      it 'should include head_tags_attributes' do
        ht = create :head_tag, page_id: page.id

        attrs = revision.attributes.except('page_revision_id','ordinal','notes','is_minor','is_published','author_id','created_at','updated_at', 'page_id')
        attrs['head_tags_attributes'].should == {ht.head_tag_id => ht.content}
        #[ht.attributes.except('created_at', 'updated_at', 'page_id')]
      end
    end

    describe '#snapshot' do
      it 'should build a page based on snapshot_attribute' do
        snapshot = revision.snapshot
        snapshot.should be_new_record
        snapshot.should be_an_instance_of Page
        snapshot.title.should == 'title'
        snapshot.path.should == '/test/path'
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
  end
end
