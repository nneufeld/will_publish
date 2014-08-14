require 'spec_helper'

describe "WillPublish::Publishable" do

  describe "publish" do
    before(:each) do
      @draft = Guide.create(name: 'Test Guide', description: 'Guide description', created_at: 5.hours.ago, updated_at: 2.hours.ago)
      @draft.publish
      @published = Guide.last
    end

    it "should create a new object with the same attributes" do
      expect(Guide.count).to eq(2)
      expect(@published.name).to eq(@draft.name)
      expect(@published.description).to eq(@draft.description)
    end

    it "should not copy the active record timestamps" do
      expect(@published.created_at).not_to eq(@draft.created_at)
      expect(@published.updated_at).not_to eq(@draft.updated_at)
    end

    it "should set the is_published_version flag of the published coopy to true" do
      expect(@draft.is_published_version).to eq(false)
      expect(@published.is_published_version).to eq(true)
    end

    context "when the object has already been published" do
      before(:each) do
        @draft.update_attributes(name: 'Updated Name')
        @draft.publish
      end

      it "should not create a second published copy" do
        expect(Guide.count).to eq(2)
      end

      it "should update the attributes of the published copy" do
        @published.reload
        expect(@published.name).to eq('Updated Name')
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

        published = @draft.published
        expect(published.is_published_version).to eq(true)
        expect(published).to eq(Guide.last)
      end
    end

    context "when called on a draft that has not been published" do
      it "should return nil" do
        expect(@draft.published).to be_nil
      end
    end

    context "when called on a published version" do
      it "should return nil" do
        @draft.publish

        published = @draft.published
        expect(published.published).to be_nil
      end
    end
  end

  describe "draft" do
    before(:each) do
      @draft = Guide.create(name: 'Test Guide', description: 'Guide description')
      @draft.publish
      @published = @draft.published
    end

    context "when called on a published version" do
      it "should return the draft version of the publication" do
        expect(@published.draft).to eq(@draft)
      end
    end

    context "when called on a draft" do
      it "should return nil" do
        expect(@draft.draft).to be_nil
      end
    end
  end

end