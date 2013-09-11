require 'spec_helper'

describe "WillPublish::Publishable" do

  describe "publish" do
    before(:each) do
      @draft = Guide.create(name: 'Test Guide', description: 'Guide description', created_at: 5.hours.ago, updated_at: 2.hours.ago)
      @draft.publish
      @published = Guide.last
    end

    it "should create a new object with the same attributes" do
      Guide.count.should == 2
      @published.name.should == @draft.name
      @published.description.should == @draft.description
    end

    it "should create a PublishableMapping object to map the draft to the published version" do
      WillPublish::PublishableMapping.count.should == 1
      mapping = WillPublish::PublishableMapping.first
      mapping.draft.should == @draft
      mapping.published.should == @published
    end

    it "should not copy the active record timestamps" do
      @published.created_at.should_not == @draft.created_at
      @published.updated_at.should_not == @draft.updated_at
    end

    it "should set the is_published_version flag of the published coopy to true" do
      @draft.is_published_version.should == false
      @published.is_published_version.should == true
    end

    context "when the object has already been published" do
      before(:each) do
        @draft.update_attributes(name: 'Updated Name')
        @draft.publish
      end

      it "should not create a second published copy" do
        Guide.count.should == 2
      end

      it "should update the attributes of the published copy" do
        @published.reload
        @published.name.should == 'Updated Name'
      end
    end

  end

  describe "published" do
    before(:each) do
      @draft = Guide.create(name: 'Test Guide', description: 'Guide description')
    end

    context "when called on a draft that has been published" do
      it "should return the published copy of the publication" do
        @draft.publish

        published = @draft.published_version
        published.is_published_version.should == true
        published.should == Guide.last
      end
    end

    context "when called on a draft that has not been published" do
      it "should return nil" do
        @draft.published_version.should == nil
      end
    end

    context "when called on a published version" do
      it "should return nil" do
        @draft.publish

        published = @draft.published_version
        published.published_version.should == nil
      end
    end
  end

  describe "draft" do
    before(:each) do
      @draft = Guide.create(name: 'Test Guide', description: 'Guide description')
      @draft.publish
      @published = @draft.published_version
    end

    context "when called on a published version" do
      it "should return the draft version of the publication" do
        @published.draft_version.should == @draft
      end
    end

    context "when called on a draft" do
      it "should return nil" do
        @draft.draft_version.should == nil
      end
    end
  end

end